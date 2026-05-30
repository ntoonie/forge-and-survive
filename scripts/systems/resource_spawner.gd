extends Node

const TILE_SIZE = 32
const MAP_MIN_X = 2
const MAP_MAX_X = 33
const MAP_MIN_Y = 2
const MAP_MAX_Y = 17

# How many of each resource to spawn
const IRON_COUNT = 3
const WOOD_COUNT = 3
const STONE_COUNT = 3

# Forge center — avoid spawning too close
const FORGE_TILE = Vector2i(17, 9)
const MIN_DISTANCE_FROM_FORGE = 5

var iron_scene = preload("res://scenes/world/ironnode.tscn")
var wood_scene = preload("res://scenes/world/woodnode.tscn")
var stone_scene = preload("res://scenes/world/stonenode.tscn")

var used_positions: Array = []

func _ready():
	print("ResourceSpawner started!")
	_spawn_resources()
	print("Resources spawned: ", used_positions.size())

func _spawn_resources():
	# Spawn each resource type
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
	print("Spawning resource at: ", world_pos)
	node.global_position = world_pos
	
	var world = get_tree().current_scene.find_child("World")
	if world:
		world.add_child(node)
	else:
		print("World node not found!")
	used_positions.append(pos)

func _get_random_position() -> Vector2i:
	var attempts = 0
	while attempts < 50:
		var x = randi_range(MAP_MIN_X, MAP_MAX_X)
		var y = randi_range(MAP_MIN_Y, MAP_MAX_Y)
		var candidate = Vector2i(x, y)

		# Check not too close to forge
		var dist_to_forge = abs(x - FORGE_TILE.x) + abs(y - FORGE_TILE.y)
		if dist_to_forge < MIN_DISTANCE_FROM_FORGE:
			attempts += 1
			continue

		# Check not overlapping existing resource
		if candidate in used_positions:
			attempts += 1
			continue

		return candidate
		attempts += 1
	return Vector2i(-1, -1)  # Failed to find position
