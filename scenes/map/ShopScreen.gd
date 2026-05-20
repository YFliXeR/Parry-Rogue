# ShopScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shown when the player clicks a SHOP node on the map.
# Displays 3 buyable cards with gold costs.
# Player can buy any they can afford, then leave.
# On leave: RunManager.advance_row() → SceneManager.go_to_map()
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Layout ────────────────────────────────────────────────
const CARD_COUNT : int   = 3
const CARD_W     : float = 260.0
const CARD_H     : float = 380.0
const CARD_GAP   : float = 80.0

const LEAVE_RECT := Rect2(760.0, 900.0, 400.0, 64.0)


# ── State ─────────────────────────────────────────────────
var _shop_cards : Array = []
var _purchased  : Array = [false, false, false]
var _card_rects : Array = []


# ── Node References ───────────────────────────────────────
var _gold_label   : Label
var _card_bgs     : Array = []
var _price_labels : Array = []
var _sold_labels  : Array = []


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	_shop_cards = CardDatabase.get_random_cards(CARD_COUNT)

	var total_w := CARD_COUNT * CARD_W + (CARD_COUNT - 1) * CARD_GAP
	var start_x := (1920.0 - total_w) / 2.0
	var card_y  := 260.0

	for i in CARD_COUNT:
		var cx := start_x + i * (CARD_W + CARD_GAP)
		_card_rects.append(Rect2(cx, card_y, CARD_W, CARD_H))

	_build_ui()


# ── UI Construction ───────────────────────────────────────
func _build_ui() -> void:
	# Background
	var bg       := ColorRect.new()
	bg.color      = Color(0.05, 0.03, 0.10)
	bg.size       = Vector2(1920.0, 1080.0)
	bg.position   = Vector2.ZERO
	add_child(bg)

	# Title
	var title                      := Label.new()
	title.text                      = "SHOP"
	title.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	title.size                      = Vector2(400.0, 70.0)
	title.position                  = Vector2(760.0, 55.0)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.20, 0.80, 0.45))
	add_child(title)

	# Hint
	var hint                      := Label.new()
	hint.text                      = "buy cards with your gold — leave when done"
	hint.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	hint.size                      = Vector2(700.0, 30.0)
	hint.position                  = Vector2(610.0, 140.0)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.35, 0.55, 0.40))
	add_child(hint)

	# Gold display
	_gold_label                    = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.size               = Vector2(400.0, 40.0)
	_gold_label.position           = Vector2(760.0, 185.0)
	_gold_label.add_theme_font_size_override("font_size", 26)
	_gold_label.add_theme_color_override("font_color", Color(1.00, 0.80, 0.10))
	add_child(_gold_label)
	_refresh_gold()

	# Card slots
	for i in CARD_COUNT:
		_build_card_slot(i, _card_rects[i].position)

	# Leave button
	var leave_bg      := ColorRect.new()
	leave_bg.size      = LEAVE_RECT.size
	leave_bg.position  = LEAVE_RECT.position
	leave_bg.color     = Color(0.10, 0.08, 0.18)
	add_child(leave_bg)

	var leave_lbl                      := Label.new()
	leave_lbl.text                      = "LEAVE  SHOP"
	leave_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	leave_lbl.vertical_alignment        = VERTICAL_ALIGNMENT_CENTER
	leave_lbl.size                      = LEAVE_RECT.size
	leave_lbl.position                  = LEAVE_RECT.position
	leave_lbl.add_theme_font_size_override("font_size", 22)
	leave_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.80))
	add_child(leave_lbl)


