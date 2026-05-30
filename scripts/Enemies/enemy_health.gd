extends CharacterBody2D

var SPEED = 80.0
const FORGE_POSITION = Vector2(544, 288)
const ATTACK_RANGE   = 40.0

@export var max_health: int = 30
var current_health: int

signal died

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ── State machine ─────────────────────────────────────────
enum State { SEEK, AVOID }
var _state := State.SEEK

# AVOID state
var _avoid_dir:   Vector2 = Vector2.ZERO
var _avoid_timer: float   = 0.0
const AVOID_DURATION = 1.0   # seconds to go perpendicular before retrying

# Stuck detection — compare position every interval
var _last_pos:         Vector2 = Vector2.ZERO
var _stuck_poll_timer: float   = 0.0
const POLL_INTERVAL  = 0.12   # how often to sample position
const STUCK_MIN_DIST = 3.0    # must move at least this many px per interval

func _ready():
	current_health = max_health
	add_to_group("enemy")
	_last_pos = global_position

func apply_wave_config(config: Dictionary):
	max_health = config["enemy_health"]
	current_health = max_health
	SPEED = config["enemy_speed"]

func _physics_process(delta):
	var forge     = get_tree().get_first_node_in_group("forge")
	var forge_pos = forge.global_position if forge else FORGE_POSITION

	if global_position.distance_to(forge_pos) <= ATTACK_RANGE:
		_attack_forge(forge)
		return

	match _state:
		State.SEEK:
			_do_seek(delta, forge_pos)
		State.AVOID:
			_do_avoid(delta, forge_pos)

# ── SEEK: move straight toward forge, detect if stuck ─────
func _do_seek(delta: float, forge_pos: Vector2) -> void:
	var dir = (forge_pos - global_position).normalized()
	velocity = dir * SPEED
	move_and_slide()

	# Poll position to see if we actually moved
	_stuck_poll_timer += delta
	if _stuck_poll_timer >= POLL_INTERVAL:
		var moved = global_position.distance_to(_last_pos)
		if moved < STUCK_MIN_DIST:
			_enter_avoid(dir, forge_pos)   # blocked — go perpendicular
		_last_pos         = global_position
		_stuck_poll_timer = 0.0

	_update_sprite(dir)

# ── AVOID: move perpendicular for AVOID_DURATION, then retry
func _do_avoid(delta: float, forge_pos: Vector2) -> void:
	_avoid_timer -= delta
	if _avoid_timer <= 0.0:
		_state            = State.SEEK
		_last_pos         = global_position
		_stuck_poll_timer = 0.0
		return

	velocity = _avoid_dir * SPEED
	move_and_slide()
	_update_sprite(_avoid_dir)

# ── Pick axis-aligned perpendicular direction ─────────────
func _enter_avoid(seek_dir: Vector2, forge_pos: Vector2) -> void:
	if abs(seek_dir.x) >= abs(seek_dir.y):
		# Primarily moving horizontally → dodge vertically
		# Pick up or down — whichever is closer to the forge
		_avoid_dir = Vector2(0.0, -1.0) if forge_pos.y < global_position.y else Vector2(0.0, 1.0)
	else:
		# Primarily moving vertically → dodge horizontally
		_avoid_dir = Vector2(-1.0, 0.0) if forge_pos.x < global_position.x else Vector2(1.0, 0.0)

	_avoid_timer      = AVOID_DURATION
	_last_pos         = global_position
	_stuck_poll_timer = 0.0
	_state            = State.AVOID

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
