# Player.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Manages player HP, damage handling, visual feedback,
# WASD movement, and parry input detection.
#
# Movement is processed every frame via _process().
# Parry input is gated by _accepting_input — only active
# when ParrySystem opens a window.
#
# Does NOT evaluate whether a parry succeeds — that is
# ParrySystem.gd's job. This script only reports what
# the player pressed and when.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Signals ───────────────────────────────────────────────
signal direction_pressed(dir: String)   # emitted when player presses a direction key during parry window
signal confirm_pressed                  # emitted when player presses Spacebar during parry window
signal player_died                      # emitted when HP reaches zero
signal hp_changed(current: float)       # fires whenever HP changes


# ── State ─────────────────────────────────────────────────
var current_hp       : float = GameConstants.PLAYER_MAX_HP
var is_dead          : bool  = false
var _accepting_input : bool  = false   # true only during an active parry window


# ── Combat ───────────────────────────────────────────────
@export var attack_damage : float = 1.0
@export var attack_range  : float = 140.0

@export var arena_min := Vector2(-2000, -2000)
@export var arena_max := Vector2(2000, 2000)

# ── Node References ───────────────────────────────────────
@onready var _visual : ColorRect = $Visual   # the blue rectangle


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	# Restore HP from BuildManager so damage carries between fights
	current_hp = BuildManager.current_hp
	_visual.position = -_visual.size / 2.0

func _process(delta: float) -> void:
	if is_dead:
		return
	_handle_movement(delta)
	_handle_attack()


# ── Movement ──────────────────────────────────────────────

## Reads WASD each frame and moves the player, clamped to arena bounds.
## Accounts for visual size so the rect edges, not the origin, stop at the boundary.
func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0

	if dir.length_squared() > 0.0:
		dir = dir.normalized()

	global_position += dir * GameConstants.PLAYER_MOVE_SPEED * delta
	global_position.x = clamp(global_position.x, arena_min.x, arena_max.x)
	global_position.y = clamp(global_position.y, arena_min.y, arena_max.y)


# ── Combat ───────────────────────────────────────────────

## TEMP debug attack.
## Damages all enemies near the player when pressing Space.
func _handle_attack() -> void:
	if not Input.is_action_just_pressed("ui_accept"):
		return

	# Find every enemy currently in the scene.
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if enemy == null:
			continue

		# Check distance from player.
		var dist := global_position.distance_to(enemy.global_position)

		if dist <= attack_range:
			enemy.take_damage(attack_damage)


# ── Public Methods ────────────────────────────────────────

## Opens the parry input window. Player will now emit signals when keys are pressed.
func enable_parry_input() -> void:
	_accepting_input = true


## Closes the parry input window. Player ignores all parry keys after this.
func disable_parry_input() -> void:
	_accepting_input = false


## Apply damage to the player.
## is_chip: true if this is a chip block (iron_skin reduces it)
## is_chip: false for full hits (iron_skin does NOT protect)
func take_damage(amount: float, is_chip: bool = false) -> void:
	if is_dead:
		return

	var actual := amount
	if is_chip:
		actual *= BuildManager.get_chip_multiplier()

	current_hp -= actual
	current_hp  = maxf(current_hp, 0.0)
	BuildManager.current_hp = current_hp
	hp_changed.emit(current_hp)
	_flash_hit()

	if current_hp <= 0.0:
		_on_death()


## Returns current HP as a 0.0–1.0 ratio (useful for HP bar display)
func get_hp_ratio() -> float:
	return current_hp / float(GameConstants.PLAYER_MAX_HP)


# ── Parry Input ───────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_input or is_dead:
		return

	# Direction keys — report which direction was pressed
	if event.is_action_pressed("parry_left"):
		direction_pressed.emit("left")
	elif event.is_action_pressed("parry_right"):
		direction_pressed.emit("right")
	elif event.is_action_pressed("parry_up"):
		direction_pressed.emit("up")
	elif event.is_action_pressed("parry_down"):
		direction_pressed.emit("down")

	# Confirm key — report that spacebar was pressed
	if event.is_action_pressed("parry_confirm"):
		confirm_pressed.emit()


# ── Private Methods ───────────────────────────────────────

## Flash the player red briefly to signal a hit.
func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "color", Color.RED,              0.05)
	tween.tween_property(_visual, "color", Color(0.29, 0.62, 1.0), 0.15)


func _on_death() -> void:
	is_dead = true
	_visual.color = Color(0.3, 0.3, 0.3)
	player_died.emit()


## Fully resets the player for a new run.
func reset() -> void:
	current_hp = GameConstants.PLAYER_MAX_HP
	BuildManager.current_hp = current_hp
	is_dead    = false
	_visual.color = Color(0.29, 0.62, 1.0)
	disable_parry_input()
	hp_changed.emit(current_hp)
