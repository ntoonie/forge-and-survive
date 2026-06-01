extends CharacterBody2D

var SPEED = 80.0
const FORGE_POSITION = Vector2(576, 320)
const ATTACK_RANGE   = 8.0
const WAYPOINT_REACH = 12.0

@export var max_health: int = 30
var current_health: int
var enemy_damage: int = 10

# ── SA PATH ───────────────────────────────────────────────────
var sa_path: PackedVector2Array = []
var path_index: int = 0

# ── ATTACK COOLDOWN ───────────────────────────────────────────
var attack_cooldown: float = 0.0
const ATTACK_INTERVAL: float = 2.0

# ── ESCAPE STATE MACHINE ──────────────────────────────────────
#
#  NORMAL  → move straight toward target
#              collision → store wall normal, enter BACK_UP
#
#  BACK_UP → push along wall normal for BACKUP_DURATION seconds
#              timer done → pick the wall-parallel that faces the
#              target, enter STEER
#
#  STEER   → travel in _steer_dir every frame (no burst-peek logic)
#             Exit condition: a test-only probe of STEER_CLEAR_PX
#             pixels in desired_dir succeeds WITHOUT collision.
#             That proves the obstacle edge is behind us, not just
#             that one frame's tiny motion happened to be free.
#             Flip side only when hitting something NEW while steering
#             AND only once per steer session (prevents oscillation).
#             Give up after STEER_MAX_PX → SA repath.

enum EscapePhase { NORMAL, BACK_UP, STEER }

const BACKUP_DURATION  : float = 0.22   # seconds pushing away from wall
const BACKUP_SPEED_MUL : float = 0.55   # speed fraction while backing up
const STEER_SPEED_MUL  : float = 0.90   # speed fraction while steering
const STEER_CLEAR_PX   : float = 28.0   # probe distance that must be clear to exit steer
const STEER_MAX_PX     : float = 220.0  # total steer distance before SA repath
const STEER_FLIP_ONCE  : bool  = true   # allow at most one direction flip per steer session

var _escape_phase    : EscapePhase = EscapePhase.NORMAL
var _backup_dir      : Vector2     = Vector2.ZERO
var _backup_timer    : float       = 0.0
var _steer_dir       : Vector2     = Vector2.ZERO
var _steer_traveled  : float       = 0.0
var _steer_flipped   : bool        = false   # has the direction already been flipped once?

signal died

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	add_to_group("enemy")
	var forge = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION
	sa_path = SAPathfinder.find_path(global_position, forge_pos)
	path_index = 0

func apply_wave_config(config: Dictionary):
	max_health     = config["enemy_health"]
	current_health = max_health
	SPEED          = config["enemy_speed"]
	enemy_damage   = config.get("enemy_damage", 10)

