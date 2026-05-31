extends StaticBody2D

@export var max_health: int = 100
@export var damage: int = 10
@export var attack_range: float = 150.0

var current_health: int
var enemies_in_range: Array = []

# ── Shot durability ────────────────────────────────────────────
var shots_remaining: int = 8

func _ready():
	current_health = max_health
	$DetectionRange.body_entered.connect(_on_enemy_entered)
	$DetectionRange.body_exited.connect(_on_enemy_exited)
	$ShootTimer.timeout.connect(_shoot)

func _on_enemy_entered(body):
	if body.is_in_group("enemy"):
		enemies_in_range.append(body)

func _on_enemy_exited(body):
	if body.is_in_group("enemy"):
		enemies_in_range.erase(body)

func _shoot():
	# Clean up dead enemies first
	enemies_in_range = enemies_in_range.filter(
		func(e): return is_instance_valid(e)
	)
	if enemies_in_range.size() == 0:
		return
	# Attack first enemy in range
	var target = enemies_in_range[0]
	target.take_damage(damage)
	print("Tower shot enemy! Enemy health: ", target.current_health)

	# Decrement shot durability
	shots_remaining -= 1
	if shots_remaining <= 0:
		print("Tower worn out after firing too many shots!")
		SAPathfinder.remove_wall(global_position)
		queue_free()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		SAPathfinder.remove_wall(global_position)
		queue_free()
