extends CharacterBody2D

const SPEED = 60.0
const FORGE_POSITION = Vector2(576.0, 320.0)

var path: PackedVector2Array = []
var path_index: int = 0

signal died

func _ready():
	path = SAPathfinder.find_path(global_position, FORGE_POSITION)
	path_index = 0

func _physics_process(_delta):
	if path_index >= path.size():
		_attack_forge()
		return

	var target = path[path_index]
	var direction = (target - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

	if global_position.distance_to(target) < 8.0:
		path_index += 1

func _attack_forge():
	print("Forge is under attack!")
	queue_free()

func take_damage(amount: int):
	died.emit()
	queue_free()
