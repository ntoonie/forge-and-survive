extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$ResumeButton.process_mode = Node.PROCESS_MODE_ALWAYS
	$RestartButton.process_mode = Node.PROCESS_MODE_ALWAYS
	$QuitButton.process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for btn in [$ResumeButton, $RestartButton, $QuitButton]:
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.size = Vector2(200, 60)

	$ResumeButton.pressed.connect(_on_resume_pressed)
	$RestartButton.pressed.connect(_on_restart_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	visible = false

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		var center = get_viewport_rect().size / 2
		$ResumeButton.position = Vector2(center.x - 100, center.y - 110)
		$RestartButton.position = Vector2(center.x - 100, center.y - 30)
		$QuitButton.position = Vector2(center.x - 100, center.y + 50)

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
