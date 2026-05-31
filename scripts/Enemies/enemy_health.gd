extends CharacterBody2D

var SPEED = 80.0
const FORGE_POSITION = Vector2(576, 320) # Aligned center of the Forge
const ATTACK_RANGE   = 8.0               # Distance from the edge of the forge hitbox
const WAYPOINT_REACH = 12.0              # Distance to consider a waypoint "reached"

@export var max_health: int = 30
var current_health: int

# ── SA PATH ──────────────────────────────────────────
var sa_path: PackedVector2Array = []
var path_index: int = 0

# ── ATTACK COOLDOWN ──────────────────────────────────
var attack_cooldown: float = 0.0
const ATTACK_INTERVAL: float = 2.0

# ── ANGLE-SWEEP ESCAPE STATE ─────────────────────────
# Persists across physics frames so each frame advances
# the sweep by one 15° step rather than oscillating.
const SWEEP_STEP_DEG  := 15.0            # degrees rotated per blocked frame
const SWEEP_MAX_DEG   := 360.0           # full circle before giving up
var _sweep_dir        := Vector2.ZERO    # current candidate direction
var _sweep_accumulated := 0.0           # total degrees swept this episode

signal died

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	add_to_group("enemy")

	# Request an SA-optimised path from spawn → Forge at wave start
	var forge = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION
	sa_path = SAPathfinder.find_path(global_position, forge_pos)
	path_index = 0

func apply_wave_config(config: Dictionary):
	max_health = config["enemy_health"]
	current_health = max_health
	SPEED = config["enemy_speed"]

func _physics_process(_delta: float) -> void:  # _delta forwarded to move_and_collide
	var forge = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION

	# ── Determine current target ──────────────────────
	# Follow SA waypoints while available; then target the forge directly.
	var target_pos: Vector2
	if sa_path.size() > 0 and path_index < sa_path.size():
		target_pos = sa_path[path_index]

		# Advance to next waypoint when close enough
		if global_position.distance_to(target_pos) <= WAYPOINT_REACH:
			path_index += 1
			# If we just consumed the last waypoint, aim for forge edge
			if path_index >= sa_path.size():
				target_pos = _closest_forge_point(forge_pos)
	else:
		# No SA path (or exhausted) — aim for closest edge of the forge hitbox
		target_pos = _closest_forge_point(forge_pos)

	# ── Check arrival at forge ────────────────────────
	var forge_edge = _closest_forge_point(forge_pos)
	if attack_cooldown > 0.0:
		attack_cooldown -= _delta

	if global_position.distance_to(forge_edge) <= ATTACK_RANGE:
		if attack_cooldown <= 0.0:
			_attack_forge(forge)
			attack_cooldown = ATTACK_INTERVAL
		return

	# ── Move toward current target (angle-sweep escape) ──────────
	# Uses move_and_collide() so we get an explicit collision result
	# each frame without Godot's built-in slide behaviour masking it.
	var desired_dir := (target_pos - global_position).normalized()

	if _sweep_dir == Vector2.ZERO:
		# ── Normal travel: try the direct desired direction ───────
		var motion: Vector2 = desired_dir * SPEED * _delta
		var collision := move_and_collide(motion)
		if collision:
			_check_pile_attack(collision, forge)
			# Hit something — start a fresh sweep from the desired dir
			_sweep_dir         = desired_dir
			_sweep_accumulated = 0.0
			# Immediately take the first 15° step this frame
			_sweep_dir = _sweep_dir.rotated(deg_to_rad(SWEEP_STEP_DEG))
			_sweep_accumulated += SWEEP_STEP_DEG
			var sweep_motion: Vector2 = _sweep_dir * SPEED * _delta
			var sweep_col    := move_and_collide(sweep_motion)
			if sweep_col:
				_check_pile_attack(sweep_col, forge)
			if not sweep_col:
				# First step already clear — but stay in sweep mode
				# so next frame we exit cleanly only if still clear.
				_update_sprite(_sweep_dir)
			else:
				_update_sprite(_sweep_dir)   # still moving, just blocked
		else:
			# Clear path — stay in normal mode
			_update_sprite(desired_dir)
	else:
		# ── Sweep mode: advance one 15° step clockwise ───────────
		if _sweep_accumulated >= SWEEP_MAX_DEG:
			# Full 360° with no clear angle — request a fresh SA path
			_sweep_dir         = Vector2.ZERO
			_sweep_accumulated = 0.0
			var forge_r = get_tree().get_first_node_in_group("forge")
			var fp      = forge_r.global_position if forge_r else FORGE_POSITION
			sa_path    = SAPathfinder.find_path(global_position, fp)
			path_index = 0
			return

		_sweep_dir = _sweep_dir.rotated(deg_to_rad(SWEEP_STEP_DEG))
		_sweep_accumulated += SWEEP_STEP_DEG

		var sweep_motion: Vector2 = _sweep_dir * SPEED * _delta
		var sweep_col    := move_and_collide(sweep_motion)
		if sweep_col:
			_check_pile_attack(sweep_col, forge)
		if not sweep_col:
			# Direction is clear — exit sweep mode, resume normal travel
			_sweep_dir         = Vector2.ZERO
			_sweep_accumulated = 0.0
			_update_sprite(desired_dir)
		else:
			# Still blocked — keep sweeping next frame
			_update_sprite(_sweep_dir)

# Returns the closest point on the forge's 32x32 collision box
func _closest_forge_point(forge_pos: Vector2) -> Vector2:
	var box_min = forge_pos - Vector2(16, 16)
	var box_max = forge_pos + Vector2(16, 16)
	return Vector2(
		clamp(global_position.x, box_min.x, box_max.x),
		clamp(global_position.y, box_min.y, box_max.y)
	)

func _check_pile_attack(collision: KinematicCollision2D, forge: Node2D) -> void:
	if not collision: return
	var collider = collision.get_collider()
	if not collider: return
	
	var forge_pos = forge.global_position if forge else FORGE_POSITION
	# If bumping into the forge, or into another enemy while close to the forge
	if collider.is_in_group("forge") or (collider.is_in_group("enemy") and global_position.distance_to(forge_pos) < 150.0):
		if attack_cooldown <= 0.0:
			_attack_forge(forge)
			attack_cooldown = ATTACK_INTERVAL

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
	# Removed queue_free() to keep enemy alive and attacking

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
