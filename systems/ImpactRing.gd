# ImpactRing.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# A short-lived expanding circle that appears when a counter
# projectile hits the boss. Drawn in code — no assets needed.
# Spawned by Arena._on_counter_hit() and self-destructs.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class_name ImpactRing
extends Node2D


# ── Config ────────────────────────────────────────────────
const MAX_RADIUS : float = 75.0    # how large the ring expands
const SPEED      : float = 260.0   # expansion speed in pixels/sec
const LINE_WIDTH : float = 3.5     # ring stroke width


# ── State ─────────────────────────────────────────────────
var _radius : float = 8.0   # starts slightly above zero so first frame looks good


# ── Lifecycle ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_radius += SPEED * delta
	queue_redraw()
	if _radius >= MAX_RADIUS:
		queue_free()


# ── Drawing ───────────────────────────────────────────────
func _draw() -> void:
	# Alpha fades from 0.85 at start to 0.0 at max radius
	var progress := (_radius - 8.0) / (MAX_RADIUS - 8.0)
	var alpha    := (1.0 - progress) * 0.85
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48,
			 Color(1.0, 0.45, 0.45, alpha), LINE_WIDTH, true)