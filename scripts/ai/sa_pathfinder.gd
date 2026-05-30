extends Node

# ── SETTINGS ────────────────────────────────────────
const INITIAL_TEMP = 100.0
const COOLING_RATE = 0.95
const ITERATIONS   = 300
const TILE_SIZE    = 32
const GRID_W       = 35
const GRID_H       = 19

# ── COSTS ────────────────────────────────────────────
const WALL_COST  = 1000.0
const TRAP_COST  = 50.0
const NORMAL_COST = 1.0

var current_temperature: float = INITIAL_TEMP
var wall_positions: Array = []
var trap_positions: Array = []

signal temperature_changed(new_temp)

# ── MAIN FUNCTION ────────────────────────────────────
func find_path(start: Vector2, goal: Vector2) -> PackedVector2Array:
	# Step 1: Get initial path using BFS
	var initial_path = _bfs(start, goal)
	if initial_path.is_empty():
		return PackedVector2Array()

	# Step 2: Optimize with SA
	var current = initial_path.duplicate()
	var best    = current.duplicate()
	current_temperature = INITIAL_TEMP

	for _i in ITERATIONS:
		current_temperature *= COOLING_RATE
		temperature_changed.emit(current_temperature)

		var candidate = _get_neighbor(current)
		var delta = _cost(candidate) - _cost(current)

		if delta < 0 or randf() < exp(-delta / max(current_temperature, 0.001)):
			current = candidate.duplicate()
			if _cost(current) < _cost(best):
				best = current.duplicate()

	return best

# ── BFS ──────────────────────────────────────────────
func _bfs(start: Vector2, goal: Vector2) -> PackedVector2Array:
	var start_cell = _world_to_cell(start)
	var goal_cell  = _world_to_cell(goal)

	var queue      = [start_cell]
	var came_from  = {start_cell: null}

	while queue.size() > 0:
		var current = queue.pop_front()
		if current == goal_cell:
			break
		for neighbor in _get_neighbors(current):
			if neighbor not in came_from:
				came_from[neighbor] = current
				queue.append(neighbor)

	# Reconstruct path as world positions
	var path = PackedVector2Array()
	var step = goal_cell
	while step != null:
		path.insert(0, _cell_to_world(step))
		step = came_from.get(step, null)
	return path

# ── COST FUNCTION ────────────────────────────────────
func _cost(path: PackedVector2Array) -> float:
	var total = 0.0
	for point in path:
		var cell = _world_to_cell(point)
		if cell in wall_positions:
			total += WALL_COST
		elif cell in trap_positions:
			total += TRAP_COST
		else:
			total += NORMAL_COST
	total += path.size() * 0.5
	return total

# ── GET NEIGHBOR SOLUTION ────────────────────────────
func _get_neighbor(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() < 3:
		return path
	var new_path = path.duplicate()
	var idx = randi_range(1, path.size() - 2)
	var cell = _world_to_cell(new_path[idx])
	var dx = randi_range(-1, 1)
	var dy = randi_range(-1, 1)
	var new_cell = Vector2i(
		clamp(cell.x + dx, 0, GRID_W - 1),
		clamp(cell.y + dy, 0, GRID_H - 1)
	)
	new_path[idx] = _cell_to_world(new_cell)
	return new_path

# ── NEIGHBOR CELLS (for BFS) ─────────────────────────
func _get_neighbors(cell: Vector2i) -> Array:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var result = []
	for d in dirs:
		var n = cell + d
		if n.x >= 0 and n.x < GRID_W and n.y >= 0 and n.y < GRID_H:
			if n not in wall_positions:
				result.append(n)
	return result

# ── HELPERS ──────────────────────────────────────────
func _world_to_cell(world: Vector2) -> Vector2i:
	return Vector2i(int(world.x / TILE_SIZE), int(world.y / TILE_SIZE))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2,
				   cell.y * TILE_SIZE + TILE_SIZE / 2)

# ── UPDATE WALLS/TRAPS ───────────────────────────────
func add_wall(world_pos: Vector2):
	var cell = _world_to_cell(world_pos)
	if cell not in wall_positions:
		wall_positions.append(cell)

func remove_wall(world_pos: Vector2):
	var cell = _world_to_cell(world_pos)
	wall_positions.erase(cell)

func add_trap(world_pos: Vector2):
	var cell = _world_to_cell(world_pos)
	if cell not in trap_positions:
		trap_positions.append(cell)

func spike_temperature(amount: float = 50.0):
	current_temperature += amount
	temperature_changed.emit(current_temperature)
