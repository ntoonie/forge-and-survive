extends CharacterBody2D

const SPEED = 150.0

# AnimatedSprite2D2 is added as a child of the Player instance in World.tscn
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D2

func _physics_process(_delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()

	# Clamp player's position within the expanded TileMapLayer boundary
	# Original: (9.0, 36.0) to (1129.0, 644.0)
	# Allowed: 2 pixel floorings (64 px) above and below, 1 pixel flooring (32 px) to the right
	position.x = clamp(position.x, 9.0, 1161.0)
	position.y = clamp(position.y, -28.0, 708.0)

	# Only control sprite if it exists (it lives in World.tscn, not player.tscn)
	if anim == null:
		return

	# Mirror sprite: default faces right, flip when going left
	if direction.x < 0:
		anim.flip_h = true
	elif direction.x > 0:
		anim.flip_h = false

	# Switch animation
	if velocity == Vector2.ZERO:
		if anim.animation != "idle":
			anim.play("idle")
	else:
		if anim.animation != "running":
			anim.play("running")


func _on_forge_child_order_changed() -> void:
	pass # Replace with function body.
