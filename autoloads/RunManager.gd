# RunManager.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — tracks the player's position and chosen path
# through the run map. Provides node state queries to the
# MapScreen and fight config to the Arena.
#
# Map structure: rows of nodes, player picks one per row.
# Connection rule: can reach ±1 column in the next row.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Map Layout ────────────────────────────────────────────
# Each inner array is one row of node types.
# Node types: "fight" | "elite" | "shop" | "event" | "boss"
# Last row must always be ["boss"].
const MAP_LAYOUT : Array = [
	["fight", "event", "fight"],   # Row 0 — entry encounters
	["shop",  "fight", "elite"],   # Row 1 — mid encounters
	["elite", "fight", "fight"],   # Row 2 — tough encounters
	["boss"],                       # Row 3 — final boss (always)
]


# ── State ─────────────────────────────────────────────────
var current_row : int          = 0    # which row the player is choosing from
var path        : Array[int]   = []   # column chosen at each completed row
var node_type   : String       = "fight"  # type of the selected node for current fight
var current_enemy : Dictionary = {}   # enemy selected for the current fight


# ── Node Queries ──────────────────────────────────────────
# These are called by MapScreen to determine how to draw each node.

## Returns the type string of a node at (row, col).
func get_node_type(row: int, col: int) -> String:
	if row >= MAP_LAYOUT.size() or col >= MAP_LAYOUT[row].size():
		return "fight"
	return MAP_LAYOUT[row][col]


## Returns the state of a node: "available" | "completed" | "locked"
func get_node_state(row: int, col: int) -> String:
	if row < current_row:
		# Past row — show as completed only if it was on the chosen path
		if row >= 0 and row < path.size() and path[row] == col:
			return "completed"
		return "locked"

	if row > current_row:
		return "locked"

	# This is the current row — check if node is reachable
	if current_row == 0:
		return "available"   # first row: all nodes are open

	# Check connection from the previous row's chosen column
	var prev_col : int = 0

	if current_row - 1 >= 0 and current_row - 1 < path.size():
		prev_col = path[current_row - 1]
	var next_row_len : int  = MAP_LAYOUT[row].size()

	# Boss row (single node) is always reachable
	if next_row_len == 1:
		return "available"

	if abs(prev_col - col) <= 1:
		return "available"

	return "locked"


# ── Actions ───────────────────────────────────────────────

## Called by MapScreen when the player clicks a node.
## Stores the chosen column and node type for Arena to read.
func select_node(row: int, col: int) -> void:
	node_type = get_node_type(row, col)
	path.append(col)

	# Pick a random enemy for combat nodes
	match node_type:
		"fight", "elite", "boss":
			current_enemy = EnemyDatabase.get_random_enemy(node_type)
		_:
			current_enemy = {}   # no enemy for shop/event nodes

## Advances to the next row after a fight is complete and card is picked.
## Called by Arena._on_card_selected().
func advance_row() -> void:
	current_row += 1


## True when all rows (including boss) are complete — run is over.
func is_run_complete() -> bool:
	return current_row >= MAP_LAYOUT.size()


## True when the current row is the boss row.
func is_boss_row() -> bool:
	return current_row == MAP_LAYOUT.size() - 1


## 1-indexed row number for display labels.
func get_fight_number() -> int:
	return current_row + 1


# ── Fight Config ──────────────────────────────────────────
# Arena reads these to configure the boss HP and speed.

func get_current_hp() -> int:
	match node_type:
		"elite": return GameConstants.ELITE_FIGHT_HP
		"boss":  return GameConstants.BOSS_FIGHT_HP
		_:       return GameConstants.REGULAR_FIGHT_HP


func get_current_interval() -> float:
	match node_type:
		"elite": return GameConstants.ELITE_FIGHT_INTERVAL
		"boss":  return GameConstants.BOSS_FIGHT_INTERVAL
		_:       return GameConstants.REGULAR_FIGHT_INTERVAL


# ── Reset ─────────────────────────────────────────────────

## Full reset — called on death or after a completed run.
func reset() -> void:
	current_row   = 0
	path.clear()
	node_type     = "fight"
	current_enemy = {}