func _build_card_slot(index: int, pos: Vector2) -> void:
	var card      = _shop_cards[index]
	var rarity    : String = card.get("rarity", "common")
	var rar_color : Color  = _rarity_color(rarity)

	# Background
	var bg      := ColorRect.new()
	bg.size      = Vector2(CARD_W, CARD_H)
	bg.position  = pos
	bg.color     = Color(0.08, 0.06, 0.12)
	add_child(bg)
	_card_bgs.append(bg)

	# Rarity bar
	var rar_bar      := ColorRect.new()
	rar_bar.size      = Vector2(CARD_W, 5.0)
	rar_bar.position  = pos
	rar_bar.color     = rar_color
	add_child(rar_bar)

	# Name
	var name_lbl                      := Label.new()
	name_lbl.text                      = card.get("name", "???")
	name_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.size                      = Vector2(CARD_W - 20.0, 50.0)
	name_lbl.position                  = pos + Vector2(10.0, 24.0)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(name_lbl)

	# Type
	var type_lbl                      := Label.new()
	type_lbl.text                      = card.get("type", "").to_upper()
	type_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.size                      = Vector2(CARD_W - 20.0, 26.0)
	type_lbl.position                  = pos + Vector2(10.0, 70.0)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", rar_color)
	add_child(type_lbl)

	# Description
	var desc_lbl                      := Label.new()
	desc_lbl.text                      = card.get("description", "")
	desc_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment        = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode             = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size                      = Vector2(CARD_W - 24.0, 190.0)
	desc_lbl.position                  = pos + Vector2(12.0, 104.0)
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.82))
	add_child(desc_lbl)

	# Price label
	var price_lbl                     := Label.new()
	price_lbl.text                     = str(_get_price(rarity)) + "  gold"
	price_lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.size                     = Vector2(CARD_W - 20.0, 40.0)
	price_lbl.position                 = pos + Vector2(10.0, CARD_H - 52.0)
	price_lbl.add_theme_font_size_override("font_size", 18)
	price_lbl.add_theme_color_override("font_color", Color(1.00, 0.80, 0.10))
	add_child(price_lbl)
	_price_labels.append(price_lbl)

	# "PURCHASED" label — hidden until bought
	var sold_lbl                      := Label.new()
	sold_lbl.text                      = "PURCHASED"
	sold_lbl.horizontal_alignment      = HORIZONTAL_ALIGNMENT_CENTER
	sold_lbl.size                      = Vector2(CARD_W - 20.0, 40.0)
	sold_lbl.position                  = pos + Vector2(10.0, CARD_H - 52.0)
	sold_lbl.visible                   = false
	sold_lbl.add_theme_font_size_override("font_size", 16)
	sold_lbl.add_theme_color_override("font_color", Color(0.35, 0.70, 0.45))
	add_child(sold_lbl)
	_sold_labels.append(sold_lbl)


# ── Private Helpers ───────────────────────────────────────

func _get_price(rarity: String) -> int:
	match rarity:
		"rare":      return GameConstants.SHOP_PRICE_RARE
		"legendary": return GameConstants.SHOP_PRICE_LEGENDARY
		_:           return GameConstants.SHOP_PRICE_COMMON


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":      return Color(0.25, 0.55, 1.00)
		"legendary": return Color(1.00, 0.72, 0.10)
		_:           return Color(0.65, 0.65, 0.70)


func _refresh_gold() -> void:
	if _gold_label:
		_gold_label.text = "◆  " + str(BuildManager.gold) + "  gold"


func _mark_purchased(index: int) -> void:
	_purchased[index]              = true
	_price_labels[index].visible   = false
	_sold_labels[index].visible    = true
	_card_bgs[index].color         = Color(0.05, 0.04, 0.08)
	_refresh_gold()


# ── Input ─────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# Check card clicks
	for i in CARD_COUNT:
		if not _card_rects[i].has_point(event.position):
			continue
		if _purchased[i]:
			continue

		var rarity  : String = _shop_cards[i].get("rarity", "common")
		var price   : int    = _get_price(rarity)
		var card_id : String = _shop_cards[i].get("id", "")

		if BuildManager.spend_gold(price):
			BuildManager.add_card(card_id)
			_mark_purchased(i)
			print("Bought: ", _shop_cards[i].get("name", "?"), " (", price, "g) | Gold left: ", BuildManager.gold)
		else:
			print("Not enough gold. Need ", price, " | Have ", BuildManager.gold)

		get_viewport().set_input_as_handled()
		return

	# Leave button
	if LEAVE_RECT.has_point(event.position):
		RunManager.advance_row()
		SceneManager.go_to_map()
		get_viewport().set_input_as_handled()
