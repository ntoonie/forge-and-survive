extends CharacterBody2D

const SPEED = 60.0
var forge_position = Vector2(544, 288)

@export var max_health: int = 30
var current_health: int

func _ready():
	current_health = max_health

func _physics_process(_delta):
	var direction = (forge_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		queue_free()
