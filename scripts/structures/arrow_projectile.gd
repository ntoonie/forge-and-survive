extends Area2D

@export var speed: float = 420.0
@export var hit_radius: float = 3.0

var target: Node2D
var damage: int = 10
var _has_hit: bool = false
var _aim_direction: Vector2 = Vector2.RIGHT

@onready var projectile_shape: Polygon2D = $Polygon2D

func setup(target_node: Node2D, projectile_damage: int, spawn_origin: Vector2) -> void:
	target = target_node
	damage = projectile_damage
	global_position = spawn_origin

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	projectile_shape.visible = false
	queue_redraw()

func _draw() -> void:
	var arrow_color = Color(1.0, 0.85, 0.2)
	draw_line(Vector2(-10, 0), Vector2(5, 0), arrow_color, 3.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, 0),
		Vector2(2, -4),
		Vector2(2, 4)
	]), arrow_color)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target = target.global_position - global_position
	if to_target.length() <= hit_radius:
		_hit_target(target)
		return

	_aim_direction = to_target.normalized()
	rotation = _aim_direction.angle()
	global_position += _aim_direction * speed * delta
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body == target:
		_hit_target(body)

func _hit_target(body: Node) -> void:
	if _has_hit:
		return
	_has_hit = true
	if is_instance_valid(body) and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()