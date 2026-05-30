extends CharacterBody2D

var SPEED = 60.0
const FORGE_POSITION = Vector2(544, 288)

@export var max_health: int = 30
var current_health: int

var path: PackedVector2Array = []
var path_index: int = 0

signal died

func _ready():
	current_health = max_health
	add_to_group("enemy")
	path = SAPathfinder.find_path(global_position, FORGE_POSITION)
	path_index = 0
	print("Path length: ", path.size())

func apply_wave_config(config: Dictionary):
	max_health = config["enemy_health"]
	current_health = max_health
	SPEED = config["enemy_speed"]

func _physics_process(_delta):
	if path_index >= path.size():
		_attack_forge()
		return
	var target = path[path_index]
	var direction = (target - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()
	if global_position.distance_to(target) < 16.0:
		path_index += 1

func _attack_forge():
	var forge = get_tree().get_first_node_in_group("forge")
	if forge:
		forge.take_damage(10)
		print("Forge attacked! Health: ", forge.current_health)
	queue_free()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
