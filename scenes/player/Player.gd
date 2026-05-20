# Player.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Manages player HP, damage handling, visual feedback,
# and parry input detection.
# Does NOT evaluate whether a parry succeeds — that is
# ParrySystem.gd's job. This script only reports what
# the player pressed and when.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Signals ──────────────────────────────────────────────
signal direction_pressed(dir: String)   # emitted when player presses a direction key
signal confirm_pressed                  # emitted when player presses Spacebar
signal player_died                      # emitted when HP reaches zero
signal hp_changed(current: float)   # fires whenever HP changes


# ── State ─────────────────────────────────────────────────
var current_hp    : float = GameConstants.PLAYER_MAX_HP
var is_dead       : bool  = false
var _accepting_input : bool = false   # only true during an active parry window


# ── Node References ───────────────────────────────────────
@onready var _visual : ColorRect = $Visual   # the blue rectangle


# ── Public Methods ────────────────────────────────────────

## Call this to open the parry input window.
## Player will now emit signals when keys are pressed.
func enable_parry_input() -> void:
	_accepting_input = true


## Call this to close the parry input window.
## Player will ignore all parry keys after this.
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
		actual *= BuildManager.get_chip_multiplier()   # iron_skin applies here

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


# ── Input ──────────────────────────────────────────────────
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
## Uses a Tween so it doesn't block anything else.
func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "color", Color.RED, 0.05)
	tween.tween_property(_visual, "color", Color(0.29, 0.62, 1.0), 0.15)
	# Returns to the original blue #4A9EFF after the flash


func _on_death() -> void:
	is_dead = true
	_visual.color = Color(0.3, 0.3, 0.3)   # grey out on death
	player_died.emit()


## Fully resets the player for a new run.
## Called by Arena when restarting.
func reset() -> void:
	current_hp = GameConstants.PLAYER_MAX_HP
	BuildManager.current_hp = current_hp   # sync to build manager
	is_dead    = false
	_visual.color = Color(0.29, 0.62, 1.0)   # back to original blue
	disable_parry_input()
	hp_changed.emit(current_hp)              # update HUD immediately


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	# Restore HP from BuildManager so damage carries between fights
	current_hp = BuildManager.current_hp