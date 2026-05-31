extends CharacterBody2D

const SPEED = 150.0

# AnimatedSprite2D2 is added as a child of the Player instance in World.tscn
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D2

func _physics_process(_delta):
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()

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
