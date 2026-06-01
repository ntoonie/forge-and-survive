extends Node

# ── Config ────────────────────────────────────────────────────
const GRID_W         : int   = 36
const GRID_H         : int   = 23
const TILE           : int   = 32
const T_INITIAL      : float = 5.0
const COOLING_RATE   : float = 0.97
const CORRIDOR_CLAMP : float = 2.5     # max cell drift from BFS baseline
const WALL_PENALTY   : float = 1000.0
const TRAP_PENALTY   : float = 50.0
const TURN_WEIGHT    : float = 3.0

# ── Iteration budget: adaptive per path length ─────────────────
# Short paths (≤8 cells) need far fewer SA steps; long ones benefit
# from more. Capped at 300 to stay under ~0.5 ms on mid-range hardware.
const SA_ITER_PER_CELL : int = 12   # iterations allocated per path cell
const SA_ITER_MIN      : int = 60   # never fewer than this
const SA_ITER_MAX      : int = 300   # never more than this

const OFFSET_X         : float = -10.0
const OFFSET_Y         : float = 90.0

var wall_cells : Dictionary = {}   # cell : true
var trap_cells : Dictionary = {}   # cell : true

# ── Path cache ────────────────────────────────────────────────
# Key: String "<sx>,<sy>|<gx>,<gy>"  →  Value: PackedVector2Array
# Invalidated when any wall is added or removed.
var _path_cache     : Dictionary = {}
const CACHE_MAX     : int = 64   # evict oldest entries beyond this limit
var _cache_insert_order : Array = []   # tracks insertion order for LRU eviction

# ────────────────────────────────────────────────────────────────
# Wall registration
# ────────────────────────────────────────────────────────────────
func add_wall(world_pos: Vector2) -> void:
	var cell := _world_to_cell(world_pos)
	wall_cells[cell] = true
	_invalidate_cache()          # topology changed — all cached paths stale


func remove_wall(world_pos: Vector2) -> void:
	var cell := _world_to_cell(world_pos)
	wall_cells.erase(cell)
	_invalidate_cache()


func _invalidate_cache() -> void:
	_path_cache.clear()
	_cache_insert_order.clear()


# ────────────────────────────────────────────────────────────────
# Coordinate helpers
# ────────────────────────────────────────────────────────────────
func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x - OFFSET_X) / TILE,
		int(world_pos.y - OFFSET_Y) / TILE
	)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * TILE + OFFSET_X + TILE / 2,
		cell.y * TILE + OFFSET_Y + TILE / 2
	)


# ────────────────────────────────────────────────────────────────
# Public API — returns world-space waypoints, cache-aware
# ────────────────────────────────────────────────────────────────
func find_path(start_world: Vector2, goal_world: Vector2) -> PackedVector2Array:
	var start_cell := _world_to_cell(start_world)
	var goal_cell  := _world_to_cell(goal_world)
	var cache_key  := _make_key(start_cell, goal_cell)

	# ── Cache hit ────────────────────────────────────────────────
	if _path_cache.has(cache_key):
		return _path_cache[cache_key]

	# ── Cache miss — compute ──────────────────────────────────────
	var cells  := compute_path(start_cell, goal_cell)
	var result := PackedVector2Array()
	for c in cells:
		result.append(_cell_to_world(c))

	# ── Store in cache (LRU eviction at CACHE_MAX) ───────────────
	if _cache_insert_order.size() >= CACHE_MAX:
		var oldest_key : String = _cache_insert_order.pop_front()
		_path_cache.erase(oldest_key)

	_path_cache[cache_key]         = result
	_cache_insert_order.append(cache_key)

	return result


func _make_key(start: Vector2i, goal: Vector2i) -> String:
	return "%d,%d|%d,%d" % [start.x, start.y, goal.x, goal.y]


# ────────────────────────────────────────────────────────────────
# Core pipeline
# ────────────────────────────────────────────────────────────────
func compute_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var bfs_path : Array[Vector2i] = _bfs(start, goal)
	if bfs_path.is_empty():
		return []
	var sa_path : Array[Vector2i] = _sa(bfs_path)
	return sa_path


