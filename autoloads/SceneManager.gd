# SceneManager.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — handles all scene transitions in the game.
# Creates a black overlay that fades out → scene loads →
# fades in. Persists across all scene changes.
#
# Usage:
#   SceneManager.go_to_map()
#   SceneManager.go_to_arena()
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Scene Paths ───────────────────────────────────────────
const MAP_SCENE   := "res://scenes/map/MapScreen.tscn"
const ARENA_SCENE := "res://scenes/arena/Arena.tscn"
const SHOP_SCENE  := "res://scenes/map/ShopScreen.tscn"
const EVENT_SCENE := "res://scenes/map/EventScreen.tscn"


# ── Config ────────────────────────────────────────────────
const FADE_DURATION : float = 0.35   # seconds for each fade


# ── Overlay ───────────────────────────────────────────────
var _overlay : ColorRect   # full-screen black rect, lives on a CanvasLayer


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	_build_overlay()


func _build_overlay() -> void:
	# CanvasLayer at a very high layer so it covers everything
	var canvas       := CanvasLayer.new()
	canvas.layer      = 100
	add_child(canvas)

	# Full-screen black rect — starts invisible
	_overlay              = ColorRect.new()
	_overlay.color         = Color.BLACK
	_overlay.size          = Vector2(1920.0, 1080.0)
	_overlay.modulate.a    = 0.0
	_overlay.mouse_filter  = Control.MOUSE_FILTER_IGNORE   # don't block clicks while invisible
	canvas.add_child(_overlay)


# ── Public API ────────────────────────────────────────────

## Transition to the map screen.
func go_to_map() -> void:
	_transition_to(MAP_SCENE)


## Transition to the arena for the current fight.
func go_to_arena() -> void:
	_transition_to(ARENA_SCENE)


## Transition to the shop screen.
func go_to_shop() -> void:
	_transition_to(SHOP_SCENE)


## Transition to a random event screen.
func go_to_event() -> void:
	_transition_to(EVENT_SCENE)


# ── Private ───────────────────────────────────────────────

## Fades to black → changes scene → fades back in.
func _transition_to(scene_path: String) -> void:
	# Block input during transition so nothing gets clicked mid-fade
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()

	# Step 1: fade to black
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)

	# Step 2: swap the scene while screen is black
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

	# Step 3: fade back to transparent
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)

	# Step 4: restore input
	tween.tween_callback(func(): _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)
