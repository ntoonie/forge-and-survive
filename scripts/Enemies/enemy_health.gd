extends CharacterBody2D

var SPEED = 80.0
const FORGE_POSITION = Vector2(576, 320) # Aligned center of the Forge
const ATTACK_RANGE   = 8.0               # Distance from the edge of the forge hitbox

@export var max_health: int = 30
var current_health: int

signal died

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	add_to_group("enemy")

func apply_wave_config(config: Dictionary):
	max_health = config["enemy_health"]
	current_health = max_health
	SPEED = config["enemy_speed"]

func _physics_process(_delta: float) -> void:
	var forge = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION

	# 1. Target the closest edge/corner of the Forge hitbox (32x32px boundary)
	var box_min = forge_pos - Vector2(16, 16)
	var box_max = forge_pos + Vector2(16, 16)
	var target_pos = Vector2(
		clamp(global_position.x, box_min.x, box_max.x),
		clamp(global_position.y, box_min.y, box_max.y)
	)

	# 2. Check if we have arrived at the edge of the Forge
	if global_position.distance_to(target_pos) <= ATTACK_RANGE:
		_attack_forge(forge)
		return

	# 3. Calculate direction to closest point on the Forge
	var desired_dir = (target_pos - global_position).normalized()
	velocity = desired_dir * SPEED

	# Move and handle collisions
	move_and_slide()

	# 4. Real-time collision avoidance (slide smoothly along wall tangents)
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		# Only slide if we are pushing against the collision boundary
		if normal.dot(desired_dir) < 0:
			# Get the two perpendicular tangents to the wall normal
			var tangent1 = Vector2(-normal.y, normal.x)
			var tangent2 = Vector2(normal.y, -normal.x)
			# Choose the tangent that makes positive progress toward the forge
			var slide_dir = tangent1 if tangent1.dot(desired_dir) > tangent2.dot(desired_dir) else tangent2
			# Move along the tangent
			velocity = slide_dir * SPEED
			move_and_slide()
			_update_sprite(slide_dir)
		else:
			_update_sprite(desired_dir)
	else:
		_update_sprite(desired_dir)

func _update_sprite(direction: Vector2) -> void:
	if anim:
		if direction.x < 0:
			anim.flip_h = true
		elif direction.x > 0:
			anim.flip_h = false
		if anim.animation != "running":
			anim.play("running")

func _attack_forge(forge = null):
	if forge == null:
		forge = get_tree().get_first_node_in_group("forge")
	if forge:
		forge.take_damage(10)
		print("Forge attacked! Health: ", forge.current_health)
	queue_free()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
