extends Node

enum Phase { BUILD, DEFENSE }

var current_phase = Phase.BUILD
var build_timer = 10.0
var wave_number = 0
var max_waves = 5

signal phase_changed(new_phase)
signal game_won

func _ready():
	wave_evolver = WaveEvolver.new()
	add_child(wave_evolver)
	phase_changed.emit(Phase.BUILD)
	AudioManager.play_day()

func _process(delta):
	if current_phase == Phase.BUILD:
		build_timer -= delta
		if build_timer <= 0:
			_start_defense_phase()

func _start_defense_phase():
	current_phase = Phase.DEFENSE
	wave_number += 1
	print("Night! Wave: ", wave_number)
	phase_changed.emit(Phase.DEFENSE)
	AudioManager.play_night()
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.start_wave(wave_number)
		wave_manager.wave_cleared.connect(_on_wave_cleared, CONNECT_ONE_SHOT)

func _on_wave_cleared(_wave_number):
	if wave_number >= max_waves:
		game_won.emit()
		get_tree().change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")
		return
	_start_build_phase()

func _start_build_phase():
	current_phase = Phase.BUILD
	build_timer = 20.0
	phase_changed.emit(Phase.BUILD)
	AudioManager.play_day()

func get_time_remaining() -> float:
	return build_timer

func skip_to_night():
	if current_phase == Phase.BUILD:
		build_timer = 0

var wave_evolver: WaveEvolver

func _on_night_ended() -> void:
	var forge = get_tree().get_first_node_in_group("forge")
	if forge:
		wave_evolver.last_forge_hp_remaining = forge.current_health
	else:
		wave_evolver.last_forge_hp_remaining = 100
	wave_evolver.last_wave_survived = true
	var spec: Array = wave_evolver.evolve()
	_spawn_wave(spec[0], spec[1], spec[2])

func _spawn_wave(fast: int, tanks: int, normal: int) -> void:
	for _i in range(fast):
		_spawn_enemy("fast")
	for _i in range(tanks):
		_spawn_enemy("tank")
	for _i in range(normal):
		_spawn_enemy("normal")

func _spawn_enemy(type: String) -> void:
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		var config = wave_manager._get_wave_config(wave_number)
		config["type"] = type
		wave_manager._spawn_enemy(config)
