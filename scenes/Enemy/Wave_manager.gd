extends Node

signal wave_cleared(wave_number: int)
signal wave_started(wave_number: int)

@export var enemy_scene: PackedScene
# spawn_points kept for fallback compatibility but no longer required
@export var spawn_points: Array[Marker2D]

var current_wave: int = 0
var enemies_remaining: int = 0
var is_spawning: bool = false

# ── Boundary gate constants ────────────────────────────────────
# Gates: 0 = West, 1 = East, 2 = North, 3 = South
const GATE_WEST  : int = 0
const GATE_EAST  : int = 1
const GATE_NORTH : int = 2
const GATE_SOUTH : int = 3

# Viewport dimensions (match project resolution 1152 × 648)
const SCREEN_W : float = 1152.0
const SCREEN_H : float = 648.0
const EDGE_OFFSET : float = -80.0   # spawn slightly outside the visible area


func _ready() -> void:
	pass  # temporary — game_loop.gd will call this later


func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	enemies_remaining = 0
	is_spawning = true
	wave_started.emit(current_wave)

	var config = _get_wave_config(wave_number)
	for i in config.enemy_count:
		await get_tree().create_timer(0.5).timeout
		_spawn_enemy(config)

	is_spawning = false
	_check_wave_cleared()


func _get_wave_config(wave: int) -> Dictionary:
	return {
		"enemy_count":     2 + wave * 3,
		"enemy_health":    30 + wave * 20,
		"enemy_speed":     60.0 + wave * 5.0,
		"sa_initial_temp": max(20.0, 100.0 - wave * 15.0),
		# Gate gene comes from the wave evolver; default to random when absent
		"spawn_gate":      _get_evolved_gate(),
	}


# Ask the WaveEvolver (if present) for the evolved gate, otherwise random
func _get_evolved_gate() -> int:
	var evolver = get_tree().get_first_node_in_group("wave_evolver")
	if evolver and evolver.population.size() > 0:
		# Gene index 3 holds the gate (0-3) — clamped for safety
		var best : Array = evolver.population[0]
		if best.size() >= 4:
			return clamp(best[3], 0, 3)
	return randi() % 4


# Returns a world-space spawn position along the chosen boundary gate
func _gate_spawn_position(gate: int) -> Vector2:
	match gate:
		GATE_WEST:
			return Vector2(EDGE_OFFSET, randf_range(0.0, SCREEN_H))
		GATE_EAST:
			return Vector2(SCREEN_W - EDGE_OFFSET, randf_range(0.0, SCREEN_H))
		GATE_NORTH:
			return Vector2(randf_range(0.0, SCREEN_W), EDGE_OFFSET)
		GATE_SOUTH:
			return Vector2(randf_range(0.0, SCREEN_W), SCREEN_H - EDGE_OFFSET)
	return Vector2(EDGE_OFFSET, SCREEN_H / 2.0)   # fallback: West centre


func _spawn_enemy(config: Dictionary) -> void:
	if enemy_scene == null:
		push_error("WaveManager: enemy_scene is not assigned!")
		return

	var enemy = enemy_scene.instantiate()

	# Use evolved boundary-gate spawning; fall back to Marker2D if needed
	var gate : int = config.get("spawn_gate", randi() % 4)
	enemy.global_position = _gate_spawn_position(gate)

	var type = config.get("type", "normal")
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	
	if type == "fast":
		enemy.scale = Vector2(1.5, 1.5)
		if enemy.has_method("apply_wave_config"):
			config["enemy_health"] = config.get("enemy_health", 30) / 2
			config["enemy_speed"] = config.get("enemy_speed", 60.0) * 1.5
			enemy.apply_wave_config(config)
		if sprite:
			sprite.modulate = Color(1.5, 0.8, 0.8) # brighter red/pink
	elif type == "tank":
		enemy.scale = Vector2(3.0, 3.0)
		if enemy.has_method("apply_wave_config"):
			config["enemy_health"] = config.get("enemy_health", 30) * 2
			config["enemy_speed"] = config.get("enemy_speed", 60.0) / 2
			enemy.apply_wave_config(config)
		if sprite:
			sprite.modulate = Color(0.4, 0.4, 0.4) # darker
	else:
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
	print("Checking wave clear: remaining = ", enemies_remaining, "spawning = ", is_spawning)
	if enemies_remaining <= 0 and not is_spawning:
		print("Wave ", current_wave, " cleared!")
		wave_cleared.emit(current_wave)
