# DeathScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Overlay shown when the player dies.
# Builds its own UI in code — no .tscn needed.
# Fades in smoothly over the arena.
#
# Call show_screen() on death.
# Call hide_screen() on restart.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Colors ────────────────────────────────────────────────
const COLOR_OVERLAY  := Color(0.04, 0.02, 0.08, 0.88)   # deep dark purple overlay
const COLOR_TITLE    := Color(0.90, 0.15, 0.15, 1.00)   # red YOU DIED
const COLOR_SUBTITLE := Color(0.60, 0.40, 0.65, 1.00)   # dim magenta hint


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
	# Full-screen dark overlay
	_overlay          = ColorRect.new()
	_overlay.color    = COLOR_OVERLAY
	_overlay.size     = Vector2(1920.0, 1080.0)
	_overlay.position = Vector2.ZERO
	add_child(_overlay)

	# "YOU DIED" title
	_title                    = Label.new()
	_title.text               = "YOU DIED"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size               = Vector2(800.0, 120.0)
	_title.position           = Vector2(560.0, 400.0)
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	add_child(_title)

	# Restart hint
	_subtitle                    = Label.new()
	_subtitle.text               = "PRESS  R  TO  RESTART"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.size               = Vector2(800.0, 60.0)
	_subtitle.position           = Vector2(560.0, 530.0)
	_subtitle.add_theme_font_size_override("font_size", 28)
	_subtitle.add_theme_color_override("font_color", COLOR_SUBTITLE)
	add_child(_subtitle)


# ── Public API ────────────────────────────────────────────

## Fades the death screen in over the arena.
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


## Hides the death screen instantly.
func hide_screen() -> void:
	visible = false