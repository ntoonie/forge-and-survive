extends Node

const TILE_SIZE = 32
const COSTS = {
	"wall": {"stone": 3},
	"tower": {"wood": 2, "iron": 2},
	"floor_spikes": {"wood": 2, "stone": 2}
}

var selected_structure = "wall"
var build_mode = false
var wall_scene = preload("res://scenes/structures/wall.tscn")
var tower_scene = preload("res://scenes/structures/tower.tscn")
var floor_spikes_scene = preload("res://scenes/structures/floor_spikes.tscn")
var ghost: ColorRect

func _ready():
	ghost = ColorRect.new()
	ghost.size = Vector2(TILE_SIZE, TILE_SIZE)
	ghost.color = Color(0.5, 0.5, 1.0, 0.5)
	ghost.visible = false
	get_tree().current_scene.add_child.call_deferred(ghost)

func _process(_delta):
	if Input.is_action_just_pressed("toggle_build"):
		build_mode = !build_mode
		ghost.visible = build_mode
		print("Build mode: ", build_mode)

	if Input.is_action_just_pressed("select_tower"):
		selected_structure = "tower"
		ghost.color = Color(0.2, 0.8, 0.2, 0.5)
		print("Selected: Tower")

	if Input.is_action_just_pressed("select_wall"):
		selected_structure = "wall"
		ghost.color = Color(0.5, 0.5, 1.0, 0.5)
		print("Selected: Wall")

	if Input.is_action_just_pressed("select_spikes"):
		selected_structure = "floor_spikes"
		ghost.color = Color(1.0, 0.4, 0.1, 0.5)
		print("Selected: Floor Spike")

	if build_mode:
		_update_ghost()
		if Input.is_action_just_pressed("place"):
			_place_structure()

func _update_ghost():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var mouse = get_viewport().get_mouse_position()
	var world_pos = camera.global_position + (mouse - get_viewport().get_visible_rect().size / 2)
	var snapped = Vector2(
		floor(world_pos.x / TILE_SIZE) * TILE_SIZE,
		floor(world_pos.y / TILE_SIZE) * TILE_SIZE
	)
	ghost.global_position = snapped

func _place_structure():
	if not _can_afford():
		print("Not enough resources!")
		return

	var build_pos = ghost.global_position + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

	# 1. Do not allow building further than 4 block radius (4 * 32 = 128 pixels) from the player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = player.global_position.distance_to(build_pos)
		if distance > 128.0:
			print("Cannot build: Too far from player!")
			return

	# 2. Do not allow placing structures on top of each other
	var existing_structures = get_tree().get_nodes_in_group("structures")
	for s in existing_structures:
		if is_instance_valid(s) and s.global_position.distance_to(build_pos) < 5.0:
			print("Cannot build: Structure already exists here!")
			return

	var structure
	if selected_structure == "wall":
		structure = wall_scene.instantiate()
	elif selected_structure == "tower":
		structure = tower_scene.instantiate()
	else:
		structure = floor_spikes_scene.instantiate()
	structure.global_position = build_pos
	get_tree().current_scene.add_child(structure)
	structure.add_to_group("structures")

	# Notify pathfinder about new obstacle (walls and towers block movement)
	if selected_structure == "wall" or selected_structure == "tower":
		SAPathfinder.add_wall(structure.global_position)
		
		# Notify all living enemies to repath from their current position
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.has_method("request_repath"):
				enemy.request_repath()
	_deduct_cost()
	print("Placed: ", selected_structure)

func _can_afford() -> bool:
	var cost = COSTS[selected_structure]
	for resource in cost:
		if GameData.resources[resource] < cost[resource]:
			return false
	return true

func _deduct_cost():
	var cost = COSTS[selected_structure]
	for resource in cost:
		GameData.resources[resource] -= cost[resource]
