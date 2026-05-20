# EventScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shown when the player clicks an EVENT node on the map.
# Picks a random event from the pool and presents 2 choices.
# Each choice applies an effect (heal, gold, card, damage).
# After choosing: shows result → advances row → goes to map.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Event Pool ────────────────────────────────────────────
# Each event has a title, flavor text, and 2 choices.
# Choice effects: "nothing" | "heal" | "gold" | "card" | "damage_and_card" | "rare_and_damage"
const EVENTS : Array = [
	{
		"title":  "Healing Rune",
		"flavor": "A soft light pulses from an ancient rune carved into the stone floor. It hums faintly.",
		"choices": [
			{ "label": "Absorb the energy",  "effect": "heal",    "value": 1, "result": "Warmth flows through you.  (+1 HP)" },
			{ "label": "Walk past it",        "effect": "nothing", "value": 0, "result": "You leave it undisturbed." },
		]
	},
	{
		"title":  "Arcane Cache",
		"flavor": "A hidden compartment in the wall holds crystallised arcane energy, pulsing with stored power.",
		"choices": [
			{ "label": "Claim the crystals",  "effect": "gold",    "value": 60, "result": "You pocket the crystals.  (+60 gold)" },
			{ "label": "Leave it",            "effect": "nothing", "value": 0,  "result": "You walk on." },
		]
	},
	{
		"title":  "Dark Offering",
		"flavor": "An altar pulses with shadowy energy. Power emanates from it — but nothing is free.",
		"choices": [
			{ "label": "Accept the offering  (−1 HP, +1 card)", "effect": "damage_and_card", "value": 1, "result": "Dark energy tears through you. Knowledge is yours.  (−1 HP, +1 card)" },
			{ "label": "Refuse",                                  "effect": "nothing",        "value": 0, "result": "You step away from the altar." },
		]
	},
	{
		"title":  "Wandering Spirit",
		"flavor": "A translucent spirit drifts toward you, holding something in its ethereal hands.",
		"choices": [
			{ "label": "Accept the gift",  "effect": "card",    "value": 1, "result": "The spirit smiles and fades.  (+1 random card)" },
			{ "label": "Dismiss it",       "effect": "nothing", "value": 0, "result": "The spirit drifts away, confused." },
		]
	},
	{
		"title":  "Forbidden Tome",
		"flavor": "A book bound in shadow sits open on a pedestal. Its pages glow with dangerous knowledge.",
		"choices": [
			{ "label": "Read it  (−2 HP, +1 rare card)", "effect": "rare_and_damage", "value": 2, "result": "The knowledge burns into your mind.  (−2 HP, +1 rare card)" },
			{ "label": "Close the tome",                  "effect": "nothing",        "value": 0, "result": "You shut it before it can harm you." },
		]
	},
]


# ── Button Rects for click detection ──────────────────────
const BTN_1_RECT := Rect2(460.0, 560.0, 1000.0, 64.0)
const BTN_2_RECT := Rect2(460.0, 644.0, 1000.0, 64.0)


# ── State ─────────────────────────────────────────────────
var _event        : Dictionary = {}
var _chose        : bool       = false   # prevents double-click


# ── Node References ───────────────────────────────────────
var _result_label : Label
var _btn1_bg      : ColorRect
var _btn2_bg      : ColorRect


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	# Pick a random event
	var events_copy := EVENTS.duplicate()
	events_copy.shuffle()
	_event = events_copy[0]

	_build_ui()


