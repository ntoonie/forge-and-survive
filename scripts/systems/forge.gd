extends StaticBody2D

@export var max_health: int = 300
var current_health: int

signal forge_destroyed

func _ready():
	current_health = max_health
	add_to_group("forge")
	print("Forge ready! Health: ", current_health)

func take_damage(amount: int):
	current_health -= amount
	print("Forge health: ", current_health)
	if current_health <= 0:
		forge_destroyed.emit()
		_game_over()

func _game_over():
	print("GAME OVER - Forge destroyed!")
	get_tree().change_scene_to_file(
        "res://scenes/ui/DefeatScreen.tscn"
	)
