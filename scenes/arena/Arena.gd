# Arena.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# The conductor. Owns all arena systems and connects them.
# Later this will handle boss spawning, round flow,
# and transitioning to the card draft screen.
#
# TEMPORARY: Press Enter to simulate a random boss attack.
# This will be removed once Boss.gd is built in Phase 2.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node2D

# ── Node References ───────────────────────────────────────
@onready var _player       : Node2D = $World/Player
@onready var _parry_system : Node   = $ParrySystem
@onready var _skill_check_ui : Control = $UI/SkillCheckUI
@onready var _boss_slot : Node2D = $World/BossSlot
@onready var _boss : Node2D = $World/BossSlot
@onready var _hud : Control = $UI/HUD
@onready var _death_screen : Control = $UI/DeathScreen
@onready var _boss_hp_bar : Control = $UI/BossHPBarUI
@onready var _card_draft : Control = $UI/CardDraftScreen
@onready var _camera : Camera2D = $World/Player/Camera2D
@onready var _sequence_ui : Control = $UI/SequenceUI


# ── Screen Shake State ────────────────────────────────────
var _shake_intensity    : float = 0.0
var _shake_duration     : float = 0.0
var _shake_max_duration : float = 0.1   # prevents divide by zero


# Dynamically created — shows "FIGHT 2 / 4" or "BOSS FIGHT"
var _fight_label : Label


# ── Card Effect State ─────────────────────────────────────
var _parry_chain      : int  = 0     # consecutive perfect parries (echo_strike)
var _surge_used       : bool = false  # first parry used (arcane_surge)


# ── Lifecycle ─────────────────────────────────────────────
func _ready() -> void:
	# Wire ParrySystem to Player
	_parry_system.setup(_player)

	# Connect parry outcomes
	_parry_system.parry_perfect.connect(_on_parry_perfect)
	_parry_system.parry_chip.connect(_on_parry_chip)
	_parry_system.parry_failed.connect(_on_parry_failed)

	# Connect skill check UI
	_parry_system.window_opened.connect(_on_window_opened)
	_parry_system.window_closed.connect(_on_window_closed)

	# Connect player signals
	_player.player_died.connect(_on_player_died)
	_player.hp_changed.connect(_hud.update_hp)

	# Connect boss signals
	_boss.attack_fired.connect(_on_boss_attack)
	_boss.hp_changed.connect(_boss_hp_bar.update_hp)
	_boss.boss_died.connect(_on_boss_died)

	# Connect card draft
	_card_draft.card_selected.connect(_on_card_selected)

	# Connect sequence input feedback to the sequence UI
	_parry_system.sequence_input_received.connect(_sequence_ui.register_input)

	# Connect win/death screens to R key handler
	# (handled in _unhandled_input below)

	# Configure and start this fight based on RunManager state
	_create_fight_label()
	_configure_fight()


func _configure_fight() -> void:
	var enemy := RunManager.current_enemy

	if not enemy.is_empty():
		# Configure boss from enemy database
		_boss.configure_from_enemy(enemy)
	else:
		# Fallback for any node that reaches arena without enemy data
		var hp       := RunManager.get_current_hp()
		var interval := RunManager.get_current_interval()
		_boss.configure(hp, interval)

	_boss.reset_hp()
	_boss_hp_bar.set_max_hp(_boss.current_hp)
	_boss.start()
	_hud.update_hp(BuildManager.current_hp)
	_parry_chain  = 0
	_surge_used   = false
	_update_fight_label()


# ── Parry Outcome Handlers ────────────────────────────────
func _on_parry_perfect(direction: String) -> void:
	_parry_chain += 1   # increment echo chain

	# Compute final damage with all active multipliers
	var damage := _compute_counter_damage()
	print("✓ PERFECT PARRY! [", direction, "] chain:", _parry_chain, "  damage:", damage)
	print("HP: ", _player.current_hp, " / ", GameConstants.PLAYER_MAX_HP)

	_skill_check_ui.flash_perfect()
	await GameFeel.freeze_frame(0.05)
	_spawn_counter_with_damage(damage)
	_boss.flash_hit()
	_shake_screen(4.0, 0.16)

	_surge_used = true   # arcane surge consumed after first perfect parry


