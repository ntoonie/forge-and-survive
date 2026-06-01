extends Node

@export var max_health: int = 200
var current_health: int

# ── Collision durability ───────────────────────────────────────
var collisions_remaining: int = 5

var _contact_area: Area2D
var _tick_timer: Timer
var _bodies_in_zone: Array[Node2D] = []

func _ready():
	current_health = max_health

	# Create a contact area dynamically if parent is a StaticBody2D (e.g. Wall)
	var parent = get_parent()
	if parent is StaticBody2D:
		_setup_contact_area(parent)

func _setup_contact_area(parent: StaticBody2D) -> void:
	_contact_area = Area2D.new()
	_contact_area.monitorable = false
	parent.add_child.call_deferred(_contact_area)
	
	var shape_owner = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	# Find parent's CollisionShape2D to copy and slightly enlarge the dimensions
	var parent_shape = parent.get_node_or_null("CollisionShape2D")
	if parent_shape and parent_shape.shape is RectangleShape2D:
		rect_shape.size = parent_shape.shape.size + Vector2(2.0, 2.0)
	else:
		rect_shape.size = Vector2(34.0, 34.0) # default wall size is 32x32
		
	shape_owner.shape = rect_shape
	_contact_area.add_child(shape_owner)
	
	# Create and start tick timer
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 1.0
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_damage_tick)
	add_child(_tick_timer)

func _on_damage_tick() -> void:
	if not _contact_area:
		return
		
	var overlapping = _contact_area.get_overlapping_bodies()
	_bodies_in_zone.clear()
	for body in overlapping:
		if body.is_in_group("enemy") and is_instance_valid(body):
			_bodies_in_zone.append(body)
			
	if _bodies_in_zone.size() > 0:
		var active_enemies = _bodies_in_zone.size()
		var damage_to_take = active_enemies * 10
		
		# Direct damage deduction
		current_health -= damage_to_take
		print("Wall is in contact with enemies! Remaining Health: ", current_health)
		
		if current_health <= 0:
			_destroy()

func take_damage(amount: int):
	current_health -= amount
	print("Wall attacked by enemy! Health: ", current_health)
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
