# BuildManager.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — tracks which cards the player has collected
# this run and computes the resulting build stats.
#
# Other systems call the get_*() methods to read current stats.
# This is the single place where card effects are defined.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── State ─────────────────────────────────────────────────
## Card IDs collected so far this run. Can contain duplicates (stacking).
var active_cards : Array[String] = []
var gold         : int           = 0
var current_hp : float = float(GameConstants.PLAYER_MAX_HP)

# ── Card Management ───────────────────────────────────────

## Add a card to the current build by its ID.
func add_card(card_id: String) -> void:
	active_cards.append(card_id)
	print("Build updated — active cards: ", active_cards)


## Award gold to the player.
func add_gold(amount: int) -> void:
	gold += amount
	print("Gold +", amount, "  |  Total: ", gold)


## Spend gold. Returns true if successful, false if not enough.
func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


## Clear all cards. Call at the start of a new run.
func reset() -> void:
	active_cards.clear()
	gold = 0
	current_hp   = float(GameConstants.PLAYER_MAX_HP)


# ── Build Stats ───────────────────────────────────────────
# These are read by Arena, ParrySystem, and SkillCheckUI
# to apply card effects to gameplay.

## How many projectiles fire per perfect parry.
## split_shot: replaces 1 with 3.
func get_projectile_count() -> int:
	if "split_shot" in active_cards:
		return 3
	return 1


## Total damage multiplier applied to each counter projectile.
## power_strike: doubles damage. Stacks multiplicatively.
func get_damage_multiplier() -> float:
	var multiplier := 1.0
	for id in active_cards:
		if id == "power_strike":
			multiplier *= 2.0
	return multiplier


## Extra fraction added to the parry success zone end.
## wide_guard: +0.10 per copy (10% of window duration wider).
func get_parry_window_bonus() -> float:
	var bonus := 0.0
	for id in active_cards:
		if id == "wide_guard":
			bonus += 0.10
		elif id == "gods_eye":
			bonus += 0.25
	return bonus


## Chip damage multiplier. iron_skin reduces it by 50% per stack.
func get_chip_multiplier() -> float:
	var mult := 1.0
	for id in active_cards:
		if id == "iron_skin":
			mult *= 0.5
	return mult


## Bonus flat damage added to each counter from ember_core.
func get_ember_bonus() -> int:
	var bonus := 0
	for id in active_cards:
		if id == "ember_core":
			bonus += 20
	return bonus


## Extra seconds added to the total parry window duration from quick_reflex.
func get_window_duration_bonus() -> float:
	var bonus := 0.0
	for id in active_cards:
		if id == "quick_reflex":
			bonus += 0.20
	return bonus


## HP restored per counter projectile hit from vampiric_counter.
func get_vampiric_heal() -> float:
	var heal := 0.0
	for id in active_cards:
		if id == "vampiric_counter":
			heal += 0.25
	return heal


## Damage multiplier from echo_strike based on consecutive parry chain length.
## chain=1 → 1.0x (no bonus yet), chain=2 → 1.25x, chain=3 → 1.5x, capped at 3.0x
func get_echo_multiplier(chain: int) -> float:
	if "echo_strike" not in active_cards:
		return 1.0
	return minf(1.0 + float(chain - 1) * 0.25, 3.0)