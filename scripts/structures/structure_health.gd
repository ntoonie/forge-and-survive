extends Node

@export var max_health: int = 100
var current_health: int

# ── Collision durability ───────────────────────────────────────
var collisions_remaining: int = 10

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		_destroy()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)

# Called by enemy_health.gd when an enemy physically collides with this wall
func register_collision() -> void:
	collisions_remaining -= 1
	if collisions_remaining <= 0:
		_destroy()

func _destroy() -> void:
	# Un-register this wall from the pathfinder before freeing
	SAPathfinder.remove_wall(get_parent().global_position)
	get_parent().queue_free()
