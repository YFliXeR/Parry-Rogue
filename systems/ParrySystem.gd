# ParrySystem.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# The core of the game. Receives an incoming boss attack,
# opens a parry window, listens to player input, then
# evaluates and emits the outcome.
#
# Flow:
#   Arena calls begin_attack(direction)
#     → window opens, player input enabled
#     → player presses direction key  → _on_direction_pressed()
#     → player presses spacebar       → _on_confirm_pressed()
#     → outcome evaluated             → signal emitted
#   OR window timer expires with no confirm → parry_failed
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Signals ───────────────────────────────────────────────
signal parry_perfect(direction: String)  # right direction + inside timing window
signal parry_chip(direction: String)     # right direction + outside timing window
signal parry_failed                      # wrong direction OR window expired
signal window_opened(direction: String, minigame_type: String) # tells UI to show the skill check visual
signal window_closed                     # tells UI to hide the skill check visual
signal sequence_input_received(dir: String, is_correct: bool)


# ── State ─────────────────────────────────────────────────
var _active       : bool   = false  # is a parry window currently open?
var _attack_dir   : String = ""     # direction of the incoming attack
var _pressed_dir  : String = ""     # last direction key the player pressed
var _window_timer : float  = 0.0   # time elapsed since window opened
var _confirmed    : bool   = false  # did player press spacebar yet?
var _minigame_type    : String         = "skill_check"
var _attack_sequence  : Array[String]  = []
var _input_sequence   : Array[String]  = []

# ── References ────────────────────────────────────────────
var _player : Node2D = null  # assigned by Arena.gd via setup()


# ── Setup ─────────────────────────────────────────────────

## Called once by Arena.gd after the scene loads.
## Connects player input signals so we can listen to them.
func setup(player: Node2D) -> void:
	_player = player
	_player.direction_pressed.connect(_on_direction_pressed)
	_player.confirm_pressed.connect(_on_confirm_pressed)


# ── Public API ────────────────────────────────────────────

## Call this when the boss fires an attack.
## attack_direction: "left" | "right" | "up" | "down"
## minigame_type: "skill_check" | "sequence" | "hold_zone" etc.
func begin_attack(attack_direction: String, minigame_type: String = "skill_check") -> void:
	if _active:
		return

	_attack_dir    = attack_direction
	_pressed_dir   = ""
	_confirmed     = false
	_window_timer  = 0.0
	_active        = true
	_minigame_type = minigame_type  # ← add this line

	_player.enable_parry_input()
	window_opened.emit(attack_direction, minigame_type)


## Starts a sequence parry window. The player must press the
## directions in the correct order before the timer expires.
func begin_sequence_attack(sequence: Array) -> void:
	if _active:
		return

	_attack_sequence.clear()
	for s in sequence:
		_attack_sequence.append(s as String)
	_input_sequence.clear()
	_window_timer    = 0.0
	_confirmed       = false
	_active          = true
	_minigame_type   = "sequence"

	_player.enable_parry_input()
	window_opened.emit("", "sequence")


## Cancels any active parry window and resets all state.
## Called by Arena when restarting.
func reset() -> void:
	_active          = false
	_window_timer    = 0.0
	_confirmed       = false
	_pressed_dir     = ""
	_attack_dir      = ""
	_attack_sequence.clear()
	_input_sequence.clear()
	_minigame_type   = "skill_check"
	_player.disable_parry_input()
	window_closed.emit()


# ── Process ───────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _active:
		return

	_window_timer += delta

	var total_duration := GameConstants.PARRY_WINDOW_DURATION + BuildManager.get_window_duration_bonus()

	if _window_timer >= total_duration:
		if _minigame_type == "sequence":
			_resolve_sequence(false)   # ran out of time on sequence = chip
		else:
			_resolve(false, false)     # ran out of time on skill check = full hit


# ── Input Callbacks ───────────────────────────────────────

# Receives direction from Player.gd when a direction key is pressed
func _on_direction_pressed(dir: String) -> void:
	if not _active:
		return

	if _minigame_type == "sequence":
		# Check if this direction matches the next expected in the sequence
		var expected_index := _input_sequence.size()
		if expected_index >= _attack_sequence.size():
			return   # sequence already complete

		var expected   : String = _attack_sequence[expected_index]
		var is_correct : bool   = (dir == expected)
		_input_sequence.append(dir)
		sequence_input_received.emit(dir, is_correct)

		if not is_correct:
			# Wrong direction — chip block and end window
			_resolve_sequence(false)
		elif _input_sequence.size() >= _attack_sequence.size():
			# Completed the full sequence correctly — perfect!
			_resolve_sequence(true)
	else:
		_pressed_dir = dir


# Receives confirm from Player.gd when spacebar is pressed
func _on_confirm_pressed() -> void:
	if not _active or _confirmed:
		return
	_confirmed = true

	var direction_correct : bool = (_pressed_dir == _attack_dir)

	# Total duration includes quick_reflex bonus
	var total_duration : float = GameConstants.PARRY_WINDOW_DURATION + BuildManager.get_window_duration_bonus()
	var zone_start     : float = GameConstants.PARRY_SUCCESS_START * total_duration
	var bonus          : float = BuildManager.get_parry_window_bonus() * total_duration
	var zone_end       : float = GameConstants.PARRY_SUCCESS_END * total_duration + bonus
	var in_window      : bool  = (_window_timer >= zone_start and _window_timer <= zone_end)

	_resolve(direction_correct, in_window)


# ── Private ───────────────────────────────────────────────

# Closes the window and emits the correct outcome signal
func _resolve(direction_correct: bool, in_window: bool) -> void:
	_active = false
	_player.disable_parry_input()
	window_closed.emit()

	if direction_correct and in_window:
		parry_perfect.emit(_attack_dir)
	elif direction_correct and not in_window:
		parry_chip.emit(_attack_dir)
	else:
		parry_failed.emit()


## Resolves a sequence parry attempt.
## success = true → perfect parry  |  false → chip block
func _resolve_sequence(success: bool) -> void:
	_active = false
	_player.disable_parry_input()
	window_closed.emit()

	if success:
		parry_perfect.emit("sequence")
	else:
		parry_chip.emit("sequence")   # wrong/incomplete = chip (gentler for sequences)