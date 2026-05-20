# MapScreen.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Visual node map drawn entirely with Godot's _draw() API.
# No child nodes needed — everything is code-drawn.
#
# Player clicks an available node → RunManager.select_node()
# → SceneManager.go_to_arena()
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Node Visual ───────────────────────────────────────────
const NODE_RADIUS : float = 42.0   # circle radius for draw + click detection

# Display text inside each node type
const TYPE_LABELS := {
	"fight": "FIGHT",
	"elite": "ELITE",
	"shop":  "SHOP",
	"event": "EVENT",
	"boss":  "BOSS",
}

# Color for each node type (used when node is available)
const TYPE_COLORS := {
	"fight": Color(0.25, 0.55, 0.90),   # blue
	"elite": Color(0.90, 0.55, 0.10),   # orange
	"shop":  Color(0.20, 0.75, 0.40),   # green
	"event": Color(0.65, 0.30, 0.80),   # purple
	"boss":  Color(0.90, 0.15, 0.15),   # red
}


# ── Victory State ─────────────────────────────────────────
# Rect2 used for click detection on the play-again button
const PLAY_AGAIN_RECT := Rect2(780.0, 680.0, 360.0, 72.0)


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	queue_redraw()


# ── Drawing ───────────────────────────────────────────────
func _draw() -> void:
	# Background
	draw_rect(Rect2(0.0, 0.0, 1920.0, 1080.0), Color(0.05, 0.03, 0.10))

	if RunManager.is_run_complete():
		_draw_victory()
	else:
		_draw_map()
		_draw_card_summary()


func _draw_map() -> void:
	var font := ThemeDB.fallback_font

	# Title
	var title    := "PARRY  ROGUE"
	var title_sz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 42)
	draw_string(font, Vector2(960.0 - title_sz.x / 2.0, 95.0),
				title, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(0.75, 0.55, 1.00))

	# Gold display — top right corner
	var gold_txt := "◆  " + str(BuildManager.gold) + "  gold"
	var gold_sz  := font.get_string_size(gold_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font, Vector2(1920.0 - gold_sz.x - 30.0, 55.0),
				gold_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.00, 0.80, 0.10))

	# Small instruction
	var hint    := "click a node to begin the next encounter"
	var hint_sz := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(960.0 - hint_sz.x / 2.0, 128.0),
				hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.35, 0.30, 0.50))

	# Connection lines (drawn first so nodes sit on top)
	_draw_connections()

	# All nodes
	for row in RunManager.MAP_LAYOUT.size():
		for col in RunManager.MAP_LAYOUT[row].size():
			_draw_node(
				_node_pos(row, col),
				RunManager.get_node_type(row, col),
				RunManager.get_node_state(row, col)
			)


func _draw_connections() -> void:
	for row in RunManager.MAP_LAYOUT.size() - 1:
		var next_count : int = RunManager.MAP_LAYOUT[row + 1].size()

		for col in RunManager.MAP_LAYOUT[row].size():
			for nc in next_count:
				# Connect if adjacent OR if next row has only one node (boss)
				if next_count == 1 or abs(col - nc) <= 1:
					var from_state := RunManager.get_node_state(row, col)
					var to_state   := RunManager.get_node_state(row + 1, nc)

					# Bright line on the active path, dim elsewhere
					var on_path := (from_state == "completed" and
								   (to_state == "available" or to_state == "completed"))
					var line_color := Color(0.42, 0.38, 0.62, 0.9) if on_path \
								   else Color(0.14, 0.12, 0.22, 0.6)

					draw_line(_node_pos(row, col), _node_pos(row + 1, nc),
							  line_color, 2.0, true)


