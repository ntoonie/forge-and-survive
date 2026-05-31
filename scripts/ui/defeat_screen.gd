extends Control

func _ready():
	$Button.connect("pressed", _on_button_pressed)
	AudioManager.play_defeat()

func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
