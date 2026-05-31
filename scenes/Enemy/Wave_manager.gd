extends Node

signal wave_cleared(wave_number: int)
signal wave_started(wave_number: int)

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker2D]

var current_wave: int = 0
var enemies_remaining: int = 0
var is_spawning: bool = false


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
		"enemy_count":     3 + wave * 2,
		"enemy_health":    50 + wave * 10,
		"enemy_speed":     60.0 + wave * 3.0,
		"sa_initial_temp": max(20.0, 100.0 - wave * 3.0),
	}


func _spawn_enemy(config: Dictionary) -> void:
	if enemy_scene == null:
		push_error("WaveManager: enemy_scene is not assigned!")
		return
	if spawn_points.is_empty():
		push_error("WaveManager: no spawn points assigned!")
		return

	var enemy = enemy_scene.instantiate()

	if enemy.has_method("apply_wave_config"):
		enemy.apply_wave_config(config)

	enemy.global_position = spawn_points.pick_random().global_position
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
