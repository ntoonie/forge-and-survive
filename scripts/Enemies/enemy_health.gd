extends RigidBody2D


@export var max_health: int = 30
var current_health: int

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		get_parent().die()
