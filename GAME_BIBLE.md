# PARRY ROGUE — Project Bible

## Overview
Top-down fixed-arena action roguelite. Core mechanic: boss attacks with 
a direction + DBD-style timing window. Player presses matching direction 
key + spacebar in the green zone = perfect parry → counter fires.
3 outcomes: perfect parry / chip block / full hit.

## Engine
Godot 4.6.2, GDScript, Forward+ renderer, 1920x1080 canvas_items stretch

## Autoloads
- GameConstants.gd — all balance values (HP, timing, gold, prices)
- CardDatabase.gd — all 12 card definitions (Array of Dicts)
- BuildManager.gd — active_cards[], gold, current_hp, all stat methods
- RunManager.gd — current_row, path[], node_type, current_enemy, MAP_LAYOUT
- SceneManager.gd — fade transitions between scenes (go_to_map/arena/shop/event)
- EnemyDatabase.gd — REGULAR/ELITE/BOSS enemy pools (Array of Dicts)
- GameFeel.gd — freeze_frame(duration), used by Arena for hit pause

## Scene Files
- scenes/arena/Arena.tscn + Arena.gd — combat (parry system, boss, HUD)
- scenes/arena/Arena.gd — orchestrates all combat systems
- scenes/map/MapScreen.tscn + MapScreen.gd — branching node map (_draw based)
- scenes/map/ShopScreen.tscn + ShopScreen.gd — buy cards with gold
- scenes/map/EventScreen.gd — random events with 2 choices
- scenes/bosses/Boss.gd — attack loop, telegraph, sequence generation
- scenes/player/Player.gd — HP, damage, parry input signals
- scenes/ui/SkillCheckUI.gd — rotating needle + green zone (_draw based)
- scenes/ui/SequenceUI.gd — sequence arrow display (_draw based)
- scenes/ui/CardDraftScreen.gd — pick 1 of 3 cards after fight
- scenes/ui/HUD.gd — 6 HP segments
- scenes/ui/BossHPBar.gd — boss HP bar
- scenes/ui/DeathScreen.gd — death overlay, R to restart
- systems/ParrySystem.gd — core logic: direction check + timing = outcome
- systems/CounterProjectile.gd — projectile fired on perfect parry
- systems/ImpactRing.gd — expanding ring visual on counter hit
- constants/GameConstants.gd — all numbers
- scenes/enemies/Enemy.tscn + Enemy.gd — reusable wave-combat enemy base
- systems/EnemySpawner.gd — spawns enemies around player arena

## Groups
## Global groups:
- player
- enemy

## Map Structure
MAP_LAYOUT in RunManager:
Row 0: ["fight","event","fight"]
Row 1: ["shop","fight","elite"]  
Row 2: ["elite","fight","fight"]
Row 3: ["boss"]
Connection rule: ±1 column per row

## Card Types (12 total)
Common: split_shot, wide_guard, iron_skin, quick_reflex, ember_core
Rare: power_strike, vampiric_counter, echo_strike, arcane_surge, frost_edge
Legendary: gods_eye, mirror_defense

## Enemy Types
Regular(5): stone_golem(skill_check), shadow_wraith(skill_check), 
  blood_knight(skill_check), arcane_sentinel(sequence/3), void_crawler(sequence/2)
Elite(2): iron_juggernaut(skill_check), phantom_mage(sequence/3)
Boss(2): ancient_warden(skill_check/350hp), void_sovereign(sequence/4/320hp)

## Minigame Types
skill_check: direction key + spacebar in rotating needle green zone
sequence: press N direction keys in correct order before timer expires

## Key Combat Flow
Boss telegraph (orange flash) → attack_fired(dir, sequence) signal →
Arena routes to ParrySystem → skill check or sequence UI appears →
Player inputs → outcome → damage/counter/chip/miss → boss fires again

## Gold System
Fight:+50 Elite:+80 Boss:+120 | Common:35g Rare:65g Legendary:100g

## HP System
PLAYER_MAX_HP=6 segments, persists between fights via BuildManager.current_hp
CHIP_DAMAGE=0.25 * iron_skin_multiplier, FULL_HIT=1.0

## Current State
Phase 8 foundation complete. Arena/UI architecture refactored into scalable wave-combat foundation.

Current systems working:

map→fight→draft→map loop
shops/events/cards
boss combat
parry system
skill check + sequence minigames
scalable arena movement
enemy spawning/chasing
enemy contact damage
enemy HP/death
temporary player combat loop

## NEXT OBJECTIVE
Expand into full wave-combat roguelite:
- enemy attack cadence
- enemy separation/steering
- WaveManager system
- multiple enemy archetypes
- combat feel polish
- replace temporary player attack system
- XP/build progression
- elite rounds
- boss waves
- Enemies spawn at arena edges, move toward player
- Regular projectiles: dodge by moving
- Highlighted projectiles: trigger existing skill check system
- Wave manager: 2-minute waves, escalating enemy count
- Boss fight remains as climax after 3 waves