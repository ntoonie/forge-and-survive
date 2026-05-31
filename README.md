# Forge & Survive

Forge & Survive is a top-down 2D resource-gathering, survival, and tower defense game built with **Godot 4.6 (GL Compatibility/Compatibility renderer)**. Set in a 16-bit retro aesthetic, the game challenges the player to collect essential resources during the day, construct formidable defenses, and survive night waves of raiders that utilize a **Simulated Annealing AI pathfinding** model to navigate around obstacles and traps to destroy the central Forge.

---

## 📂 Project Directory Structure

Based on the `forge-and-survive/` folder layout:

```
forge-and-survive/
├── assets/
│   └── sprites/
│       ├── enemy_1.png         # Animated spritesheet for raider enemies
│       ├── player.png          # Animated spritesheet for the player
│       └── structure.png       # Atlas texture for walls, towers, and floor spikes
├── scenes/
│   ├── Main.tscn               # Master scene coordinating HUD, World, and loops
│   ├── Enemy/
│   │   └── character_body_2d.tscn # Enemy node base
│   ├── player/
│   │   # Player instantiations
│   ├── structures/
│   │   ├── floor_spikes.tscn   # Floor spikes Area2D structure
│   │   ├── forge.tscn          # Central Forge target structure
│   │   ├── tower.tscn          # Defensive Arrow Tower structure
│   │   └── wall.tscn           # Defensive Wall structure
│   ├── ui/
│   │   ├── HUD.tscn            # Canvas HUD showing wave timer, counts, resources
│   │   ├── VictoryScreen.tscn  # Game victory scene
│   │   ├── arrow_tower.tscn    # Defensive Arrow Tower instantiable scene
│   │   └── defeat_screen.tscn  # Defeat/Retry overlay scene
│   └── world/
│       ├── ResourceNode.tscn   # Base resource node template
│       ├── World.tscn          # Main level design tilemap & spawn markers
│       ├── ironnode.tscn       # Gatherable Iron Node
│       ├── stonenode.tscn      # Gatherable Stone Node
│       └── woodnode.tscn       # Gatherable Wood Node
├── scripts/
│   ├── Enemies/
│   │   ├── Raiderbody.gd       # Simple sliding navigation AI prototype
│   │   └── enemy_health.gd     # Main raider movement, path follower & state script
│   ├── ai/
│   │   └── sa_pathfinder.gd    # Simulated Annealing local optimization pathfinder
│   ├── player/
│   │   └── player.gd           # Physics-based player movement & sprite animation
│   ├── structures/
│   │   └── arrow_tower.gd      # Range detection & auto-shoot combat logic
│   ├── systems/
│   │   ├── build_system.gd     # Grid snapping placement, preview, & validation
│   │   ├── day_night_overlay.gd# Smooth overlay shading for phase transitions
│   │   ├── floor_spikes.gd     # Spikes periodic Area2D tick damage logic
│   │   ├── forge.gd            # Central objective state, health, & game over
│   │   ├── game_data.gd        # Global resource inventory Singleton
│   │   ├── game_loop.gd        # Phase-switching (Day/Night) wave controller
│   │   ├── resource_spawner.gd # Spawn controller for resource nodes
│   │   └── structure_health.gd # Reusable health, damage, & destruction node
│   └── ui/
│       ├── defeat_screen.gd
│       ├── hud.gd              # Dynamic label processing for player HUD
│       └── victory_screen.gd
├── SA_prototype/
│   ├── sa_prototype.py         # Python simulated annealing design script
│   └── sa_result.png           # Plotted path mutation visualization
├── project.godot               # Engine configuration & input mappings
└── README.md                   # Project documentation (This file)
```

## ⚙️ Core Systems & Game Architecture

### 1. Phase-based Game Loop (`game_loop.gd`, `day_night_overlay.gd`)
The gameplay transitions dynamically between two distinct states:
*   **Build Phase (Day - 60s):** The player gathers materials (Iron, Wood, Stone) and places defensive walls, arrow towers, and floor spikes.
*   **Defense Phase (Night):** Enemy raiders spawn from the outskirts and march toward the Forge. Building placement is locked. The night concludes when all enemies are defeated.
*   *Visuals:* A canvas overlay handles transitions, rendering a smooth dark color shading during the night to establish a tense defense atmosphere.

### 2. Grid Placement & Construction System (`build_system.gd`)
*   **Grid Size:** 32x32 pixel cells.
*   **Placement Mechanics:** Pressing `B` toggles Build Mode. A dynamic color-coded preview ghost (semi-transparent grid block) tracks the snapped mouse coordinate.
*   **Material Costs:**
    *   **Wall:** `1 Stone` — Blocks enemy navigation completely.
    *   **Arrow Tower:** `1 Wood + 1 Iron` — Automatically shoots the nearest target in range.
    *   **Floor Spikes:** `1 Wood + 1 Stone` — Allows enemies to pass over, but deals high periodic damage.

