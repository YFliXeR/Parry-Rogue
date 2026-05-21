# EnemySpawner.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Handles spawning enemies into the arena.
#
# Current responsibilities:
# - Spawn enemies
# - Place enemies around the player
#
# Future responsibilities:
# - Wave spawning
# - Elite spawning
# - Spawn limits
# - Difficulty scaling
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Enemy Scene ──────────────────────────────────────────
@export var enemy_scene : PackedScene


# ── References ───────────────────────────────────────────
@onready var _player  : Node2D = $"../Player"
@onready var _enemies : Node2D = $"../Enemies"


# ── Lifecycle ────────────────────────────────────────────
func _ready() -> void:
	# TEMP: Spawn a few enemies immediately on arena start.
	# Later this will be handled by WaveManager.
	for i in 3:
		_spawn_enemy()


# ── Spawning ─────────────────────────────────────────────

## Creates one enemy somewhere around the player.
func _spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()

	# Spawn enemies around the player at random angles.
	var angle    := randf() * TAU
	var distance := randf_range(500.0, 800.0)

	var spawn_pos := _player.global_position + Vector2(
		cos(angle),
		sin(angle)
	) * distance

	enemy.global_position = spawn_pos

	_enemies.add_child(enemy)