func _on_parry_chip(direction: String) -> void:
	_parry_chain = 0   # reset echo chain on chip
	print("△ CHIP BLOCK [", direction, "] — right direction, wrong timing.")
	_player.take_damage(GameConstants.CHIP_DAMAGE, true)   # is_chip = true
	_shake_screen(3.5, 0.14)
	print("HP: ", _player.current_hp, " / ", GameConstants.PLAYER_MAX_HP)

	# Mirror Defense — chip blocks also fire a weak counter
	if "mirror_defense" in BuildManager.active_cards:
		var mirror_dmg := int(GameConstants.BASE_COUNTER_DAMAGE * 0.4 * BuildManager.get_damage_multiplier())
		_spawn_counter_with_damage(mirror_dmg)


func _on_parry_failed() -> void:
	_parry_chain = 0   # reset echo chain on miss
	print("✗ FULL HIT — wrong direction or no input!")
	_player.take_damage(GameConstants.FULL_HIT_DAMAGE, false)   # is_chip = false
	_shake_screen(9.0, 0.28)
	print("HP: ", _player.current_hp, " / ", GameConstants.PLAYER_MAX_HP)


# ── Player Death ──────────────────────────────────────────
func _on_player_died() -> void:
	print("PLAYER DIED")
	_boss.stop()
	_parry_system.reset()
	_death_screen.show_screen()


func _on_window_opened(direction: String, minigame_type: String) -> void:
	_skill_check_ui.show_check(direction, minigame_type)	
	# Debug label removed — skill check visual handles it now


func _on_window_closed() -> void:
	_skill_check_ui.hide_check()
	_sequence_ui.hide_sequence()


# ── Counter Spawning ──────────────────────────────────────

## Spawns counter projectiles using the current build stats.
func _spawn_counter() -> void:
	_spawn_counter_with_damage(_compute_counter_damage())


## Spawns counter projectiles with a specific pre-computed damage value.
func _spawn_counter_with_damage(damage: int) -> void:
	var count  := BuildManager.get_projectile_count()
	var angles := _get_spread_angles(count)

	for angle in angles:
		var projectile := CounterProjectile.new()
		add_child(projectile)
		projectile.init(_player.global_position, _boss_slot.global_position, damage, angle)
		projectile.hit_landed.connect(_on_counter_hit)


## Computes the total counter damage including all active card multipliers.
func _compute_counter_damage() -> int:
	var base   := GameConstants.BASE_COUNTER_DAMAGE + BuildManager.get_ember_bonus()
	var mult   := BuildManager.get_damage_multiplier()
	var echo   := BuildManager.get_echo_multiplier(_parry_chain)

	# Arcane surge: 3x on first perfect parry of the fight
	var surge  := 3.0 if ("arcane_surge" in BuildManager.active_cards and not _surge_used) else 1.0

	return int(float(base) * mult * echo * surge)


func _on_counter_hit(damage: int) -> void:
	_boss.take_damage(damage)
	_spawn_impact_ring(_boss_slot.global_position)

	# Vampiric Counter — heal on hit
	var heal := BuildManager.get_vampiric_heal()
	if heal > 0.0:
		BuildManager.current_hp = minf(BuildManager.current_hp + heal, float(GameConstants.PLAYER_MAX_HP))
		_player.current_hp      = BuildManager.current_hp
		_hud.update_hp(BuildManager.current_hp)

	# Frost Edge — delay next boss attack
	if "frost_edge" in BuildManager.active_cards:
		_boss.delay_next_attack(0.8)


