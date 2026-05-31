extends StaticBody2D

@export var max_health: int = 300
var current_health: int
var is_destroyed: bool = false

signal forge_destroyed

func _ready():
	current_health = max_health
	is_destroyed = false
	add_to_group("forge")
	print("Forge ready! Health: ", current_health)

func take_damage(amount: int):
	if is_destroyed:
		return

	current_health -= amount
	if current_health < 0:
		current_health = 0
	print("Forge health: ", current_health)
	if current_health <= 0:
		is_destroyed = true
		forge_destroyed.emit()
		_game_over()

func _game_over():
	print("GAME OVER - Forge destroyed!")
	get_tree().change_scene_to_file(
		"res://scenes/ui/defeat_screen.tscn"
	)
