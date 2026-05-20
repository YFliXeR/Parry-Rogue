# BossHPBar.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Displays the boss's current HP as a horizontal bar.
# Call set_max_hp() before each fight to set the correct max.
# Call update_hp() whenever boss HP changes.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Layout ────────────────────────────────────────────────
const BAR_WIDTH  : float = 500.0
const BAR_HEIGHT : float = 16.0


# ── Colors ────────────────────────────────────────────────
const COLOR_BG   := Color(0.20, 0.05, 0.05, 1.0)
const COLOR_FILL := Color(0.85, 0.15, 0.15, 1.0)
const COLOR_TEXT := Color(0.80, 0.50, 0.50, 1.0)


# ── State ─────────────────────────────────────────────────
var _max_hp : int = GameConstants.BOSS_MAX_HP   # updated each fight via set_max_hp()


# ── Node References ───────────────────────────────────────
var _bg    : ColorRect
var _fill  : ColorRect
var _label : Label


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	_build_ui()


# ── UI Construction ───────────────────────────────────────
func _build_ui() -> void:
	_bg          = ColorRect.new()
	_bg.size     = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.position = Vector2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0)
	_bg.color    = COLOR_BG
	add_child(_bg)

	_fill          = ColorRect.new()
	_fill.size     = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill.position = Vector2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0)
	_fill.color    = COLOR_FILL
	add_child(_fill)

	_label                      = Label.new()
	_label.text                 = "BOSS"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size                 = Vector2(BAR_WIDTH, 28.0)
	_label.position             = Vector2(-BAR_WIDTH / 2.0, -BAR_HEIGHT / 2.0 - 28.0)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(_label)


# ── Public API ────────────────────────────────────────────

## Call before each fight to set the correct max HP for this enemy.
## Resets the bar to full width.
func set_max_hp(new_max: int) -> void:
	_max_hp      = new_max
	_fill.size.x = BAR_WIDTH   # reset bar to full visually


## Updates the fill bar to reflect current HP.
## Connected to boss.hp_changed signal in Arena.gd.
func update_hp(current: int) -> void:
	var ratio    := float(current) / float(_max_hp)
	_fill.size.x  = BAR_WIDTH * clampf(ratio, 0.0, 1.0)