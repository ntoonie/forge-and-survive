extends Node

signal wave_cleared(wave_number: int)
signal wave_started(wave_number: int)

# ── Scene exports (assign in World scene inspector) ───────────────────────────
@export var enemy_scene:   PackedScene   # enemy_1.tscn — Normal
@export var enemy_2_scene: PackedScene   # enemy_2.tscn — Raider (fast)
@export var enemy_3_scene: PackedScene   # enemy_3.tscn — Twin Boss

var current_wave      : int  = 0
var enemies_remaining : int  = 0
var is_spawning       : bool = false

# ── Boundary gate constants ────────────────────────────────────────────────────
const GATE_WEST  : int = 0
const GATE_EAST  : int = 1
const GATE_NORTH : int = 2
const GATE_SOUTH : int = 3

const SCREEN_W    : float = 1152.0
const SCREEN_H    : float = 648.0
const EDGE_OFFSET : float = -80.0

# ── Base stats for enemy_1 at wave 1 ─────────────────────────────────────────
const BASE_HEALTH     : int   = 30
const BASE_SPEED      : float = 80.0
const BASE_DAMAGE     : int   = 10
const HEALTH_PER_WAVE : int   = 20
const SPEED_PER_WAVE  : float = 5.0

# ── Evolved wave spec from WaveEvolver ────────────────────────────────────────
# Chromosome: [fast_count, tank_count, normal_count, spawn_gate]
# Defaults used until game_loop.gd supplies the first evolved spec.
var _evolved_spec : Array = [2, 0, 3, 0]   # safe conservative defaults


func _ready() -> void:
	add_to_group("wave_manager")


# ── Called by game_loop.gd before start_wave() each round ─────
func set_evolved_spec(spec: Array) -> void:
	if spec.size() >= 4:
		_evolved_spec = spec
		print("WaveManager received evolved spec: fast=%d  tank=%d  normal=%d  gate=%d" % [
			spec[0], spec[1], spec[2], spec[3]
		])


# ── Main spawn entry ──────────────────────────────────────────────────────────
func start_wave(wave_number: int) -> void:
	current_wave      = wave_number
	enemies_remaining = 0
	is_spawning       = true
	wave_started.emit(current_wave)

	# ── Resolve counts and base gate from the evolved spec ────────
	# The GA provides deltas; we still apply the hardcoded floor so that
	# very early waves (when the evolver has no feedback yet) stay sane.
	var evolved_normal : int = _evolved_spec[2]
	var evolved_fast   : int = _evolved_spec[0]
	var evolved_tank   : int = _evolved_spec[1]
	var base_gate      : int = clamp(_evolved_spec[3], 0, 3)

	# Minimum enemy counts grow with wave number, but the evolver
	# can push them higher.  Taking the max keeps the game from going
	# easier than the hardcoded baseline.
	var e1_count : int = max(2 + wave_number * 3, evolved_normal)
	var spawn_counter : int = 0

	# ── enemy_1 (Normal) ──────────────────────────────────────────
	var e1_config : Dictionary = _get_enemy1_config(wave_number)
	for i in e1_count:
		await get_tree().create_timer(0.5).timeout
		var spawn_gate : int = (base_gate + spawn_counter) % 4
		spawn_counter += 1
		_spawn_enemy(enemy_scene, e1_config, spawn_gate, Vector2.ZERO)

	# ── enemy_2 (Raider / fast) — evolved count from wave 1 onwards ─
	var e2_base  : int = (wave_number - 2) * 2 if wave_number >= 3 else 0
	var e2_count : int = max(e2_base, evolved_fast)
	if e2_count > 0:
		var e2_config : Dictionary = _get_enemy2_config(wave_number)
		for i in e2_count:
			await get_tree().create_timer(0.6).timeout
			var spawn_gate : int = (base_gate + spawn_counter) % 4
			spawn_counter += 1
			_spawn_enemy(enemy_2_scene, e2_config, spawn_gate, Vector2.ZERO)

	# ── enemy_3 (Twin Boss) — hardcoded wave-5 logic + evolved tank bonus ─
	var e3_count : int = 0
	if wave_number == 5:
		e3_count = 2           # the canonical twin-boss pair
	e3_count = max(e3_count, evolved_tank if wave_number >= 5 else 0)

	if e3_count > 0:
		var e3_config : Dictionary = _get_enemy3_config(wave_number)
		var gates_e3  : Array      = [GATE_WEST, GATE_EAST, GATE_NORTH, GATE_SOUTH]
		for idx in e3_count:
			await get_tree().create_timer(1.0 if idx == 0 else 0.3).timeout
			var g : int = gates_e3[idx % gates_e3.size()]
			var offset  : Vector2 = Vector2(0, -22 if idx % 2 == 0 else 22)
			_spawn_enemy(enemy_3_scene, e3_config, g, offset)

	is_spawning = false
	_check_wave_cleared()


# ── Per-type config builders ──────────────────────────────────────────────────

func _get_enemy1_config(wave: int) -> Dictionary:
	return {
		"enemy_health": BASE_HEALTH + wave * HEALTH_PER_WAVE,
		"enemy_speed":  (BASE_SPEED + wave * SPEED_PER_WAVE) * 0.8,
		"enemy_damage": BASE_DAMAGE,
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


func _get_enemy2_config(wave: int) -> Dictionary:
	var base_hp  : int   = BASE_HEALTH + wave * HEALTH_PER_WAVE
	var base_spd : float = BASE_SPEED  + wave * SPEED_PER_WAVE
	return {
		"enemy_health": base_hp * 2,
		"enemy_speed":  base_spd * 1.0,
		"enemy_damage": int(BASE_DAMAGE * 1.25),
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


func _get_enemy3_config(wave: int) -> Dictionary:
	var base_hp  : int   = BASE_HEALTH + wave * HEALTH_PER_WAVE
	var base_spd : float = BASE_SPEED  + wave * SPEED_PER_WAVE
	return {
		"enemy_health": int(base_hp  * 3.0),
		"enemy_speed":  base_spd * 0.25,
		"enemy_damage": int(BASE_DAMAGE * 0.5),
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
	}


# ── Spawn helpers ─────────────────────────────────────────────────────────────

func _gate_spawn_position(gate: int, offset: Vector2 = Vector2.ZERO) -> Vector2:
	var spawn_min_x := -8.0
	var spawn_max_x := 1140.0
	var spawn_min_y := 92.0
	var spawn_max_y := 824.0

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