# ── UI Construction ───────────────────────────────────────
func _build_ui() -> void:
	# Background
	var bg      := ColorRect.new()
	bg.color     = Color(0.05, 0.03, 0.10)
	bg.size      = Vector2(1920.0, 1080.0)
	bg.position  = Vector2.ZERO
	add_child(bg)

	# Event title
	var title_lbl                     := Label.new()
	title_lbl.text                     = _event.get("title", "Unknown Event")
	title_lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size                     = Vector2(1000.0, 80.0)
	title_lbl.position                 = Vector2(460.0, 160.0)
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 1.00))
	add_child(title_lbl)

	# Flavor text
	var flavor_lbl                     := Label.new()
	flavor_lbl.text                     = _event.get("flavor", "")
	flavor_lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	flavor_lbl.vertical_alignment       = VERTICAL_ALIGNMENT_CENTER
	flavor_lbl.autowrap_mode            = TextServer.AUTOWRAP_WORD_SMART
	flavor_lbl.size                     = Vector2(900.0, 120.0)
	flavor_lbl.position                 = Vector2(510.0, 290.0)
	flavor_lbl.add_theme_font_size_override("font_size", 17)
	flavor_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.70))
	add_child(flavor_lbl)

	# Divider line visual (just a slim ColorRect)
	var divider      := ColorRect.new()
	divider.size      = Vector2(600.0, 1.0)
	divider.position  = Vector2(660.0, 490.0)
	divider.color     = Color(0.25, 0.22, 0.35)
	add_child(divider)

	# Choice buttons
	var choices := _event.get("choices", []) as Array
	_btn1_bg = _build_button(choices[0].get("label", "Choice 1") if choices.size() > 0 else "Continue",
							 BTN_1_RECT, Color(0.12, 0.09, 0.22))
	_btn2_bg = _build_button(choices[1].get("label", "Leave")    if choices.size() > 1 else "Leave",
							 BTN_2_RECT, Color(0.09, 0.08, 0.16))

	# Result label — hidden until a choice is made
	_result_label                      = Label.new()
	_result_label.text                  = ""
	_result_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.size                  = Vector2(900.0, 50.0)
	_result_label.position              = Vector2(510.0, 780.0)
	_result_label.visible               = false
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.add_theme_color_override("font_color", Color(0.70, 0.90, 0.70))
	add_child(_result_label)


func _build_button(label_text: String, rect: Rect2, bg_color: Color) -> ColorRect:
	var bg      := ColorRect.new()
	bg.size      = rect.size
	bg.position  = rect.position
	bg.color     = bg_color
	add_child(bg)

	var lbl                     := Label.new()
	lbl.text                     = label_text
	lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment       = VERTICAL_ALIGNMENT_CENTER
	lbl.size                     = rect.size
	lbl.position                 = rect.position
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.95))
	add_child(lbl)

	return bg


# ── Input ─────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _chose:
		return
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var choices := _event.get("choices", []) as Array

	if BTN_1_RECT.has_point(event.position) and choices.size() > 0:
		_choose(choices[0])
		get_viewport().set_input_as_handled()
	elif BTN_2_RECT.has_point(event.position) and choices.size() > 1:
		_choose(choices[1])
		get_viewport().set_input_as_handled()


# ── Choice Resolution ─────────────────────────────────────
func _choose(choice: Dictionary) -> void:
	_chose = true
	_apply_effect(choice)

	# Show result and wait before transitioning
	_result_label.text    = choice.get("result", "")
	_result_label.visible = true

	# Dim buttons to show they're no longer clickable
	_btn1_bg.color = Color(0.06, 0.05, 0.10)
	_btn2_bg.color = Color(0.06, 0.05, 0.10)

	await get_tree().create_timer(1.8).timeout
	RunManager.advance_row()
	SceneManager.go_to_map()


func _apply_effect(choice: Dictionary) -> void:
	var effect : String = choice.get("effect", "nothing")
	var value  : int    = choice.get("value", 0)

	match effect:
		"heal":
			# Restore HP without exceeding max
			BuildManager.current_hp = minf(
				BuildManager.current_hp + float(value),
				float(GameConstants.PLAYER_MAX_HP)
			)
			print("Event: Healed ", value, " HP | HP now: ", BuildManager.current_hp)

		"gold":
			BuildManager.add_gold(value)

		"card":
			# Give one random card from the full pool
			var cards := CardDatabase.get_random_cards(1)
			if not cards.is_empty():
				BuildManager.add_card(cards[0].get("id", ""))

		"damage_and_card":
			# Lose HP and gain a card — can't kill the player
			BuildManager.current_hp = maxf(BuildManager.current_hp - float(value), 0.5)
			var cards := CardDatabase.get_random_cards(1)
			if not cards.is_empty():
				BuildManager.add_card(cards[0].get("id", ""))

		"rare_and_damage":
			# Lose HP and gain a rare card specifically
			BuildManager.current_hp = maxf(BuildManager.current_hp - float(value), 0.5)
			var rare_pool : Array = CardDatabase.ALL_CARDS.filter(
				func(c: Dictionary) -> bool: return c.get("rarity", "") == "rare"
			)
			if not rare_pool.is_empty():
				rare_pool.shuffle()
				BuildManager.add_card(rare_pool[0].get("id", ""))

		"nothing":
			pass   # player chose to do nothing — no effect