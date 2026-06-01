extends CanvasLayer

@onready var iron_label = $Control/ResourcePanel/IronLabel
@onready var wood_label = $Control/ResourcePanel/WoodLabel
@onready var stone_label = $Control/ResourcePanel/StoneLabel
@onready var timer_label = $Control/ResourcePanel/TimerLabel
@onready var wave_label = $Control/ResourcePanel/WaveLabel
@onready var build_mode_label = $Control/BuildStatusPanel/BuildModeLabel
@onready var selected_label = $Control/BuildStatusPanel/SelectedLabel
@onready var build_hint_label = $Control/BuildStatusPanel/BuildHintLabel
@onready var build_status_panel = $Control/BuildStatusPanel
@onready var hotbar_panel = $Control/HotbarPanel
@onready var wall_button = $Control/HotbarPanel/HotbarRow/WallButton
@onready var tower_button = $Control/HotbarPanel/HotbarRow/TowerButton
@onready var spikes_button = $Control/HotbarPanel/HotbarRow/SpikesButton

var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var pause_menu_instance = null
var hotbar_buttons: Array[TextureButton] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hotbar_buttons = [wall_button, tower_button, spikes_button]
	build_hint_label.text = "Press 1/2/3 or click the hotbar"
	get_viewport().size_changed.connect(_layout_overlay)

	wall_button.pressed.connect(_on_wall_pressed)
	tower_button.pressed.connect(_on_tower_pressed)
	spikes_button.pressed.connect(_on_spikes_pressed)

	var control = $Control
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var gear = get_node_or_null("Control/GearButton")
	if gear:
		gear.ignore_texture_size = true
		gear.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		gear.custom_minimum_size = Vector2(96, 96)
		await get_tree().process_frame
		gear.size = Vector2(196, 196)
		var screen_w = get_viewport().get_visible_rect().size.x
		var margin_right = 2.0
		gear.position = Vector2(screen_w - gear.size.x - margin_right, 1)
		gear.pressed.connect(_on_gear_pressed)
	else:
		print("GearButton not found!")

	for button in hotbar_buttons:
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(88, 88)

	await get_tree().process_frame
	_layout_overlay()
	_refresh_build_ui()

func _layout_overlay() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	var panel_size = hotbar_panel.size
	if panel_size == Vector2.ZERO:
		panel_size = hotbar_panel.get_combined_minimum_size()
	var hotbar_position = Vector2((viewport_size.x - panel_size.x) * 0.5, viewport_size.y - panel_size.y - 20)
	hotbar_panel.position = hotbar_position

	var status_size = build_status_panel.size
	if status_size == Vector2.ZERO:
		status_size = build_status_panel.get_combined_minimum_size()
	var status_x = hotbar_position.x - status_size.x - 16.0
	if status_x < 16.0:
		status_x = 16.0
	build_status_panel.position = Vector2(status_x, hotbar_position.y)

	var gear = get_node_or_null("Control/GearButton")
	if gear:
		gear.position = Vector2(viewport_size.x - gear.size.x - 2.0, 1)

func _get_build_system():
	return get_tree().get_first_node_in_group("build_system")

func _refresh_build_ui() -> void:
	var build_system = _get_build_system()
	if build_system:
		build_mode_label.text = "Build Mode: ON" if build_system.build_mode else "Build Mode: OFF"
		selected_label.text = "Selected: %s" % _pretty_structure_name(build_system.selected_structure)
		_update_hotbar_selection(build_system.selected_structure)
	else:
		build_mode_label.text = "Build Mode: --"
		selected_label.text = "Selected: --"
		_update_hotbar_selection("")

func _on_gear_pressed():
	if pause_menu_instance == null:
		pause_menu_instance = pause_menu_scene.instantiate()
		add_child(pause_menu_instance)
	pause_menu_instance.visible = true
	get_tree().paused = true

func _on_wall_pressed() -> void:
	_select_structure_from_hud("wall")

func _on_tower_pressed() -> void:
	_select_structure_from_hud("tower")

func _on_spikes_pressed() -> void:
	_select_structure_from_hud("floor_spikes")

func _select_structure_from_hud(structure_name: String) -> void:
	var build_system = _get_build_system()
	if build_system:
		build_system.build_mode = true
		build_system.selected_structure = structure_name
		_refresh_build_ui()

func _process(_delta):
	iron_label.text = "Iron: " + str(GameData.resources["iron"])
	wood_label.text = "Wood: " + str(GameData.resources["wood"])
	stone_label.text = "Stone: " + str(GameData.resources["stone"])
	_refresh_build_ui()

	var game_loop = get_tree().get_first_node_in_group("game_loop")
	if game_loop:
		if game_loop.current_phase == 0:
			timer_label.text = "Day: " + str(int(game_loop.get_time_remaining())) + "s"
			wave_label.text = "Wave: " + str(game_loop.wave_number + 1) + "/" + str(game_loop.max_waves)
		else:
			timer_label.text = "NIGHT - DEFEND!"
			wave_label.text = "Wave: " + str(game_loop.wave_number) + "/" + str(game_loop.max_waves)

func _update_hotbar_selection(selected_structure: String) -> void:
	var selected_button: TextureButton = null
	match selected_structure:
		"wall":
			selected_button = wall_button
		"tower":
			selected_button = tower_button
		"floor_spikes":
			selected_button = spikes_button

	for button in hotbar_buttons:
		if button == selected_button:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)
			button.scale = Vector2(1.08, 1.08)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 0.55)
			button.scale = Vector2.ONE

func _pretty_structure_name(structure_name: String) -> String:
	match structure_name:
		"floor_spikes":
			return "Floor Spikes"
		"tower":
			return "Tower"
		"wall":
			return "Wall"
	return structure_name
