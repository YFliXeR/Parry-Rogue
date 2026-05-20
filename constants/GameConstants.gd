# GameConstants.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ALL balance values for the entire game live here.
# Change a number here → it updates everywhere automatically.
# Never hardcode numbers in other scripts.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


# ── Player ────────────────────────────────────────────────
const PLAYER_MAX_HP          : int   = 6      # total health segments per run
const CHIP_DAMAGE            : float = 0.25   # HP lost on chip block (wrong timing)
const FULL_HIT_DAMAGE        : float = 1.0    # HP lost on full hit (wrong direction)
const PLAYER_MOVE_SPEED      : float = 320.0  # pixels per second, WASD movement
const ARENA_BOUNDS : Rect2 = Rect2(160.0, 90.0, 1600.0, 900.0)
const PLAYER_BOUNDS_PADDING  : float = 40.0   # pixels from screen edge player can't cross


# ── Parry System ──────────────────────────────────────────
const PARRY_WINDOW_DURATION  : float = 1.2    # seconds the skill check is active (default is 0.8)
const PARRY_SUCCESS_START    : float = 0.30   # window opens at 30% through the check
const PARRY_SUCCESS_END      : float = 0.55   # window closes at 55% through the check
# Tip: widen SUCCESS_START→END gap to make timing easier, narrow it to make harder


# ── Counter Attack ────────────────────────────────────────
const BASE_COUNTER_DAMAGE    : int   = 25     # damage of a base counter (no upgrades)
const COUNTER_SPEED          : float = 600.0  # pixels per second


# ── Run Structure ─────────────────────────────────────────
const ACTS_PER_RUN           : int   = 3      # total acts before final boss
const FIGHTS_PER_ACT         : int   = 3      # regular fights before each act boss
const FIGHTS_PER_RUN          : int   = 4      # 3 regular fights + 1 boss fight
const REGULAR_FIGHT_HP        : int   = 150    # enemy HP in regular fights
const REGULAR_FIGHT_INTERVAL  : float = 2.2    # seconds between attacks in regular fights
const BOSS_FIGHT_HP           : int   = 350    # final boss has more HP
const BOSS_FIGHT_INTERVAL     : float = 1.8    # final boss attacks faster


# ── Card Draft ────────────────────────────────────────────
const DRAFT_CARDS_SHOWN      : int   = 3      # how many cards player picks from


# ── Boss ──────────────────────────────────────────────────
const BOSS_ATTACK_INTERVAL    : float = 2.5   # seconds between attacks
const BOSS_TELEGRAPH_DURATION : float = 0.6   # orange warning before attack fires
const BOSS_MAX_HP             : int   = 250   # 10 perfect parries at base damage to kill
const ELITE_FIGHT_HP       : int   = 220    # elite enemy HP (harder than regular)
const ELITE_FIGHT_INTERVAL : float = 2.0    # elite attacks faster than regular


# ── Gold ──────────────────────────────────────────────────
const GOLD_FIGHT_REWARD    : int = 50    # gold earned from regular fight
const GOLD_ELITE_REWARD    : int = 80    # gold earned from elite fight
const GOLD_BOSS_REWARD     : int = 120   # gold earned from boss fight

const SHOP_PRICE_COMMON    : int = 35    # cost to buy a common card
const SHOP_PRICE_RARE      : int = 65    # cost to buy a rare card
const SHOP_PRICE_LEGENDARY : int = 100   # cost to buy a legendary card