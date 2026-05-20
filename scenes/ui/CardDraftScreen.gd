# CardDraftScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shows 3 clickable upgrade cards after a boss is defeated.
# Builds its layout once in _ready() and updates card content
# each time show_draft() is called.
#
# Emits card_selected(card_id) when the player clicks a card.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Signals ───────────────────────────────────────────────
signal card_selected(card_id: String)


# ── Layout Constants ──────────────────────────────────────
const CARD_COUNT  : int   = 3
const CARD_W      : float = 280.0
const CARD_H      : float = 380.0
const CARD_GAP    : float = 80.0


# ── Colors ────────────────────────────────────────────────
const COLOR_OVERLAY  := Color(0.03, 0.02, 0.06, 0.92)
const COLOR_CARD_BG  := Color(0.08, 0.06, 0.12, 1.00)
const COLOR_CARD_HOV := Color(0.14, 0.10, 0.20, 1.00)   # hover highlight
const COLOR_TITLE    := Color(0.80, 0.65, 0.90, 1.00)
const COLOR_DESC     := Color(0.80, 0.75, 0.85, 1.00)


# ── Runtime State ─────────────────────────────────────────
var _cards_data  : Array     = []          # the 3 cards currently on offer
var _card_rects  : Array     = []          # Rect2 for click detection per card
var _card_bgs    : Array     = []          # background ColorRect refs for hover


# ── Per-card label references (updated each draft) ────────
var _name_labels : Array = []
var _type_labels : Array = []
var _rar_labels  : Array = []
var _rar_bars    : Array = []
var _desc_labels : Array = []


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	visible = false
	_build_layout()


# ── Layout (built once) ───────────────────────────────────
func _build_layout() -> void:
	# Dark overlay
	var overlay          := ColorRect.new()
	overlay.color         = COLOR_OVERLAY
	overlay.size          = Vector2(1920.0, 1080.0)
	overlay.position      = Vector2.ZERO
	add_child(overlay)

	# "CHOOSE AN UPGRADE" title
	var title                      := Label.new()
	title.text                      = "CHOOSE AN UPGRADE"
	title.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	title.size                      = Vector2(900.0, 60.0)
	title.position                  = Vector2(510.0, 230.0)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	add_child(title)

	# Build the 3 card slots
	var total_w := CARD_COUNT * CARD_W + (CARD_COUNT - 1) * CARD_GAP
	var start_x := (1920.0 - total_w) / 2.0
	var card_y  := (1080.0 - CARD_H) / 2.0 + 20.0

	for i in CARD_COUNT:
		var cx := start_x + i * (CARD_W + CARD_GAP)
		_card_rects.append(Rect2(cx, card_y, CARD_W, CARD_H))
		_build_card_slot(i, Vector2(cx, card_y))


func _build_card_slot(_index: int, pos: Vector2) -> void:
	# Card background — stored for hover effect
	var bg          := ColorRect.new()
	bg.size          = Vector2(CARD_W, CARD_H)
	bg.position      = pos
	bg.color         = COLOR_CARD_BG
	add_child(bg)
	_card_bgs.append(bg)

	# Rarity colour bar along the top edge
	var rar_bar      := ColorRect.new()
	rar_bar.size      = Vector2(CARD_W, 6.0)
	rar_bar.position  = pos
	add_child(rar_bar)
	_rar_bars.append(rar_bar)

	# Card name
	var name_lbl                    := Label.new()
	name_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size                    = Vector2(CARD_W - 20.0, 50.0)
	name_lbl.position                = pos + Vector2(10.0, 28.0)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(name_lbl)
	_name_labels.append(name_lbl)

	# Card type (SHAPE, STAT, etc.)
	var type_lbl                    := Label.new()
	type_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.size                    = Vector2(CARD_W - 20.0, 28.0)
	type_lbl.position                = pos + Vector2(10.0, 76.0)
	type_lbl.add_theme_font_size_override("font_size", 12)
	add_child(type_lbl)
	_type_labels.append(type_lbl)

	# Rarity label (COMMON, RARE, etc.)
	var rar_lbl                    := Label.new()
	rar_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	rar_lbl.size                    = Vector2(CARD_W - 20.0, 28.0)
	rar_lbl.position                = pos + Vector2(10.0, 100.0)
	rar_lbl.add_theme_font_size_override("font_size", 11)
	add_child(rar_lbl)
	_rar_labels.append(rar_lbl)

	# Description
	var desc_lbl                    := Label.new()
	desc_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode           = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size                    = Vector2(CARD_W - 30.0, 160.0)
	desc_lbl.position                = pos + Vector2(15.0, 158.0)
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", COLOR_DESC)
	add_child(desc_lbl)
	_desc_labels.append(desc_lbl)


# ── Public API ────────────────────────────────────────────

## Show the draft with a fresh set of 3 cards.
func show_draft(cards: Array) -> void:
	_cards_data = cards

	for i in CARD_COUNT:
		var card : Dictionary = cards[i]
		var rar_color := _rarity_color(card.get("rarity", "common"))

		_card_bgs[i].color  = COLOR_CARD_BG   # reset hover state
		_rar_bars[i].color  = rar_color
		_name_labels[i].text = card.get("name", "???")

		_type_labels[i].text = card.get("type", "").to_upper()
		_type_labels[i].add_theme_color_override("font_color", rar_color)

		_rar_labels[i].text  = card.get("rarity", "common").to_upper()
		_rar_labels[i].add_theme_color_override("font_color", rar_color.darkened(0.15))

		_desc_labels[i].text = card.get("description", "")

	visible = true


## Hide the draft screen.
func hide_draft() -> void:
	visible = false


# ── Input ─────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Hover: tint the card the mouse is over
	if event is InputEventMouseMotion:
		for i in CARD_COUNT:
			_card_bgs[i].color = COLOR_CARD_HOV if _card_rects[i].has_point(event.position) else COLOR_CARD_BG

	# Click: select the card under the cursor
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in CARD_COUNT:
			if _card_rects[i].has_point(event.position):
				_on_card_clicked(_cards_data[i].get("id", ""))
				get_viewport().set_input_as_handled()
				return


# ── Private ───────────────────────────────────────────────
func _on_card_clicked(card_id: String) -> void:
	print("Card chosen: ", card_id)
	hide_draft()
	card_selected.emit(card_id)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common":    return Color(0.65, 0.65, 0.70)
		"rare":      return Color(0.25, 0.55, 1.00)
		"legendary": return Color(1.00, 0.72, 0.10)
		_:           return Color(0.65, 0.65, 0.70)