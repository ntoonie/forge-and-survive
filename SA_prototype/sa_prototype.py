import math
import random
import matplotlib.pyplot as plt

# ── GRID SETUP ──────────────────────────────────────
GRID_W = 35
GRID_H = 19
TILE   = 32

# Walls blocking the path (grid coordinates)
WALLS = {(5,5), (5,6), (5,7), (6,7), (7,7), (10,9), (11,9)}

# Traps (grid coordinates) — high cost to walk through
TRAPS = {(8,9), (9,9)}

# Start and goal
START = (0, 9)       # left edge, middle
GOAL  = (17, 9)      # center of map (forge)

# ── COST FUNCTION ───────────────────────────────────
def cost(path):
    total = 0
    for cell in path:
        if cell in WALLS:
            total += 1000   # never walk through walls
        elif cell in TRAPS:
            total += 50     # avoid traps if possible
        else:
            total += 1      # normal tile cost
    # Add path length penalty
    total += len(path) * 0.5
    return total

# ── BFS (initial path) ──────────────────────────────
def bfs(start, goal):
    queue = [start]
    came_from = {start: None}
    while queue:
        current = queue.pop(0)
        if current == goal:
            break
        x, y = current
        for dx, dy in [(1,0),(-1,0),(0,1),(0,-1)]:
            neighbor = (x+dx, y+dy)
            if (0 <= neighbor[0] < GRID_W and
                0 <= neighbor[1] < GRID_H and
                neighbor not in WALLS and
                neighbor not in came_from):
                came_from[neighbor] = current
                queue.append(neighbor)
    # Reconstruct path
    path = []
    step = goal
    while step is not None:
        path.append(step)
        step = came_from.get(step)
    path.reverse()
    return path

# ── GET NEIGHBOR SOLUTION ───────────────────────────
def get_neighbor(path):
    if len(path) < 3:
        return path
    new_path = path.copy()
    # Pick a random middle waypoint and shift it
    idx = random.randint(1, len(path) - 2)
    x, y = new_path[idx]
    dx = random.randint(-1, 1)
    dy = random.randint(-1, 1)
    new_x = max(0, min(GRID_W-1, x + dx))
    new_y = max(0, min(GRID_H-1, y + dy))
    new_path[idx] = (new_x, new_y)
    return new_path

# ── SIMULATED ANNEALING ─────────────────────────────
def simulated_annealing(initial_path,
                         initial_temp=100.0,
                         cooling_rate=0.95,
                         iterations=500):
    current = initial_path.copy()
    best    = current.copy()
    temp    = initial_temp
    temp_history = []

    for i in range(iterations):
        temp *= cooling_rate
        temp_history.append(temp)

        candidate = get_neighbor(current)
        delta = cost(candidate) - cost(current)

        # Accept better solution always
        # Accept worse solution with probability
        if delta < 0 or random.random() < math.exp(-delta / max(temp, 0.001)):
            current = candidate
            if cost(current) < cost(best):
                best = current.copy()

    return best, temp_history

# ── VISUALIZE ───────────────────────────────────────
def visualize(bfs_path, sa_path, temp_history):
    fig, axes = plt.subplots(1, 2, figsize=(16, 7))

    # ── Left: Map with paths ──
    ax = axes[0]
    ax.set_title("Map: BFS (blue) vs SA (red)", fontsize=14)
    ax.set_xlim(0, GRID_W)
    ax.set_ylim(0, GRID_H)
    ax.set_aspect('equal')
    ax.invert_yaxis()

    # Draw grid
    for x in range(GRID_W):
        for y in range(GRID_H):
            color = 'white'
            if (x, y) in WALLS:
                color = '#555555'
            elif (x, y) in TRAPS:
                color = '#cc4400'
            rect = plt.Rectangle((x, y), 1, 1,
                                   facecolor=color,
                                   edgecolor='#cccccc',
                                   linewidth=0.3)
            ax.add_patch(rect)

    # Draw start and goal
    ax.add_patch(plt.Rectangle((START[0], START[1]), 1, 1, facecolor='green'))
    ax.add_patch(plt.Rectangle((GOAL[0],  GOAL[1]),  1, 1, facecolor='gold'))

    # Draw BFS path
    if bfs_path:
        bx = [c[0]+0.5 for c in bfs_path]
        by = [c[1]+0.5 for c in bfs_path]
        ax.plot(bx, by, 'b-o', linewidth=2, markersize=4, label='BFS path')

    # Draw SA path
    if sa_path:
        sx = [c[0]+0.5 for c in sa_path]
        sy = [c[1]+0.5 for c in sa_path]
        ax.plot(sx, sy, 'r-o', linewidth=2, markersize=4, label='SA path')

    ax.legend()

    # ── Right: Temperature over time ──
    ax2 = axes[1]
    ax2.set_title("SA Temperature (Heat Meter)", fontsize=14)
    ax2.plot(temp_history, color='orange', linewidth=2)
    ax2.set_xlabel("Iteration")
    ax2.set_ylabel("Temperature")
    ax2.fill_between(range(len(temp_history)),
                      temp_history, alpha=0.3, color='orange')
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("sa_result.png")
    plt.show()
    print("Saved to sa_result.png")

# ── MAIN ────────────────────────────────────────────
if __name__ == "__main__":
    print("Running BFS...")
    bfs_path = bfs(START, GOAL)
    print(f"BFS path length: {len(bfs_path)}, cost: {cost(bfs_path):.1f}")

    print("Running Simulated Annealing...")
    sa_path, temp_history = simulated_annealing(bfs_path)
    print(f"SA path length:  {len(sa_path)}, cost: {cost(sa_path):.1f}")

    print("Visualizing...")
    visualize(bfs_path, sa_path, temp_history)