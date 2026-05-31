extends TextureProgressBar

var forge: Node2D

func _ready() -> void:
	# Query the forge node in deferred ready to ensure the forge node is loaded in the scene tree
	call_deferred("_find_forge")

func _find_forge() -> void:
	forge = get_tree().get_first_node_in_group("forge")
	if forge:
		max_value = forge.max_health
		value = forge.current_health
	else:
		push_warning("Forge health bar: Forge not found in 'forge' group.")

func _process(_delta: float) -> void:
	if is_instance_valid(forge):
		value = forge.current_health