func _draw_node(pos: Vector2, type: String, state: String) -> void:
	var font       := ThemeDB.fallback_font
	var type_color : Color = TYPE_COLORS.get(type, Color.WHITE)

	# Choose colors per state
	var bg_color     : Color
	var border_color : Color
	var text_color   : Color

	match state:
		"available":
			bg_color     = type_color.darkened(0.35)
			border_color = type_color
			text_color   = Color.WHITE
		"completed":
			bg_color     = Color(0.10, 0.08, 0.15)
			border_color = Color(0.28, 0.25, 0.38)
			text_color   = Color(0.40, 0.38, 0.50)
		_:  # locked
			bg_color     = Color(0.05, 0.04, 0.08)
			border_color = Color(0.11, 0.09, 0.16)
			text_color   = Color(0.18, 0.16, 0.22)

	draw_circle(pos, NODE_RADIUS, bg_color)
	draw_arc(pos, NODE_RADIUS, 0.0, TAU, 48, border_color, 2.5, true)

	# Text: checkmark for completed nodes, type label for others
	var label : String = "✓" if state == "completed" else TYPE_LABELS.get(type, "?")
	var font_size : int = 22 if state == "completed" else 12
	var ls        := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, pos + Vector2(-ls.x / 2.0, ls.y / 4.0),
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _draw_card_summary() -> void:
	if BuildManager.active_cards.is_empty():
		return

	var font := ThemeDB.fallback_font
	var x    := 60.0
	var y    := 900.0

	draw_string(font, Vector2(x, y), "Active cards:", HORIZONTAL_ALIGNMENT_LEFT,
				-1, 14, Color(0.50, 0.45, 0.65))
	y += 22.0

	for card_id in BuildManager.active_cards:
		for card in CardDatabase.ALL_CARDS:
			if card["id"] == card_id:
				draw_string(font, Vector2(x, y), "·  " + card["name"],
							HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.80, 0.55))
				y += 18.0


func _draw_victory() -> void:
	var font := ThemeDB.fallback_font

	# Gold title
	var title    := "RUN  COMPLETE"
	var title_sz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
	draw_string(font, Vector2(960.0 - title_sz.x / 2.0, 380.0),
				title, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(1.0, 0.80, 0.10))

	# Subtitle
	var sub    := "You survived every encounter."
	var sub_sz := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(font, Vector2(960.0 - sub_sz.x / 2.0, 460.0),
				sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.70, 0.58, 0.28))

	# Card count
	var cards    := "Total cards collected:  " + str(BuildManager.active_cards.size())
	var cards_sz := font.get_string_size(cards, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font, Vector2(960.0 - cards_sz.x / 2.0, 510.0),
				cards, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.45, 0.80, 0.55))

	# Play again button (drawn rect — click detection in _input)
	draw_rect(PLAY_AGAIN_RECT, Color(0.15, 0.12, 0.03))
	draw_rect(PLAY_AGAIN_RECT, Color(0.60, 0.45, 0.05), false, 2.0)
	var btn    := "PLAY  AGAIN"
	var btn_sz := font.get_string_size(btn, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_string(font,
				Vector2(PLAY_AGAIN_RECT.position.x + PLAY_AGAIN_RECT.size.x / 2.0 - btn_sz.x / 2.0,
						PLAY_AGAIN_RECT.position.y + PLAY_AGAIN_RECT.size.y / 2.0 + btn_sz.y / 4.0),
				btn, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)


# ── Node Position ─────────────────────────────────────────

## Computes the screen position of a node at (row, col).
## Row 0 is at the bottom, boss row is at the top.
func _node_pos(row: int, col: int) -> Vector2:
	var num_cols  : int   = RunManager.MAP_LAYOUT[row].size()
	var col_space : float = 280.0
	var total_w   : float = (num_cols - 1) * col_space
	var x         : float = 960.0 - total_w / 2.0 + col * col_space

	var row_count : int = RunManager.MAP_LAYOUT.size()
	var y_bottom   := 830.0
	var y_top      := 200.0
	var y_step     := (y_bottom - y_top) / float(row_count - 1)
	var y          := y_bottom - row * y_step

	return Vector2(x, y)


# ── Input ─────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# Victory screen — only check play again button
	if RunManager.is_run_complete():
		if PLAY_AGAIN_RECT.has_point(event.position):
			BuildManager.reset()
			RunManager.reset()
			SceneManager.go_to_map()
			get_viewport().set_input_as_handled()
		return

	# Map — check if player clicked an available node in the current row
	var current_row := RunManager.current_row
	if current_row >= RunManager.MAP_LAYOUT.size():
		return

	for col in RunManager.MAP_LAYOUT[current_row].size():
		if RunManager.get_node_state(current_row, col) != "available":
			continue

		var pos := _node_pos(current_row, col)
		if event.position.distance_to(pos) <= NODE_RADIUS + 8.0:
			RunManager.select_node(current_row, col)
			match RunManager.get_node_type(current_row, col):
				"shop":  SceneManager.go_to_shop()
				"event": SceneManager.go_to_event()
				_:       SceneManager.go_to_arena()			
			return
