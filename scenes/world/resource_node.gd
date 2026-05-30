extends Area2D

@export var resource_type: String = "iron"
@export var amount: int = 10

var player_nearby = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		_gather()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _gather():
	GameData.add_resource(resource_type, amount)
	queue_free()
