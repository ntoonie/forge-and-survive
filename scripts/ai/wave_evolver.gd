extends Node
class_name WaveEvolver

# ── Chromosome: [fast_count, tank_count, normal_count, spawn_gate] ─
# spawn_gate: 0 = West, 1 = East, 2 = North, 3 = South
const POP_SIZE    : int   = 10
const GENES       : int   = 4
const MUTATE_RATE : float = 0.2
const MAX_EACH    : int   = 8
const MAX_GATE    : int   = 3   # gate values are clamped to [0, MAX_GATE]

var population : Array = []

# Filled by game_loop.gd after each wave
var last_forge_hp_remaining : float = 100.0
var last_wave_survived      : bool  = true


func _ready() -> void:
    _seed_population()


# ── Initial random population ─────────────────────────────────
func _seed_population() -> void:
    population.clear()
    for _i in range(POP_SIZE):
        population.append([
            randi_range(1, 4),   # fast raiders
            randi_range(0, 2),   # tank raiders
            randi_range(1, 5),   # normal raiders
            randi_range(0, 3),   # spawn gate (West/East/North/South)
        ])


# ── Fitness: reward waves that pressure but don't wipe player ─
func _fitness(chromosome: Array) -> float:
    # Target ~70% forge HP remaining — challenging but survivable
    var target_pressure : float = 0.30   # 30% damage dealt to forge is ideal
    var actual_pressure : float = 1.0 - (last_forge_hp_remaining / 100.0)
    var pressure_score  : float = 1.0 - abs(target_pressure - actual_pressure)

    # Penalise empty waves or degenerate chromosomes
    var total_enemies : int = chromosome[0] + chromosome[1] + chromosome[2]
    if total_enemies == 0:
        return 0.0

    # Small bonus for using non-default gates — encourages spawn-angle diversity
    var gate_bonus : float = 0.05 if chromosome[3] != 0 else 0.0

    return clamp(pressure_score + gate_bonus, 0.0, 1.0)


# ── Called by game_loop.gd at end of each night ───────────────
func evolve() -> Array:
    # Sort by fitness descending
    population.sort_custom(
        func(a, b): return _fitness(a) > _fitness(b)
    )

    var next_gen : Array = []

    # Elitism — keep top 2
    next_gen.append(population[0].duplicate())
    next_gen.append(population[1].duplicate())

    # Fill rest with crossover + mutation
    while next_gen.size() < POP_SIZE:
        var pa : Array = population[randi_range(0, 3)].duplicate()
        var pb : Array = population[randi_range(0, 3)].duplicate()
        var child : Array = _crossover(pa, pb)
        next_gen.append(_mutate_gene(child))

    population = next_gen

    # Return the fittest chromosome as next wave spec
    return population[0].duplicate()


func _crossover(a: Array, b: Array) -> Array:
    var split : int   = randi_range(1, GENES - 1)
    var child : Array = []
    for i in range(GENES):
        child.append(a[i] if i < split else b[i])
    return child


func _mutate_gene(chromosome: Array) -> Array:
    var c : Array = chromosome.duplicate()
    for i in range(GENES):
        if randf() < MUTATE_RATE:
            var max_val : int = MAX_GATE if i == 3 else MAX_EACH
            c[i] = clamp(c[i] + randi_range(-1, 1), 0, max_val)
    return c