# ────────────────────────────────────────────────────────────────
# BFS baseline
# ────────────────────────────────────────────────────────────────
func _bfs(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var queue     : Array      = [start]
	var came_from : Dictionary = { start: null }
	var dirs      : Array      = [
		Vector2i(1,0), Vector2i(-1,0),
		Vector2i(0,1), Vector2i(0,-1)
	]

	while not queue.is_empty():
		var cur : Vector2i = queue.pop_front()
		if cur == goal:
			break
		for d in dirs:
			var nb : Vector2i = cur + d
			if nb.x < 0 or nb.x >= GRID_W: continue
			if nb.y < 0 or nb.y >= GRID_H: continue
			if wall_cells.has(nb):          continue
			if came_from.has(nb):           continue
			came_from[nb] = cur
			queue.append(nb)

	var path : Array[Vector2i] = []
	var step = goal
	while step != null and came_from.has(step):
		path.append(step)
		var parent = came_from[step]
		if parent == null:
			break
		step = parent
	path.reverse()
	return path


# ────────────────────────────────────────────────────────────────
# Cost function
# ────────────────────────────────────────────────────────────────
func _cost(path: Array[Vector2i]) -> float:
	var total : float = 0.0

	for i in range(path.size() - 1):
		total += path[i].distance_to(path[i + 1])

	for i in range(1, path.size() - 1):
		var v1  : Vector2 = Vector2(path[i]   - path[i - 1])
		var v2  : Vector2 = Vector2(path[i+1] - path[i])
		var mag : float   = v1.length() * v2.length() + 1e-9
		total += (1.0 - (v1.dot(v2) / mag)) * TURN_WEIGHT

	for cell in path:
		if wall_cells.has(cell): total += WALL_PENALTY
		if trap_cells.has(cell): total += TRAP_PENALTY

	return total


# ────────────────────────────────────────────────────────────────
# Mutation with corridor clamp
# ────────────────────────────────────────────────────────────────
func _mutate(path: Array[Vector2i], bfs_ref: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() < 3:
		return path

	var new_path : Array[Vector2i] = path.duplicate()
	var idx      : int             = randi_range(1, path.size() - 2)
	var nx       : int             = new_path[idx].x + randi_range(-1, 1)
	var ny       : int             = new_path[idx].y + randi_range(-1, 1)
	var ref      : Vector2i        = bfs_ref[min(idx, bfs_ref.size() - 1)]

	nx = clamp(nx, ref.x - int(CORRIDOR_CLAMP), ref.x + int(CORRIDOR_CLAMP))
	ny = clamp(ny, ref.y - int(CORRIDOR_CLAMP), ref.y + int(CORRIDOR_CLAMP))
	nx = clamp(nx, 0, GRID_W - 1)
	ny = clamp(ny, 0, GRID_H - 1)

	new_path[idx] = Vector2i(nx, ny)
	return new_path


# ────────────────────────────────────────────────────────────────
# Simulated Annealing — adaptive iteration budget
# ────────────────────────────────────────────────────────────────
func _sa(bfs_path: Array[Vector2i]) -> Array[Vector2i]:
	# Scale iterations to path length so short paths stay cheap.
	var iterations : int = clamp(
		bfs_path.size() * SA_ITER_PER_CELL,
		SA_ITER_MIN,
		SA_ITER_MAX
	)

	var current  : Array[Vector2i] = bfs_path.duplicate()
	var best     : Array[Vector2i] = current.duplicate()
	var best_cost : float          = _cost(best)
	var temp     : float           = T_INITIAL

	for _i in range(iterations):
		temp *= COOLING_RATE

		var candidate      : Array[Vector2i] = _mutate(current, bfs_path)
		var candidate_cost : float           = _cost(candidate)
		var current_cost   : float           = _cost(current)
		var delta          : float           = candidate_cost - current_cost

		if delta < 0.0 or randf() < exp(-delta / max(temp, 0.001)):
			current = candidate
			if candidate_cost < best_cost:
				best      = candidate.duplicate()
				best_cost = candidate_cost

	return best
