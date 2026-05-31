extends Area2D

const TICK_DAMAGE   : int   = 15      # 2× arrow tower's 10
const TICK_INTERVAL : float = 1

# Enemies currently standing on the spikes
var _bodies_in_zone : Array[Node] = []

# ── Spike durability ───────────────────────────────────────────
var ticks_remaining: int = 15

@onready var tick_timer : Timer = $DamageTimer


func _ready() -> void:
    # Area2D overlap signals
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # Damage tick
    tick_timer.wait_time = TICK_INTERVAL
    tick_timer.autostart  = true
    tick_timer.timeout.connect(_on_tick)
    tick_timer.start()


# ── Overlap tracking ──────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("enemy"):
        _bodies_in_zone.append(body)
        print("Floor spike contacted enemy! Enemy health: ", body.current_health)


func _on_body_exited(body: Node) -> void:
    _bodies_in_zone.erase(body)


# ── Periodic tick ─────────────────────────────────────────────────

func _on_tick() -> void:
    # Only consume durability when there are enemies to damage
    var enemies_hit := false
    # Iterate a copy so mid-loop removal (enemy death) is safe
    for enemy in _bodies_in_zone.duplicate():
        if is_instance_valid(enemy) and enemy.has_method("take_damage"):
            enemy.take_damage(TICK_DAMAGE)
            enemies_hit = true

    if enemies_hit:
        ticks_remaining -= 1
        if ticks_remaining <= 0:
            print("Floor spikes exhausted after repeated use!")
            queue_free()