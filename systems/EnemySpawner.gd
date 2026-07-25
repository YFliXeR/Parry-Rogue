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
@export var melee_enemy_scene : PackedScene


# ── References ───────────────────────────────────────────
@onready var _player  : Node2D = $"../Player"
@onready var _enemies : Node2D = $"../Enemies"


# ── Spawning ─────────────────────────────────────────────

## Creates one enemy somewhere around the player.
func spawn_enemy() -> void:
	if melee_enemy_scene == null:
		return

	var enemy = melee_enemy_scene.instantiate()

	# Spawn enemies around the player at random angles.
	var angle    := randf() * TAU
	var distance := randf_range(500.0, 800.0)

	var spawn_pos := _player.global_position + Vector2(
		cos(angle),
		sin(angle)
	) * distance

	enemy.global_position = spawn_pos

	_enemies.add_child(enemy)

	var wave_manager = get_node("../../WaveManager")

	if wave_manager:
		enemy.died.connect(wave_manager.enemy_killed)


func spawn_wave(enemy_count: int) -> void:
	for i in enemy_count:
		spawn_enemy()