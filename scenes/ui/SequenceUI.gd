# SequenceUI.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Visual display for the sequence parry minigame.
# Shows a row of direction arrows the player must press in order.
# Arrows light up green as correct inputs are made.
#
# Usage:
#   show_sequence(["left", "up", "right"])
#   register_input(dir, is_correct)   ← called by ParrySystem signal
#   hide_sequence()
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Visual Constants ──────────────────────────────────────
const ARROW_RADIUS : float = 38.0    # circle radius per arrow
const ARROW_GAP    : float = 20.0    # gap between circles
const FONT_SIZE    : int   = 28      # arrow character size

# Arrow characters for each direction
const ARROW_CHARS := {
	"left":  "←",
	"right": "→",
	"up":    "↑",
	"down":  "↓",
}

# Colors
const COLOR_PENDING  := Color(0.18, 0.14, 0.30, 0.90)   # not yet pressed
const COLOR_CORRECT  := Color(0.20, 0.85, 0.40, 1.00)   # correct input
const COLOR_WRONG    := Color(0.85, 0.20, 0.20, 1.00)   # wrong input
const COLOR_BORDER   := Color(0.55, 0.40, 0.80, 0.90)   # pending border
const COLOR_TEXT     := Color(0.85, 0.80, 0.95, 1.00)   # pending arrow text

# Timer bar constants
const BAR_W : float = 200.0
const BAR_H : float = 8.0


# ── State ─────────────────────────────────────────────────
var _sequence     : Array[String] = []     # the required sequence
var _inputs       : Array         = []     # what player pressed: {correct: bool}
var _progress     : float         = 0.0   # 0→1 over window duration (for timer bar)


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_progress += delta / GameConstants.PARRY_WINDOW_DURATION
	_progress  = clampf(_progress, 0.0, 1.0)
	queue_redraw()


# ── Public API ────────────────────────────────────────────

## Show the sequence arrows. Call when the boss fires a sequence attack.
func show_sequence(sequence: Array) -> void:
	_sequence.clear()
	for s in sequence:
		_sequence.append(s as String)
	_inputs.clear()
	_progress = 0.0
	visible   = true
	set_process(true)
	queue_redraw()


## Called by ParrySystem when the player presses a direction during sequence mode.
func register_input(dir: String, is_correct: bool) -> void:
	_inputs.append({ "dir": dir, "correct": is_correct })
	queue_redraw()


## Hide the sequence UI.
func hide_sequence() -> void:
	visible = false
	set_process(false)


# ── Drawing ───────────────────────────────────────────────
func _draw() -> void:
	if not visible or _sequence.is_empty():
		return

	var font      := ThemeDB.fallback_font
	var count     := _sequence.size()
	var slot_w    := ARROW_RADIUS * 2.0 + ARROW_GAP
	var total_w   := count * slot_w - ARROW_GAP
	var start_x   := -total_w / 2.0 + ARROW_RADIUS

	# Draw each arrow slot
	for i in count:
		var cx := start_x + i * slot_w
		var pos := Vector2(cx, 0.0)

		var bg_color   : Color
		var txt_color  : Color
		var bdr_color  : Color

		if i < _inputs.size():
			# This slot has been pressed
			var correct : bool = _inputs[i].get("correct", false)
			bg_color  = COLOR_CORRECT if correct else COLOR_WRONG
			txt_color = Color.WHITE
			bdr_color = bg_color
		else:
			# Waiting for input
			bg_color  = COLOR_PENDING
			txt_color = COLOR_TEXT
			bdr_color = COLOR_BORDER

		draw_circle(pos, ARROW_RADIUS, bg_color)
		draw_arc(pos, ARROW_RADIUS, 0.0, TAU, 40, bdr_color, 2.5, true)

		# Direction arrow character
		var arrow : String = ARROW_CHARS.get(_sequence[i], "?")
		var ts    := font.get_string_size(arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		draw_string(font, pos + Vector2(-ts.x / 2.0, ts.y / 4.0),
					arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, txt_color)

	# Timer bar below the arrows
	var bar_x := -BAR_W / 2.0
	var bar_y := ARROW_RADIUS + 14.0
	draw_rect(Rect2(bar_x, bar_y, BAR_W, BAR_H), Color(0.12, 0.10, 0.18))
	var remaining := (1.0 - _progress) * BAR_W
	if remaining > 0.0:
		draw_rect(Rect2(bar_x, bar_y, remaining, BAR_H), Color(0.55, 0.40, 0.80, 0.8))