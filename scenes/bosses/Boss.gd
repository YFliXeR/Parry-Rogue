# Boss.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Controls the boss attack loop.
# Waits → telegraphs (flashes orange) → fires attack → repeats.
# Emits attack_fired(direction) — Arena listens and tells
# ParrySystem to open the parry window.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D


# ── Signals ───────────────────────────────────────────────
signal attack_fired(direction: String, sequence: Array)
signal hp_changed(current: int)    # fires whenever boss takes damage
signal boss_died                   # fires when boss HP reaches zero


# ── Constants ─────────────────────────────────────────────
const DIRECTIONS      := ["left", "right", "up", "down"]
const COLOR_IDLE      := Color(0.80, 0.20, 0.20, 1.0)   # normal red
const COLOR_TELEGRAPH := Color(1.00, 0.55, 0.05, 1.0)   # warning orange
const COLOR_HIT       := Color(1.00, 1.00, 1.00, 1.0)   # white flash on hit


# ── Per-fight Config ──────────────────────────────────────
# Set via configure() before each fight starts.
var _max_hp          : int   = GameConstants.BOSS_MAX_HP
var _attack_interval : float = GameConstants.BOSS_ATTACK_INTERVAL


# ── Per-enemy Config ──────────────────────────────────────
var _idle_color        : Color          = COLOR_IDLE
var _telegraph_duration: float          = GameConstants.BOSS_TELEGRAPH_DURATION
var _minigame_type     : String         = "skill_check"
var _seq_length        : int            = 0
var _pending_sequence  : Array[String]  = []


# ── HP ────────────────────────────────────────────────────
var current_hp : int = GameConstants.BOSS_MAX_HP


# ── State ─────────────────────────────────────────────────
enum State { IDLE, TELEGRAPHING }

var _state           : State  = State.IDLE
var _attack_timer    : float  = 0.0
var _telegraph_timer : float  = 0.0
var _pending_dir     : String = ""
var _is_active       : bool   = false


# ── Node References ───────────────────────────────────────
@onready var _visual : ColorRect = $Visual


# ── Public API ────────────────────────────────────────────

## Call this from Arena to start the boss loop.
func start() -> void:
	_is_active    = true
	_state        = State.IDLE
	_attack_timer = _attack_interval
	_visual.color = COLOR_IDLE


## Sets fight-specific HP and attack speed before starting.
## Call before start() each fight.
func configure(max_hp: int, attack_interval: float) -> void:
	_max_hp          = max_hp
	_attack_interval = attack_interval
	current_hp       = max_hp
	_visual.color    = COLOR_IDLE   # ensure boss is red (not grey from last fight)



## Stops the boss attack loop immediately.
## Called by Arena on player death and before restart.
func stop() -> void:
	_is_active    = false
	_state        = State.IDLE
	_visual.color = _idle_color

## Call this when a counter projectile hits the boss.
## Plays a brief white flash.
func flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "color", COLOR_HIT,   0.05)
	tween.tween_property(_visual, "color", _idle_color, 0.15)


## Apply damage to the boss from a counter projectile hit.
func take_damage(amount: int) -> void:
	if not _is_active:
		return

	current_hp -= amount
	current_hp  = maxi(current_hp, 0)
	hp_changed.emit(current_hp)

	if current_hp <= 0:
		_die()      # boss dies — skip flash so grey sticks
	else:
		flash_hit() # only flash if boss survives this hit


## Resets boss HP — called by Arena when restarting a run.
## Resets HP to the configured max. Emits hp_changed to update the bar.
func reset_hp() -> void:
	current_hp = _max_hp
	hp_changed.emit(current_hp)


# ── Private ───────────────────────────────────────────────
func _die() -> void:
	_is_active = false
	_visual.color = Color(0.3, 0.3, 0.3)   # grey out on death
	print("Boss _die() called — emitting boss_died")   # debug
	boss_died.emit()


# ── Loop ──────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _is_active:
		return

	match _state:
		State.IDLE:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_begin_telegraph()

		State.TELEGRAPHING:
			_telegraph_timer -= delta
			if _telegraph_timer <= 0.0:
				_fire_attack()


# ── Private ───────────────────────────────────────────────
func _begin_telegraph() -> void:
	if _minigame_type == "sequence":
		_pending_sequence.clear()
		for i in _seq_length:
			_pending_sequence.append(DIRECTIONS[randi() % DIRECTIONS.size()])
		print("Boss sequence: ", _pending_sequence)
	else:
		_pending_dir = DIRECTIONS[randi() % DIRECTIONS.size()]
		print("Boss telegraphing: ", _pending_dir.to_upper())

	_state           = State.TELEGRAPHING
	_telegraph_timer = _telegraph_duration
	_visual.color    = COLOR_TELEGRAPH


func _fire_attack() -> void:
	_visual.color = _idle_color
	_state        = State.IDLE
	_attack_timer = _attack_interval

	if _minigame_type == "sequence":
		attack_fired.emit("", _pending_sequence.duplicate())
	else:
		attack_fired.emit(_pending_dir, [])


## Delays the next attack by adding extra time to the attack timer.
## Called by Arena when a frost_edge counter lands.
func delay_next_attack(seconds: float) -> void:
	_attack_timer += seconds


## Configures the boss from an enemy Dictionary from EnemyDatabase.
## Call this before start() each fight.
func configure_from_enemy(enemy: Dictionary) -> void:
	_max_hp              = enemy.get("hp",         GameConstants.REGULAR_FIGHT_HP)
	_attack_interval     = enemy.get("interval",   GameConstants.REGULAR_FIGHT_INTERVAL)
	_telegraph_duration  = enemy.get("telegraph",  GameConstants.BOSS_TELEGRAPH_DURATION)
	_minigame_type       = enemy.get("minigame",   "skill_check")
	_seq_length          = enemy.get("seq_length", 0)
	_idle_color          = enemy.get("color",      COLOR_IDLE)
	current_hp           = _max_hp
	_visual.color        = _idle_color