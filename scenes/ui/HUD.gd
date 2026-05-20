# HUD.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Draws the player's HP as a row of coloured segments.
# Segments are built dynamically from PLAYER_MAX_HP so
# changing that constant automatically resizes the display.
#
# Call update_hp(current) whenever HP changes.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Layout ────────────────────────────────────────────────
const SEGMENT_W   : float = 64.0   # width of each HP segment
const SEGMENT_H   : float = 18.0   # height of each HP segment
const SEGMENT_GAP : float = 8.0    # gap between segments


# ── Colors ────────────────────────────────────────────────
const COLOR_FULL    := Color(0.85, 0.20, 0.80, 1.00)  # bright magenta — full HP
const COLOR_PARTIAL := Color(0.45, 0.10, 0.42, 1.00)  # dim magenta — chip damage
const COLOR_EMPTY   := Color(0.12, 0.08, 0.14, 1.00)  # near-black — empty


# ── State ─────────────────────────────────────────────────
var _segments : Array = []   # holds the ColorRect nodes


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	_build_segments()


# ── Build ─────────────────────────────────────────────────
func _build_segments() -> void:
	var count       : int   = GameConstants.PLAYER_MAX_HP
	var total_width : float = count * SEGMENT_W + (count - 1) * SEGMENT_GAP
	var start_x     : float = -total_width / 2.0

	for i in count:
		var seg      := ColorRect.new()
		seg.size      = Vector2(SEGMENT_W, SEGMENT_H)
		seg.position  = Vector2(
			start_x + i * (SEGMENT_W + SEGMENT_GAP),
			-SEGMENT_H / 2.0
		)
		seg.color = COLOR_FULL
		add_child(seg)
		_segments.append(seg)


# ── Update ────────────────────────────────────────────────

## Called automatically when player HP changes.
## current_hp: the player's new HP value (can be fractional from chip damage)
func update_hp(current_hp: float) -> void:
	for i in _segments.size():
		var seg       : ColorRect = _segments[i]
		var threshold : float     = float(i + 1)   # this segment represents the (i+1)th HP point

		if current_hp >= threshold:
			# Full segment
			seg.color = COLOR_FULL
		elif current_hp > float(i):
			# Partially filled — chip damage landed here
			seg.color = COLOR_PARTIAL
		else:
			# Empty segment
			seg.color = COLOR_EMPTY