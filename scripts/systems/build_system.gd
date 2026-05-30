extends Node

const TILE_SIZE = 32
const WALL_COST = {"stone": 1}

var build_mode = false
var wall_scene = preload("res://scenes/structures/wall.tscn")
var ghost: ColorRect
var can_place = false

func _ready():
	ghost = ColorRect.new()
	ghost.size = Vector2(TILE_SIZE, TILE_SIZE)
	ghost.color = Color(0.5, 0.5, 1.0, 0.5)
	ghost.visible = false
	get_tree().current_scene.add_child(ghost)

func _process(_delta):
	if Input.is_action_just_pressed("toggle_build"):
		build_mode = !build_mode
		ghost.visible = build_mode

	if build_mode:
		_update_ghost()
		if Input.is_action_just_pressed("place"):
			_place_wall()

func _update_ghost():
	var mouse = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	var world_pos = mouse + camera.global_position - get_viewport().get_visible_rect().size / 2
	var snapped = Vector2(
		floor(world_pos.x / TILE_SIZE) * TILE_SIZE,
		floor(world_pos.y / TILE_SIZE) * TILE_SIZE
	)
	ghost.global_position = snapped

func _place_wall():
	if not _can_afford():
		print("Not enough stone!")
		return
	var wall = wall_scene.instantiate()
	wall.global_position = ghost.global_position + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	get_tree().current_scene.add_child(wall)
	GameData.resources["stone"] -= WALL_COST["stone"]
	print("Wall placed! Stone remaining: ", GameData.resources["stone"])

func _can_afford() -> bool:
	return GameData.resources["stone"] >= WALL_COST["stone"]
