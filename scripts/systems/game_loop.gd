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
