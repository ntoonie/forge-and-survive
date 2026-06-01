extends Node

enum Phase { BUILD, DEFENSE }

var current_phase = Phase.BUILD
var build_timer   = 15.0
var wave_number   = 0
var max_waves     = 5

signal phase_changed(new_phase)
signal game_won

# ── Subsystem references ───────────────────────────────────────
var wave_evolver : WaveEvolver


func _ready() -> void:
	wave_evolver = WaveEvolver.new()
	add_child(wave_evolver)
	phase_changed.emit(Phase.BUILD)
	AudioManager.play_day()


func _process(delta: float) -> void:
	if current_phase == Phase.BUILD:
		build_timer -= delta
		if build_timer <= 0:
			_start_defense_phase()


# ────────────────────────────────────────────────────────────────
# Defense phase start
# ────────────────────────────────────────────────────────────────
func _start_defense_phase() -> void:
	current_phase = Phase.DEFENSE
	wave_number  += 1
	print("Night! Wave: ", wave_number)
	phase_changed.emit(Phase.DEFENSE)
	AudioManager.play_night()

	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.start_wave(wave_number)
		wave_manager.wave_cleared.connect(_on_wave_cleared, CONNECT_ONE_SHOT)


# ────────────────────────────────────────────────────────────────
# Wave-cleared callback
# ────────────────────────────────────────────────────────────────
func _on_wave_cleared(_wave_number: int) -> void:
	# 1. Sample Forge HP and convert to a 0–100 percentage.
	var forge     = get_tree().get_first_node_in_group("forge")
	var forge_pct : float = 100.0
	if forge:
		forge_pct = clamp(
			float(forge.current_health) / float(forge.max_health) * 100.0,
			0.0, 100.0
		)
	print("Wave %d cleared. Forge HP: %.1f%%" % [_wave_number, forge_pct])

	# 2. Feed feedback into the evolver.
	wave_evolver.last_forge_hp_pct  = forge_pct
	wave_evolver.last_wave_survived = (forge_pct > 0.0)

	# 3. Run one generation of evolution and grab the fittest chromosome.
	var evolved_spec : Array = wave_evolver.evolve()
	print("Evolved spec for next wave — fast:%d  tank:%d  normal:%d  gate:%d" % [
		evolved_spec[0], evolved_spec[1], evolved_spec[2], evolved_spec[3]
	])

	# 4. Pre-load the spec into the WaveManager so start_wave() can use it.
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.set_evolved_spec(evolved_spec)

	# 5. Win-check / proceed.
	if wave_number >= max_waves:
		game_won.emit()
		get_tree().change_scene_to_file("res://scenes/ui/VictoryScreen.tscn")
		return
	_start_build_phase()


# ────────────────────────────────────────────────────────────────
# Build phase start
# ────────────────────────────────────────────────────────────────
func _start_build_phase() -> void:
	current_phase = Phase.BUILD
	build_timer   = 20.0
	phase_changed.emit(Phase.BUILD)
	AudioManager.play_day()


# ── Utility ───────────────────────────────────────────────────
func get_time_remaining() -> float:
	return build_timer


func skip_to_night() -> void:
	if current_phase == Phase.BUILD:
		build_timer = 0
