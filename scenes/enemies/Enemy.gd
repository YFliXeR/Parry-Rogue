# Enemy.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Base enemy behavior.
#
# Responsibilities:
# - Find the player
# - Move toward the player
# - Deal contact damage
# - Receive damage
# - Die and clean itself up
#
# This is the foundation for:
# - melee enemies
# - ranged enemies
# - elites
# - bosses
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends CharacterBody2D


# ── Movement ─────────────────────────────────────────────
@export var move_speed : float = 140.0


# ── Combat ───────────────────────────────────────────────
@export var max_hp : float = 3.0
@export var contact_damage : float = 1.0
@export var contact_cooldown : float = 1.0


# ── State ─────────────────────────────────────────────────
var _hp : float
var _can_damage : bool = true


# ── References ───────────────────────────────────────────
var _player : Node2D


# ── Lifecycle ────────────────────────────────────────────
func _ready() -> void:
	_hp = max_hp

	# Find player through global group.
	_player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	# Move toward player.
	var dir := (_player.global_position - global_position).normalized()

	velocity = dir * move_speed
	move_and_slide()

	_attempt_contact_damage()


# ── Damage / Death ───────────────────────────────────────

## Called when something damages this enemy.
func take_damage(amount: float) -> void:
	_hp -= amount

	print("Enemy HP:", _hp)

	if _hp <= 0.0:
		die()


## Removes the enemy from the game.
func die() -> void:
	queue_free()


# ── Contact Damage ───────────────────────────────────────

## Damages player while touching them.
func _attempt_contact_damage() -> void:
	if not _can_damage:
		return

	if global_position.distance_to(_player.global_position) < 70.0:
		_can_damage = false

		_player.take_damage(contact_damage, false)

		var timer := get_tree().create_timer(contact_cooldown)
		timer.timeout.connect(_reset_contact_damage)


## Re-enables damage after cooldown.
func _reset_contact_damage() -> void:
	_can_damage = true