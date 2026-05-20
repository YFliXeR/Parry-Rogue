# CounterProjectile.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# The counter-attack projectile fired on a perfect parry.
# No .tscn needed — spawned directly via class_name.
#
# Usage from Arena.gd:
#   var p := CounterProjectile.new()
#   add_child(p)
#   p.init(from_position, to_position)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class_name CounterProjectile
extends Node2D

## Emitted when the projectile reaches the boss.
## Arena listens to this and applies damage to the boss.
signal hit_landed(damage: int)

# ── Visual ────────────────────────────────────────────────
const RADIUS_OUTER : float = 11.0
const RADIUS_INNER : float = 5.5
const COLOR_OUTER  := Color(0.55, 0.88, 1.00, 1.0)   # cyan-white glow
const COLOR_INNER  := Color(1.00, 1.00, 1.00, 1.0)   # pure white core

# ── Config ────────────────────────────────────────────────
const HIT_DISTANCE : float = 55.0   # pixels from target to register a hit


# ── State ─────────────────────────────────────────────────
var _direction  : Vector2 = Vector2.ZERO
var _target_pos : Vector2 = Vector2.ZERO
var _damage     : int     = GameConstants.BASE_COUNTER_DAMAGE
var _has_hit    : bool    = false


# ── Setup ─────────────────────────────────────────────────

## from_pos    : player's global_position
## to_pos      : boss's global_position
## damage      : pre-computed damage (includes build multiplier)
## angle_offset: degrees to rotate the firing direction (for spread)
func init(from_pos: Vector2, to_pos: Vector2, damage: int = GameConstants.BASE_COUNTER_DAMAGE, angle_offset_deg: float = 0.0) -> void:
	global_position = from_pos
	_target_pos     = to_pos
	_damage         = damage
	var base_dir    := (to_pos - from_pos).normalized()
	_direction      = base_dir.rotated(deg_to_rad(angle_offset_deg))


# ── Movement ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if _has_hit:
		return

	global_position += _direction * GameConstants.COUNTER_SPEED * delta

	# Hit check — close enough to boss?
	if global_position.distance_to(_target_pos) < HIT_DISTANCE:
		_trigger_hit()


# ── Hit ───────────────────────────────────────────────────
func _trigger_hit() -> void:
	_has_hit = true
	hit_landed.emit(_damage)   # tell Arena how much damage was dealt
	queue_free()


# ── Drawing ───────────────────────────────────────────────
# Drawn at local origin — Node2D transform moves it automatically
func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS_OUTER, COLOR_OUTER)
	draw_circle(Vector2.ZERO, RADIUS_INNER, COLOR_INNER)