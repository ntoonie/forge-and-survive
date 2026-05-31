extends Node

signal wave_cleared(wave_number: int)
signal wave_started(wave_number: int)

# ── Scene exports (assign in World scene inspector) ───────────────────────────
@export var enemy_scene:   PackedScene   # enemy_1.tscn — rounds 1-5 baseline
@export var enemy_2_scene: PackedScene   # enemy_2.tscn — rounds 3-5 mix-in
@export var enemy_3_scene: PackedScene   # enemy_3.tscn — round 5 twin boss

var current_wave: int = 0
var enemies_remaining: int = 0
var is_spawning: bool = false

# ── Boundary gate constants ────────────────────────────────────────────────────
# Gates: 0 = West, 1 = East, 2 = North, 3 = South
const GATE_WEST  : int = 0
const GATE_EAST  : int = 1
const GATE_NORTH : int = 2
const GATE_SOUTH : int = 3

# Viewport dimensions (match project resolution 1152 × 648)
const SCREEN_W    : float = 1152.0
const SCREEN_H    : float = 648.0
const EDGE_OFFSET : float = -80.0   # spawn slightly outside the visible area

# ── Base stats for enemy_1 at wave 1 ─────────────────────────────────────────
const BASE_HEALTH : int   = 30
const BASE_SPEED  : float = 80.0
const BASE_DAMAGE : int   = 10
const HEALTH_PER_WAVE : int   = 20
const SPEED_PER_WAVE  : float = 5.0


func _ready() -> void:
	pass  # game_loop.gd will call start_wave()


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	enemies_remaining = 0
	is_spawning = true
	wave_started.emit(current_wave)

	var base_gate : int = _get_evolved_gate()
	var spawn_counter : int = 0

	# ── enemy_1: rounds 1-5 (same wave-counter logic throughout) ──────────────
	var e1_count : int = 2 + wave_number * 3
	var e1_config : Dictionary = _get_enemy1_config(wave_number)
	for i in e1_count:
		await get_tree().create_timer(0.5).timeout
		var spawn_gate = (base_gate + spawn_counter) % 4
		spawn_counter += 1
		_spawn_enemy(enemy_scene, e1_config, spawn_gate, Vector2.ZERO)

	# ── enemy_2: rounds 3-5 (slowly increasing count & speed) ────────────────
	if wave_number >= 3:
		var e2_count : int = (wave_number - 2) * 2   # 2 at R3, 4 at R4, 6 at R5
		var e2_config : Dictionary = _get_enemy2_config(wave_number)
		for i in e2_count:
			await get_tree().create_timer(0.6).timeout
			var spawn_gate = (base_gate + spawn_counter) % 4
			spawn_counter += 1
			_spawn_enemy(enemy_2_scene, e2_config, spawn_gate, Vector2.ZERO)

	# ── enemy_3: round 5 only — twin boss, one from left (West), one from right (East) ─
	if wave_number == 5:
		var e3_config : Dictionary = _get_enemy3_config(wave_number)
		await get_tree().create_timer(1.0).timeout
		_spawn_enemy(enemy_3_scene, e3_config, GATE_WEST, Vector2(0, -22))
		await get_tree().create_timer(0.3).timeout
		_spawn_enemy(enemy_3_scene, e3_config, GATE_EAST, Vector2(0,  22))

	is_spawning = false
	_check_wave_cleared()


# ── Per-type config builders ──────────────────────────────────────────────────

func _get_enemy1_config(wave: int) -> Dictionary:
	# Normal — baseline stats, scale linearly per wave (slower at 0.8x speed)
	return {
		"enemy_health": BASE_HEALTH + wave * HEALTH_PER_WAVE,
		"enemy_speed":  (BASE_SPEED + wave * SPEED_PER_WAVE) * 0.8,
		"enemy_damage": BASE_DAMAGE,
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


func _get_enemy2_config(wave: int) -> Dictionary:
	# Raider — 1.25× damage, 2.0× health, speed is exactly 1.0× baseline
	var base_hp    : int   = BASE_HEALTH + wave * HEALTH_PER_WAVE
	var base_spd   : float = BASE_SPEED  + wave * SPEED_PER_WAVE
	return {
		"enemy_health": base_hp * 2,
		"enemy_speed":  base_spd * 1.0,
		"enemy_damage": int(BASE_DAMAGE * 1.25),
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


func _get_enemy3_config(wave: int) -> Dictionary:
	# Twin Boss — 0.5× damage, 3× health, 0.25× speed
	var base_hp  : int   = BASE_HEALTH + wave * HEALTH_PER_WAVE
	var base_spd : float = BASE_SPEED  + wave * SPEED_PER_WAVE
	return {
		"enemy_health": int(base_hp  * 3.0),
		"enemy_speed":  base_spd * 0.25,
		"enemy_damage": int(BASE_DAMAGE * 0.5),
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


# ── Ask the WaveEvolver (if present) for the evolved gate, otherwise random ───
func _get_evolved_gate() -> int:
	var evolver = get_tree().get_first_node_in_group("wave_evolver")
	if evolver and evolver.population.size() > 0:
		var best : Array = evolver.population[0]
		if best.size() >= 4:
			return clamp(best[3], 0, 3)
	return randi() % 4


# Returns a world-space spawn position along the chosen boundary gate, limited to the TileMapLayer's global boundaries
func _gate_spawn_position(gate: int, offset: Vector2 = Vector2.ZERO) -> Vector2:
	# Expanded TileMapLayer global boundaries:
	# X: -10.0 to 1142.0 (with spawn points 2 px inside to avoid out of bounds: -8.0 and 1140.0)
	# Y: 90.0 to 826.0 (with spawn points 2 px inside to avoid out of bounds: 92.0 and 824.0)
	var spawn_min_x = -8.0
	var spawn_max_x = 1140.0
	var spawn_min_y = 92.0
	var spawn_max_y = 824.0
	
	var base_pos : Vector2
	match gate:
		GATE_WEST:
			base_pos = Vector2(spawn_min_x, randf_range(spawn_min_y, spawn_max_y))
		GATE_EAST:
			base_pos = Vector2(spawn_max_x, randf_range(spawn_min_y, spawn_max_y))
		GATE_NORTH:
			base_pos = Vector2(randf_range(spawn_min_x, spawn_max_x), spawn_min_y)
		GATE_SOUTH:
			base_pos = Vector2(randf_range(spawn_min_x, spawn_max_x), spawn_max_y)
		_:
			base_pos = Vector2(spawn_min_x, (spawn_min_y + spawn_max_y) / 2.0)
	return base_pos + offset


func _spawn_enemy(scene: PackedScene, config: Dictionary, gate: int, offset: Vector2) -> void:
	if scene == null:
		push_error("WaveManager: scene is not assigned!")
		return

	var enemy = scene.instantiate()
	enemy.global_position = _gate_spawn_position(gate, offset)

	if enemy.has_method("apply_wave_config"):
		enemy.apply_wave_config(config)

	get_tree().current_scene.add_child(enemy)
	enemies_remaining += 1

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	enemies_remaining -= 1
	print("Enemy died. Remaining: ", enemies_remaining)
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	print("Checking wave clear: remaining = ", enemies_remaining, " spawning = ", is_spawning)
	if enemies_remaining <= 0 and not is_spawning:
		print("Wave ", current_wave, " cleared!")
		wave_cleared.emit(current_wave)
