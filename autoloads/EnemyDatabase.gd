# EnemyDatabase.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — all enemy definitions for the game.
# Each enemy has its own HP, speed, color, and minigame type.
# Add new enemies here — nothing else needs to change.
#
# minigame types:  "skill_check" | "sequence"
# seq_length:      how many arrows in the sequence (0 if skill_check)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Regular Enemies ───────────────────────────────────────
const REGULAR_ENEMIES : Array = [
	{
		"id": "stone_golem", "name": "Stone Golem",
		"color": Color(0.55, 0.50, 0.42),
		"hp": 150, "interval": 2.4, "telegraph": 0.6,
		"minigame": "skill_check", "seq_length": 0,
	},
	{
		"id": "shadow_wraith", "name": "Shadow Wraith",
		"color": Color(0.35, 0.12, 0.52),
		"hp": 120, "interval": 1.9, "telegraph": 0.5,
		"minigame": "skill_check", "seq_length": 0,
	},
	{
		"id": "blood_knight", "name": "Blood Knight",
		"color": Color(0.75, 0.10, 0.10),
		"hp": 180, "interval": 2.2, "telegraph": 0.7,
		"minigame": "skill_check", "seq_length": 0,
	},
	{
		"id": "arcane_sentinel", "name": "Arcane Sentinel",
		"color": Color(0.35, 0.25, 0.82),
		"hp": 160, "interval": 2.8, "telegraph": 1.1,
		"minigame": "sequence", "seq_length": 3,
	},
	{
		"id": "void_crawler", "name": "Void Crawler",
		"color": Color(0.10, 0.28, 0.48),
		"hp": 140, "interval": 2.6, "telegraph": 0.9,
		"minigame": "sequence", "seq_length": 2,
	},
]


# ── Elite Enemies ─────────────────────────────────────────
const ELITE_ENEMIES : Array = [
	{
		"id": "iron_juggernaut", "name": "Iron Juggernaut",
		"color": Color(0.58, 0.52, 0.38),
		"hp": 220, "interval": 1.8, "telegraph": 0.5,
		"minigame": "skill_check", "seq_length": 0,
	},
	{
		"id": "phantom_mage", "name": "Phantom Mage",
		"color": Color(0.55, 0.18, 0.82),
		"hp": 200, "interval": 2.2, "telegraph": 1.1,
		"minigame": "sequence", "seq_length": 3,
	},
]


# ── Boss Enemies ──────────────────────────────────────────
const BOSS_ENEMIES : Array = [
	{
		"id": "ancient_warden", "name": "Ancient Warden",
		"color": Color(0.82, 0.14, 0.14),
		"hp": 350, "interval": 1.8, "telegraph": 0.6,
		"minigame": "skill_check", "seq_length": 0,
	},
	{
		"id": "void_sovereign", "name": "Void Sovereign",
		"color": Color(0.20, 0.08, 0.58),
		"hp": 320, "interval": 2.2, "telegraph": 1.2,
		"minigame": "sequence", "seq_length": 4,
	},
]


# ── Public API ────────────────────────────────────────────

## Returns a random enemy from the correct pool for the given node tier.
func get_random_enemy(tier: String) -> Dictionary:
	var pool : Array
	match tier:
		"elite": pool = ELITE_ENEMIES.duplicate()
		"boss":  pool = BOSS_ENEMIES.duplicate()
		_:       pool = REGULAR_ENEMIES.duplicate()
	pool.shuffle()
	return pool[0]