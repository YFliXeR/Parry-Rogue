# GameFeel.gd
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Autoload — global game feel effects.
# Currently handles freeze frame (the iconic fighting-game
# pause on a big hit).
#
# Usage:
#   await GameFeel.freeze_frame(0.05)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extends Node


## Freezes the entire game for 'duration' seconds.
## Uses REAL time — Engine.time_scale = 0 pauses everything
## except this timer, which ignores time_scale.
## Always await this so code after it runs post-freeze.
func freeze_frame(duration: float = 0.05) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0