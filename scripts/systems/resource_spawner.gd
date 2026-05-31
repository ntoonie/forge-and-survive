extends Node

const TILE_SIZE = 32
const MAP_MIN_X = 2
const MAP_MAX_X = 33
const MAP_MIN_Y = 2
const MAP_MAX_Y = 17

const IRON_COUNT = 3
const WOOD_COUNT = 3
const STONE_COUNT = 3

const FORGE_TILE = Vector2i(17, 9)
const MIN_DISTANCE_FROM_FORGE = 5

var iron_scene = preload("res://scenes/world/ironnode.tscn")
var wood_scene = preload("res://scenes/world/woodnode.tscn")
var stone_scene = preload("res://scenes/world/stonenode.tscn")

var used_positions: Array = []
var spawned_nodes: Array = []

func _ready():
	# Listen for day phase
	var game_loop = get_tree().get_first_node_in_group("game_loop")
	if game_loop:
		game_loop.phase_changed.connect(_on_phase_changed)
	_spawn_resources()

func _on_phase_changed(new_phase):
	if new_phase == 0:  # Day phase started
		_respawn_resources()

func _respawn_resources():
	# Clear any remaining resource nodes
	for node in spawned_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_nodes.clear()
	used_positions.clear()
	# Spawn fresh resources
	_spawn_resources()
	print("Resources respawned for new day!")

func _spawn_resources():
	for i in IRON_COUNT:
		_spawn_resource(iron_scene)
	for i in WOOD_COUNT:
		_spawn_resource(wood_scene)
	for i in STONE_COUNT:
		_spawn_resource(stone_scene)

func _spawn_resource(scene: PackedScene):
	var pos = _get_random_position()
	if pos == Vector2i(-1, -1):
		print("Failed to find position!")
		return
	var node = scene.instantiate()
	var world_pos = Vector2(
		pos.x * TILE_SIZE + TILE_SIZE / 2,
		pos.y * TILE_SIZE + TILE_SIZE / 2
	)
	node.global_position = world_pos
	var world = get_tree().current_scene.find_child("World")
	if world:
		world.add_child(node)
		spawned_nodes.append(node)
	used_positions.append(pos)

func _get_random_position() -> Vector2i:
	var attempts = 0
	while attempts < 50:
		var x = randi_range(MAP_MIN_X, MAP_MAX_X)
		var y = randi_range(MAP_MIN_Y, MAP_MAX_Y)
		var candidate = Vector2i(x, y)
		var dist_to_forge = abs(x - FORGE_TILE.x) + abs(y - FORGE_TILE.y)
		if dist_to_forge < MIN_DISTANCE_FROM_FORGE:
			attempts += 1
			continue
		if candidate in used_positions:
			attempts += 1
			continue
		return candidate
	return Vector2i(-1, -1)
