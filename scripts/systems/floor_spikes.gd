extends Area2D

## Damage dealt to enemies that walk over the spikes each tick.
@export var damage_per_tick: int = 5

## How often (in seconds) the spikes deal damage to overlapping enemies.
@export var tick_interval: float = 0.8

# Tracks enemies currently standing on the spikes.
var _enemies_on_spikes: Array = []

@onready var _tick_timer: Timer = $DamageTimer


func _ready() -> void:
	# Spikes don't block movement — enemies walk through them.
	set_collision_layer(0)
	# Detect enemy bodies overlapping.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_tick_timer.wait_time = tick_interval
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_damage_tick)
	_tick_timer.start()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		_enemies_on_spikes.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		_enemies_on_spikes.erase(body)


func _on_damage_tick() -> void:
	# Purge any freed enemies before damaging.
	_enemies_on_spikes = _enemies_on_spikes.filter(
		func(e): return is_instance_valid(e)
	)
	for enemy in _enemies_on_spikes:
		enemy.take_damage(damage_per_tick)
		print("Floor spikes hit enemy for ", damage_per_tick, " dmg. Remaining HP: ", enemy.current_health)
