extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker2D]

var current_wave = 0
var enemies_remaining = 0

func _ready():
	start_wave(1)

func start_wave(wave_number: int):
	current_wave = wave_number
	var count = 3 + wave_number * 2  # scales enemies per wave
	for i in count:
		await get_tree().create_timer(0.5).timeout
		_spawn_enemy()

func _spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var spawn = spawn_points.pick_random()
	enemy.global_position = spawn.global_position
	get_tree().current_scene.add_child(enemy)
	enemies_remaining += 1
