# SkillCheckUI.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# The DBD-style rotating skill check visual.
# Drawn entirely with Godot's _draw() API — no sprites needed.
#
# Call show_check("left") when a parry window opens.
# Call hide_check() when it closes.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Control


# ── Visual Constants ──────────────────────────────────────
const RADIUS       : float = 90.0    # ring size in pixels
const THICKNESS    : float = 14.0    # ring stroke width
const NEEDLE_WIDTH : float = 3.5     # sweeping needle width
const DOT_RADIUS   : float = 6.0     # dot at needle tip
const FONT_SIZE    : int   = 44      # direction arrow character size

const COLOR_RING   := Color(0.10, 0.08, 0.20, 0.90)  # dark purple ring
const COLOR_ZONE   := Color(0.20, 0.90, 0.40, 1.00)  # green success zone
const COLOR_NEEDLE := Color(1.00, 1.00, 1.00, 1.00)  # white needle
const COLOR_ARROW  := Color(1.00, 1.00, 1.00, 0.95)  # white direction arrow


# ── State ─────────────────────────────────────────────────
var _active     : bool   = false
var _progress   : float  = 0.0   # sweeps from 0.0 to 1.0 over window duration
var _attack_dir : String = ""


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	# Total duration includes quick_reflex — needle slows down with the card active
	var total_duration := GameConstants.PARRY_WINDOW_DURATION + BuildManager.get_window_duration_bonus()
	_progress += delta / total_duration
	_progress  = clampf(_progress, 0.0, 1.0)
	queue_redraw()


# ── Public API ────────────────────────────────────────────

## Show the skill check only if this is the right minigame type.
## Returns false and stays hidden if it's a different type.
func show_check(direction: String, minigame_type: String) -> void:
	if minigame_type != "skill_check":
		return   # a different minigame UI will handle this attack

	_attack_dir = direction
	_progress   = 0.0
	_active     = true
	visible     = true
	set_process(true)
	queue_redraw()


## Hide the skill check. Called when parry window closes.
func hide_check() -> void:
	_active  = false
	visible  = false
	set_process(false)


# ── Drawing ───────────────────────────────────────────────
func _draw() -> void:
	var center := size / 2.0
	if not _active:
		return

	# 1. Background ring — full dark circle ───────────────
	draw_arc(center, RADIUS, 0.0, TAU, 80, COLOR_RING, THICKNESS, true)

	# 2. Success zone — green arc ─────────────────────────
	# Zone sits between SUCCESS_START% and SUCCESS_END% of the full sweep.
	# Angles start at top (−PI/2) and increase clockwise.
	# Green zone grows wider when wide_guard cards are active
	var zone_s := -PI / 2.0 + GameConstants.PARRY_SUCCESS_START * TAU
	var zone_e := -PI / 2.0 + (GameConstants.PARRY_SUCCESS_END + BuildManager.get_parry_window_bonus()) * TAU	
	draw_arc(center, RADIUS, zone_s, zone_e, 32, COLOR_ZONE, THICKNESS + 4.0, true)

	# 3. Rotating needle ───────────────────────────────────
	var angle      := -PI / 2.0 + _progress * TAU
	var needle_tip := Vector2(cos(angle), sin(angle)) * RADIUS
	draw_line(center, center + needle_tip, COLOR_NEEDLE, NEEDLE_WIDTH, true)
	draw_circle(center + needle_tip, DOT_RADIUS, COLOR_NEEDLE)

	# 4. Direction arrow in center ─────────────────────────
	var arrow : String = "?"
	match _attack_dir:
		"left":  arrow = "←"
		"right": arrow = "→"
		"up":    arrow = "↑"
		"down":  arrow = "↓"

	var font      := ThemeDB.fallback_font
	var txt_size  := font.get_string_size(arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var txt_pos   := center + Vector2(-txt_size.x / 2.0, txt_size.y / 4.0)
	draw_string(font, txt_pos, arrow, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, COLOR_ARROW)


# ── Feel ──────────────────────────────────────────────────

## Called by Arena on a perfect parry.
## Briefly overbrighten the entire skill check visual.
func flash_perfect() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.2, 2.2, 2.2, 1.0), 0.04)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
