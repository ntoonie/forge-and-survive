# Forge and Survive

Forge and Survive is a top-down 2D resource-gathering and survival game prototype currently transitioning to a desktop-native application built with Raylib 5.0 and C++, targeting a 16-bit / Game Boy Advance graphical aesthetic. It features character movement, an area-based interaction system, a centralized global game state to manage gathered resources, and advanced pathfinding algorithms.

## Project Structure

The project is structured into two main directories: the original Godot 4.6 prototype and the new native Raylib implementation (`New-Forge`).

```
forge-and-survive/
├── assets/
│   └── sprites/
│       ├── enemy_1.png         # Spritesheet asset for enemies
│       ├── player.png          # Spritesheet asset for player
│       └── terrain_tiles/      # Terrain tiles and environment assets
├── SA_prototype/
│   ├── sa_prototype.py         # Python simulated annealing prototype
│   └── sa_result.png           # Exported visual result of python prototype
└── README.md                   # Project documentation

New-Forge/
├── CMakeLists.txt              # CMake build configuration fetching Raylib 5.0
└── src/
	├── main.cpp                # Application entry point and main loop
	├── game.h/.cpp             # Global state and Day/Night loop management
	├── player.h/.cpp           # Player controller and rendering
	├── world.h/.cpp            # Tilemap rendering and resource nodes
	├── enemy_ai.h/.cpp         # Simulated Annealing AI and enemies
	└── build_system.h/.cpp     # Structure placement logic
```

## System Architecture (Raylib 5.0 C++ Port)

The Raylib implementation is built around a decoupled object-oriented architecture in C++, adopting principles from the original Godot node hierarchy while maximizing native performance.

### 1. Global State Management
* **Component:** `Game` Class
* **Purpose:** Acts as a centralized manager that persists throughout the application lifecycle.
* **Details:**
  * Maintains an internal state of resource counts: `iron`, `wood`, and `stone`.
  * Manages the Day (Build Phase) and Night (Defense Phase) cycles.
  * Adjusts the render target canvas shading for night transitions.

### 2. Player Controller
* **Component:** `Player` Class
* **Purpose:** Handles physics-based movement, collision detection, and sprite rendering.
* **Details:**
  * Reads 8-directional input via WASD or arrow keys.
  * Normalizes movement vectors to maintain a consistent speed of `150.0` pixels per second.
  * Utilizes Raylib texture drawing functions to animate the player sprite from `player.png`.

### 3. Proximity Interaction System
* **Component:** `World` and `ResourceNode` Classes
* **Purpose:** Logic for interactive world objects (Wood, Stone, Iron).
* **Details:**
  * Uses simple circle/rectangle collision checks (`CheckCollisionCircleRec`) to detect player proximity.
  * Listens for the `interact` action (mapped to the physical **E** key).
  * Safely increments resource counts in the `Game` state and removes collected nodes from the active list.

### 4. Build System & Grid Snapping
* **Component:** `BuildSystem` Class
* **Purpose:** Grid placement controller for player defenses (Walls, Towers).
* **Details:**
  * Uses 32x32 tiles for grid snapping coordinates.
  * Displays a visual semi-transparent ghost preview following the mouse cursor.
  * Validates material costs against the global resource state before finalizing placement.

### 5. Simulated Annealing Pathfinding
* **Component:** `EnemyAI` Class
* **Purpose:** AI path calculation utilizing local search optimization.
* **Details:**
  * Translated from the Python/GDScript prototypes.
  * Finds an initial path using Breadth-First Search (BFS) on the grid.
  * Refines waypoints using simulated annealing over multiple iterations.
  * Calculates path cost by factoring in distance and obstacle penalties.
  * Dynamically accepts sub-optimal route mutations based on a falling cooling temperature, creating varied raider approach patterns.

## Inputs and Controls

* **Movement:** 
  * Up: `W` or `Up Arrow`
  * Down: `S` or `Down Arrow`
  * Left: `A` or `Left Arrow`
  * Right: `D` or `Right Arrow`
* **Actions:**
  * Toggle Build Mode: `B`
  * Select Wall Structure: `1`
  * Select Tower Structure: `2`
  * Place Structure: `Left Mouse Button`
  * Gather Resource: `E`

## Getting Started (Raylib Native Build)

1. Ensure you have CMake and a C++ compiler (like MSVC, GCC, or Clang) installed.
2. Navigate into the `New-Forge` directory.
3. Generate the build files:
   `cmake -B build`
4. Compile the project:
   `cmake --build build --config Release`
5. Run the generated executable. The game will automatically render at a low internal resolution scaled up to fit your window, preserving the 16-bit GBA aesthetic.

---

## Development Roadmap & Status

This project is actively transitioning from Godot to Raylib.

### Phase 1: Engine Migration & Project Setup
* **Status:** In Progress
* **Details:** Establishing CMake build systems and the core windowing logic using Raylib 5.0.

### Phase 2: Core Gameplay Port
* **Status:** Planned
* **Details:** Implementing tilemap rendering, player movement, and resource gathering logic in C++.

### Phase 3: Defense & Building Port
* **Status:** Planned
* **Details:** Porting the grid snapping and structure placement logic.

### Phase 4: Simulated Annealing AI Port
* **Status:** Planned
* **Details:** Translating the GDScript pathfinder to a performant native C++ implementation.
