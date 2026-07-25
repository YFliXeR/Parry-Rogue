# Enemy.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Base enemy behavior.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends CharacterBody2D
signal died


# ── Movement ─────────────────────────────────────────────
@export var move_speed := 120.0
@export var separation_force : float = 300.0


# ── Combat ───────────────────────────────────────────────
@export var max_hp : float = 3.0

@export var attack_damage : float = 1.0
@export var attack_range : float = 70.0

@export var attack_cooldown : float = 1.5
@export var windup_time : float = 0.4
@export var recovery_time : float = 0.5


# ── State ─────────────────────────────────────────────────
var _hp : float

var _can_attack : bool = true
var _is_attacking : bool = false


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

	if _is_attacking:
		move_and_slide()
		return

	var dir := _player.global_position - global_position
	var distance := dir.length()

	dir = dir.normalized()

	# Move toward player.
	if distance > attack_range:
		velocity = dir * move_speed

	# Stop and attack.
	else:
		velocity = Vector2.ZERO

		if _can_attack:
			_start_attack()

	_apply_separation()
	move_and_slide()


# ── Attacking ────────────────────────────────────────────

func _start_attack() -> void:
	_can_attack = false
	_is_attacking = true

	# Windup color
	$Visual.color = Color.ORANGE

	await get_tree().create_timer(windup_time).timeout

	if _player != null:
		var distance := global_position.distance_to(_player.global_position)

		if distance <= attack_range + 10.0:
			_player.take_damage(attack_damage, false)

	# Recovery color
	$Visual.color = Color.RED

	await get_tree().create_timer(recovery_time).timeout

	# Back to normal
	$Visual.color = Color.WHITE

	_is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	_can_attack = true


func _apply_separation() -> void:

	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:

		if enemy == self:
			continue

		var distance := global_position.distance_to(enemy.global_position)

		if distance < 40.0:

			var push_dir = global_position - enemy.global_position

			if push_dir != Vector2.ZERO:
				velocity += push_dir.normalized() * separation_force


# ── Damage / Death ───────────────────────────────────────

func take_damage(amount: float) -> void:

	_hp -= amount

	if _player != null:

		var knockback_dir := (global_position - _player.global_position).normalized()

		global_position += knockback_dir * 20.0

	# Hit flash
	$Visual.color = Color.WHITE

	await get_tree().create_timer(0.08).timeout

	if _is_attacking:
		$Visual.color = Color.RED
	else:
		$Visual.color = Color.WHITE

	print("Enemy HP:", _hp)

	if _hp <= 0.0:
		die()

func die() -> void:
	died.emit()
	queue_free()