### 3. Structure Catalogue
*   **Wall (`wall.tscn`):** Hard solid obstacle with 100 HP, routing enemies through secondary pathways.
*   **Arrow Tower (`arrow_tower.gd`):** Uses an Area2D sensor to track encroaching enemies. Every `ShootTimer` interval, it shoots for **10 damage**.
*   **Floor Spikes (`floor_spikes.gd`):** An Area2D structure designed with a periodic tick timer (`0.8s` interval) that deals **20 damage** (double the tower's power!) to all overlapping raiders, bypassing movement blockages to weaken incoming waves.

### 4. Advanced Simulated Annealing AI (`sa_pathfinder.gd`, `enemy_health.gd`)
Enemies navigate using a premium hybrid AI model combining grid mapping and local search heuristics:
*   **Initial Vectoring:** A basic pathing blueprint serves as the navigation baseline.
*   **Simulated Annealing Optimization:** Waypoints along the candidate path are iteratively mutated (shifted) and evaluated against a comprehensive cost function:
    *   `Path Length:` Promotes shorter travel times.
    *   `Trap Penalties:` Heavily penalizes routes routing directly through active **Floor Spikes** or hazards.
*   **Stochastic Acceptance:** Even inferior path modifications are accepted with a probability of `P = e^(−ΔCost / T)`, enabling enemies to intelligently test flanking paths rather than getting funneled or trapped in predictable grid locks.
*   **Angle-Sweep Escape:** If stuck or obstructed, enemies utilize an active angle-sweep algorithm to seamlessly slide past walls and continue their advance.
*   **Swarm Pile-Up Logic:** Enemies in the back of a horde dynamically detect if they are clustered against other raiders attacking the Forge, allowing the entire depth of the pile to coordinate and deliver simultaneous structural damage.
*   **Future AI Expansion:** Plans are in place to augment the Simulated Annealing macro-pathfinding with **Decision Trees** for micro-tactical state management (e.g., dodging, breaking structures) and **Genetic Algorithms** to adapt wave generation and enemy stats based on the player's defense strategy.

---

## 🎮 Game Controls

| Key / Input | Action |
|:---:|---|
| **`W` / `S` / `A` / `D`** or **Arrows** | Smooth Player Movement |
| **`E`** | Proximity Interaction (Harvest iron, wood, and stone nodes) |
| **`B`** | Toggle Construction Mode (Ghost grid preview becomes active) |
| **`1`** | Select **Wall** structure |
| **`2`** | Select **Arrow Tower** structure |
| **`3`** | Select **Floor Spikes** structure |
| **`Left Mouse Click`** | Place selected defense structure (Requires sufficient materials) |

---

## 🛠️ Development Roadmap & Current Progress

Following the strict, step-by-step milestone hierarchy from `forge_and_survive_roadmap.html`:

### ✅ Phase 1: Project Setup
*   **Status:** **100% Completed**
*   *Milestones:* Tool installations, Git repository initialization, and Master scene directory structure set up in Godot.

### ✅ Phase 2: Core Gameplay
*   **Status:** **100% Completed**
*   *Milestones:* 32x32 pixel TileMap grid layout created, smooth 8-directional player movement with normal speed bounds, interactable resource gathering nodes, and dynamic resource state updates.

### ✅ Phase 3: Defense System
*   **Status:** **100% Completed**
*   *Milestones:* Snapped grid placement system, color-coded structure preview blocks, material cost calculations, and solid wall, arrow tower, and floor spike implementations.

### ✅ Phase 4: Enemy System
*   **Status:** **100% Completed**
*   *Milestones:* Spawn markers placed, wave scaling configurations, character bodies with anim controllers, and basic path tracking.

### ✅ Phase 5: Complete Game Loop
*   **Status:** **100% Completed**
*   *Milestones:* State-machine-based Day/Night phase shifting, darkness canvas overlays, HUD metrics (wave count, timer, resource bars), and Forge health/victory screens.

### ✅ Phase 6: AI Integration (Simulated Annealing)
*   **Status:** **100% Completed**
*   *Milestones:* Python SA algorithm prototyping, GDScript SA Pathfinder implementation, waypoint cost assessments (length vs. spike trap costs), and thermal cooling scheduler loops.

### 🔄 Phase 7: Polish & Balancing
*   **Status:** **In Progress**
*   *Milestones:* Adjusting damage values (e.g., doubling Floor Spikes damage to `20` per tick relative to Tower's `10`), tuning spawn waves, UI feedback optimization, and final build package generation.


> [!TIP]
> **Running the Project:** Simply download and open the repository folder in **Godot 4.6+**, set the renderer to **Compatibility**, and press **F5** to run the complete prototype instantly!