func _physics_process(_delta: float) -> void:
	var forge     = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION

	# ── Resolve current waypoint target ───────────────────────
	var target_pos: Vector2
	if sa_path.size() > 0 and path_index < sa_path.size():
		target_pos = sa_path[path_index]
		if global_position.distance_to(target_pos) <= WAYPOINT_REACH:
			path_index += 1
			if path_index >= sa_path.size():
				target_pos = _closest_forge_point(forge_pos)
	else:
		target_pos = _closest_forge_point(forge_pos)

	# ── Forge attack check ─────────────────────────────────────
	var forge_edge = _closest_forge_point(forge_pos)
	if attack_cooldown > 0.0:
		attack_cooldown -= _delta
	if global_position.distance_to(forge_edge) <= ATTACK_RANGE:
		if attack_cooldown <= 0.0:
			_attack_forge(forge)
			attack_cooldown = ATTACK_INTERVAL
		return

	var desired_dir := (target_pos - global_position).normalized()

	# ── FSM ───────────────────────────────────────────────────
	match _escape_phase:

		EscapePhase.NORMAL:
			var col : KinematicCollision2D = move_and_collide(desired_dir * SPEED * _delta)
			if col:
				_check_pile_attack(col, forge)
				_backup_dir   = col.get_normal()
				_backup_timer = BACKUP_DURATION
				_escape_phase = EscapePhase.BACK_UP
				_update_sprite(_backup_dir)
			else:
				_update_sprite(desired_dir)

		EscapePhase.BACK_UP:
			_backup_timer -= _delta
			var back_col : KinematicCollision2D = move_and_collide(
				_backup_dir * SPEED * BACKUP_SPEED_MUL * _delta
			)
			if back_col:
				_check_pile_attack(back_col, forge)
			_update_sprite(_backup_dir)

			if _backup_timer <= 0.0:
				# Pick the wall-parallel (perpendicular to wall normal) that
				# points most toward the target.  This is the direction that
				# carries the enemy around the obstacle edge, not back into it.
				var perp_a : Vector2 = Vector2(-_backup_dir.y,  _backup_dir.x)
				var perp_b : Vector2 = Vector2( _backup_dir.y, -_backup_dir.x)
				_steer_dir    = perp_a if perp_a.dot(desired_dir) >= perp_b.dot(desired_dir) \
								else perp_b
				_steer_traveled = 0.0
				_steer_flipped  = false
				_escape_phase   = EscapePhase.STEER

		EscapePhase.STEER:
			# ── Give-up guard ──────────────────────────────────────
			if _steer_traveled >= STEER_MAX_PX:
				_escape_phase = EscapePhase.NORMAL
				var forge_r   = get_tree().get_first_node_in_group("forge")
				var fp        = forge_r.global_position if forge_r else FORGE_POSITION
				sa_path       = SAPathfinder.find_path(global_position, fp)
				path_index    = 0
				return

			# ── Move laterally ─────────────────────────────────────
			var step      : float                = SPEED * STEER_SPEED_MUL * _delta
			var steer_col : KinematicCollision2D = move_and_collide(_steer_dir * step)
			_steer_traveled += step

			if steer_col:
				# Hit a new obstacle while steering.
				_check_pile_attack(steer_col, forge)
				# Flip direction once per steer session to try the other side.
				# After that, give up immediately and repath — enemy is cornered.
				if not _steer_flipped:
					_steer_dir     = -_steer_dir
					_steer_flipped = true
					_steer_traveled = 0.0   # fresh budget for the new direction
				else:
					# Both sides blocked — repath from current position
					_escape_phase = EscapePhase.NORMAL
					var forge_r   = get_tree().get_first_node_in_group("forge")
					var fp        = forge_r.global_position if forge_r else FORGE_POSITION
					sa_path       = SAPathfinder.find_path(global_position, fp)
					path_index    = 0
					return
			else:
				# Steer move succeeded.  Now test a STEER_CLEAR_PX probe
				# in desired_dir.  Only exit when that probe is also clear —
				# this confirms the obstacle edge is behind us, not just that
				# one frame of sideways movement happened to not collide.
				var probe_col : KinematicCollision2D = move_and_collide(
					desired_dir * STEER_CLEAR_PX, true
				)
				if not probe_col:
					# Forward is clear — resume normal movement
					_escape_phase = EscapePhase.NORMAL

			_update_sprite(_steer_dir)

	# Map boundary clamp
	global_position.x = clamp(global_position.x, -10.0, 1142.0)
	global_position.y = clamp(global_position.y, 90.0, 826.0)

# ── Helpers ───────────────────────────────────────────────────

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
	if collider.has_node("StructureHealth"):
		if attack_cooldown <= 0.0:
			collider.get_node("StructureHealth").take_damage(enemy_damage)
			attack_cooldown = ATTACK_INTERVAL
	var forge_pos = forge.global_position if forge else FORGE_POSITION
	if collider.is_in_group("forge") or \
	   (collider.is_in_group("enemy") and global_position.distance_to(forge_pos) < 150.0):
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
		forge.take_damage(enemy_damage)
		print("Forge attacked! Health: ", forge.current_health)

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		died.emit()
		queue_free()
