extends Control

func _ready():
	$PlayButton.pressed.connect(_on_play_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_pressed():
	get_tree().quit()
