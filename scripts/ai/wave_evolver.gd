extends Node
class_name WaveEvolver

# ── Chromosome layout ──────────────────────────────────────────
# [0] fast_count   — enemy_2 (Raider) count
# [1] tank_count   — enemy_3 (Boss)   count  (only meaningful on wave ≥ 5)
# [2] normal_count — enemy_1 (Normal) count
# [3] spawn_gate   — 0 = West | 1 = East | 2 = North | 3 = South

const POP_SIZE    : int   = 10
const GENES       : int   = 4
const MUTATE_RATE : float = 0.2
const MAX_EACH    : int   = 8
const MAX_GATE    : int   = 3

var population : Array = []

# ── Feedback state — filled by game_loop.gd after each wave ───
# Expressed as a 0–100 percentage of the Forge's max HP.
var last_forge_hp_pct  : float = 100.0   # 100 = undamaged, 0 = destroyed
var last_wave_survived : bool  = true


# ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_seed_population()


# ── Initial random population ─────────────────────────────────
func _seed_population() -> void:
	population.clear()
	for _i in range(POP_SIZE):
		population.append([
			randi_range(1, 4),   # fast raiders
			randi_range(0, 2),   # tank bosses
			randi_range(1, 5),   # normal enemies
			randi_range(0, 3),   # spawn gate
		])


# ── Fitness ────────────────────────────────────────────────────
# Rewards waves that deal ~30% Forge damage — challenging but beatable.
# Returns 0–1 (higher = fitter chromosome).
func _fitness(chromosome: Array) -> float:
	var total_enemies : int = chromosome[0] + chromosome[1] + chromosome[2]
	if total_enemies == 0:
		return 0.0

	# actual_damage_pct ∈ [0,1]: fraction of Forge HP removed last wave
	var actual_damage_pct : float = 1.0 - clamp(last_forge_hp_pct / 100.0, 0.0, 1.0)

	# Target: deal 30% damage.  Score = 1 at bull's-eye, falls off toward 0.
	var target : float         = 0.30
	var pressure_score : float = 1.0 - absf(target - actual_damage_pct)

	# Small bonus for non-West gates (encourages spawn diversity)
	var gate_bonus : float = 0.05 if chromosome[3] != 0 else 0.0

	return clamp(pressure_score + gate_bonus, 0.0, 1.0)


# ── evolve() — call at end of each night phase ─────────────────
# Returns the fittest chromosome from the new generation.
func evolve() -> Array:
	population.sort_custom(
		func(a, b): return _fitness(a) > _fitness(b)
	)

	var next_gen : Array = []

	# Elitism — carry forward the two best
	next_gen.append(population[0].duplicate())
	next_gen.append(population[1].duplicate())

	# Fill remainder with crossover + mutation from the top-4 parents
	while next_gen.size() < POP_SIZE:
		var pa    : Array = population[randi_range(0, 3)].duplicate()
		var pb    : Array = population[randi_range(0, 3)].duplicate()
		var child : Array = _crossover(pa, pb)
		next_gen.append(_mutate_gene(child))

	population = next_gen

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


# ── Convenience: total enemy count of fittest chromosome ──────
func best_total_enemies() -> int:
	if population.is_empty():
		return 0
	var best : Array = population[0]
	return best[0] + best[1] + best[2]
