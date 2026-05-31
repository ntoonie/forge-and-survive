extends Node

enum Phase { BUILD, DEFENSE }

var current_phase = Phase.BUILD
var build_timer = 10.0
var wave_number = 0
var max_waves = 3

signal phase_changed(new_phase)
signal game_won

func _ready():
	phase_changed.emit(Phase.BUILD)

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
	# Start the wave
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		print("Wave manager found!")
		wave_manager.start_wave(wave_number)
		wave_manager.wave_cleared.connect(_on_wave_cleared, CONNECT_ONE_SHOT)
	else:
		print("Wave manager not found!")
func _on_wave_cleared(_wave_number):
	print("Wave cleared! Returning to day...")
	if wave_number >= max_waves:
		game_won.emit()
		get_tree().change_scene_to_file(
            "res://scenes/ui/VictoryScreen.tscn"
		)
		return
	_start_build_phase()

func _start_build_phase():
	current_phase = Phase.BUILD
	build_timer = 20.0
	print("Day! Build phase started. Timer: ", build_timer)
	phase_changed.emit(Phase.BUILD)

func get_time_remaining() -> float:
	return build_timer

func skip_to_night():
	if current_phase == Phase.BUILD:
		build_timer = 0