## Computes the angle offsets for a spread of 'count' projectiles.
## 1 projectile → [0°].  3 projectiles → [−15°, 0°, 15°].
func _get_spread_angles(count: int) -> Array[float]:
	var angles : Array[float] = []
	if count <= 1:
		angles = [0.0]
	else:
		var spread := 30.0
		var step   := spread / float(count - 1)
		for i in count:
			angles.append(-spread / 2.0 + i * step)
	return angles


## Spawns an expanding ring at the impact position.
func _spawn_impact_ring(pos: Vector2) -> void:
	var ring := ImpactRing.new()
	add_child(ring)
	ring.global_position = pos


# ── Boss Events ───────────────────────────────────────────
func _on_boss_attack(direction: String, sequence: Array) -> void:
	print("─────────────────────────────")
	var minigame : String = RunManager.current_enemy.get("minigame", "skill_check")

	if minigame == "sequence":
		print("BOSS SEQUENCE: ", sequence)
		_sequence_ui.show_sequence(sequence)
		_parry_system.begin_sequence_attack(sequence)
	else:
		print("BOSS ATTACKS: ", direction.to_upper())
		_parry_system.begin_attack(direction, "skill_check")


# ── Restart ───────────────────────────────────────────────

# Listen for R key — only acts when death screen is visible
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and _death_screen.visible:
		_restart_run()


# Resets everything back to the start of a fresh run
func _restart_run() -> void:
	# Full run reset — wipe cards and progress then go to map
	BuildManager.reset()
	RunManager.reset()
	SceneManager.go_to_map()

# ── Boss Death ────────────────────────────────────────────
func _on_boss_died() -> void:
	# Award gold based on what type of encounter this was
	var reward : int
	match RunManager.node_type:
		"elite": reward = GameConstants.GOLD_ELITE_REWARD
		"boss":  reward = GameConstants.GOLD_BOSS_REWARD
		_:       reward = GameConstants.GOLD_FIGHT_REWARD
	BuildManager.add_gold(reward)

	_parry_system.reset()
	# Show card draft — player picks one free card after every fight
	_card_draft.show_draft(CardDatabase.get_random_cards(GameConstants.DRAFT_CARDS_SHOWN))


## Fires when the player clicks a card in the draft screen.
func _on_card_selected(card_id: String) -> void:
	BuildManager.add_card(card_id)
	RunManager.advance_row()
	SceneManager.go_to_map()   # always return to map after picking a card


## Creates the fight counter label once on startup.
func _create_fight_label() -> void:
	_fight_label      = Label.new()
	_fight_label.size = Vector2(400.0, 40.0)
	_fight_label.position = Vector2(860.0, 80.0)
	_fight_label.add_theme_font_size_override("font_size", 18)
	_fight_label.add_theme_color_override("font_color", Color(0.60, 0.50, 0.80))
	add_child(_fight_label)


## Updates the fight counter text to reflect the current fight.
func _update_fight_label() -> void:
	var enemy := RunManager.current_enemy
	if not enemy.is_empty():
		_fight_label.text = enemy.get("name", "UNKNOWN")
	elif RunManager.is_boss_row():
		_fight_label.text = "BOSS  FIGHT"
	else:
		_fight_label.text = "Fight  " + str(RunManager.get_fight_number()) + " / " + str(RunManager.MAP_LAYOUT.size())


## Handles the shake each frame
func _process(delta: float) -> void:
	if _shake_duration <= 0.0:
		return

	_shake_duration -= delta

	# Intensity fades out as duration runs down
	var ratio := maxf(_shake_duration / _shake_max_duration, 0.0)
	var cur   := _shake_intensity * ratio
	_camera.offset = Vector2(randf_range(-cur, cur), randf_range(-cur, cur))

	if _shake_duration <= 0.0:
		_camera.offset = Vector2.ZERO


## Triggers a screen shake. Intensity in pixels, duration in seconds.
func _shake_screen(intensity: float, duration: float) -> void:
	_shake_intensity    = intensity
	_shake_max_duration = maxf(duration, 0.01)
	_shake_duration     = duration
