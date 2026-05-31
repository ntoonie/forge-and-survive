extends CanvasLayer

@onready var iron_label = $Control/ResourcePanel/IronLabel
@onready var wood_label = $Control/ResourcePanel/WoodLabel
@onready var stone_label = $Control/ResourcePanel/StoneLabel
@onready var timer_label = $Control/ResourcePanel/TimerLabel
@onready var wave_label = $Control/ResourcePanel/WaveLabel

var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var pause_menu_instance = null

func _ready():
	var control = $Control
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var gear = get_node_or_null("Control/GearButton")
	if gear:
		gear.ignore_texture_size = true
		gear.stretch_mode = TextureButton.STRETCH_SCALE
		gear.custom_minimum_size = Vector2(48, 48)
		await get_tree().process_frame
		gear.size = Vector2(98, 98)
		gear.position = Vector2(1092, 8)
		gear.pressed.connect(_on_gear_pressed)
	else:
		print("GearButton not found!")

func _on_gear_pressed():
	if pause_menu_instance == null:
		pause_menu_instance = pause_menu_scene.instantiate()
		get_tree().current_scene.add_child(pause_menu_instance)
	pause_menu_instance.visible = true
	get_tree().paused = true

func _process(_delta):
	iron_label.text = "Iron: " + str(GameData.resources["iron"])
	wood_label.text = "Wood: " + str(GameData.resources["wood"])
	stone_label.text = "Stone: " + str(GameData.resources["stone"])

	var game_loop = get_tree().get_first_node_in_group("game_loop")
	if game_loop:
		if game_loop.current_phase == 0:
			timer_label.text = "Day: " + str(int(game_loop.get_time_remaining())) + "s"
			wave_label.text = "Wave: " + str(game_loop.wave_number + 1) + "/" + str(game_loop.max_waves)
		else:
			timer_label.text = "NIGHT - DEFEND!"
			wave_label.text = "Wave: " + str(game_loop.wave_number) + "/" + str(game_loop.max_waves)
