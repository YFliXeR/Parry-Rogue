# WinScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Overlay shown when the player defeats a boss.
# Gold theme to contrast the red death screen.
# Builds its own UI in code — no .tscn needed.
#
# Call show_screen() when boss dies.
# Call hide_screen() when restarting.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Colors ────────────────────────────────────────────────
const COLOR_OVERLAY  := Color(0.04, 0.03, 0.01, 0.88)   # deep dark gold overlay
const COLOR_TITLE    := Color(1.00, 0.80, 0.10, 1.00)   # bright gold title
const COLOR_SUBTITLE := Color(0.70, 0.58, 0.28, 1.00)   # dim gold hint


# ── Node References ───────────────────────────────────────
var _overlay  : ColorRect
var _title    : Label
var _subtitle : Label


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	_build_ui()
	visible = false


# ── UI Construction ───────────────────────────────────────
func _build_ui() -> void:
	# Full-screen dark gold overlay
	_overlay          = ColorRect.new()
	_overlay.color    = COLOR_OVERLAY
	_overlay.size     = Vector2(1920.0, 1080.0)
	_overlay.position = Vector2.ZERO
	add_child(_overlay)

	# "BOSS DEFEATED" title
	_title                      = Label.new()
	_title.text                 = "BOSS DEFEATED"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size                 = Vector2(900.0, 120.0)
	_title.position             = Vector2(510.0, 400.0)
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	add_child(_title)

	# Continue hint
	_subtitle                      = Label.new()
	_subtitle.text                 = "PRESS  R  TO  CONTINUE"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.size                 = Vector2(900.0, 60.0)
	_subtitle.position             = Vector2(510.0, 530.0)
	_subtitle.add_theme_font_size_override("font_size", 28)
	_subtitle.add_theme_color_override("font_color", COLOR_SUBTITLE)
	add_child(_subtitle)


# ── Public API ────────────────────────────────────────────

## Fades the win screen in over the arena.
func show_screen() -> void:
	visible              = true
	_overlay.modulate.a  = 0.0
	_title.modulate.a    = 0.0
	_subtitle.modulate.a = 0.0

	# Staggered fade: overlay first, then title, then subtitle
	var tween := create_tween()
	tween.tween_property(_overlay,  "modulate:a", 1.0, 0.70)
	tween.parallel().tween_property(_title,    "modulate:a", 1.0, 0.50).set_delay(0.30)
	tween.parallel().tween_property(_subtitle, "modulate:a", 1.0, 0.50).set_delay(0.70)


## Hides the win screen instantly.
func hide_screen() -> void:
	visible = false