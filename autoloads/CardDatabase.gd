# CardDatabase.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — single source of truth for every card in the game.
# To add a new card: add one Dictionary entry to ALL_CARDS.
# Nothing else needs to change anywhere.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Card Pool ─────────────────────────────────────────────
# Each card needs: id, name, description, rarity, type
# rarity: "common" | "rare" | "legendary"
# type:   "shape"  | "stat" | "element" | "chain"

const ALL_CARDS : Array = [

	# ── COMMON ────────────────────────────────────────────

	{
		"id":          "split_shot",
		"name":        "Split Shot",
		"description": "Your counter fires 3 projectiles in a spread instead of 1.",
		"rarity":      "common",
		"type":        "shape",
	},
	{
		"id":          "wide_guard",
		"name":        "Wide Guard",
		"description": "The perfect parry timing window is 30% wider. Stacks.",
		"rarity":      "common",
		"type":        "stat",
	},
	{
		"id":          "iron_skin",
		"name":        "Iron Skin",
		"description": "Chip blocks deal 50% less damage. Surviving mistakes costs less.",
		"rarity":      "common",
		"type":        "stat",
	},
	{
		"id":          "quick_reflex",
		"name":        "Quick Reflex",
		"description": "The parry window lasts 0.2 seconds longer. More time to react.",
		"rarity":      "common",
		"type":        "stat",
	},
	{
		"id":          "ember_core",
		"name":        "Ember Core",
		"description": "Each counter projectile deals +20 bonus burn damage. Stacks.",
		"rarity":      "common",
		"type":        "element",
	},


	# ── RARE ──────────────────────────────────────────────

	{
		"id":          "power_strike",
		"name":        "Power Strike",
		"description": "Your counter deals double damage. Stacks multiplicatively.",
		"rarity":      "rare",
		"type":        "stat",
	},
	{
		"id":          "vampiric_counter",
		"name":        "Vampiric Counter",
		"description": "Each counter projectile hit restores 0.25 HP. Stacks.",
		"rarity":      "rare",
		"type":        "chain",
	},
	{
		"id":          "echo_strike",
		"name":        "Echo Strike",
		"description": "Consecutive perfect parries deal +25% more damage each. Max 3x. Resets on any miss.",
		"rarity":      "rare",
		"type":        "chain",
	},
	{
		"id":          "arcane_surge",
		"name":        "Arcane Surge",
		"description": "Your first perfect parry of each fight deals 3x damage. One chance per fight.",
		"rarity":      "rare",
		"type":        "chain",
	},
	{
		"id":          "frost_edge",
		"name":        "Frost Edge",
		"description": "Each counter hit delays the boss next attack by 0.8 seconds.",
		"rarity":      "rare",
		"type":        "element",
	},


	# ── LEGENDARY ─────────────────────────────────────────

	{
		"id":          "gods_eye",
		"name":        "God's Eye",
		"description": "The perfect parry window is massively wider (+50%). Stacks with Wide Guard.",
		"rarity":      "legendary",
		"type":        "stat",
	},
	{
		"id":          "mirror_defense",
		"name":        "Mirror Defense",
		"description": "Chip blocks also fire a counter at 40% damage. Turn your mistakes into attacks.",
		"rarity":      "legendary",
		"type":        "chain",
	},

]


# ── Public API ────────────────────────────────────────────

## Returns 'count' random cards from the pool.
## No duplicates within the same draft offer.
func get_random_cards(count: int) -> Array:
	var pool := ALL_CARDS.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))