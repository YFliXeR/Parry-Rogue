extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

@export var time_between_waves : float = 3.0

var current_wave : int = 0
var enemies_remaining : int = 0

@onready var _enemy_spawner = $"../World/EnemySpawner"


func start_run() -> void:
	current_wave = 0
	_start_next_wave()


func enemy_killed() -> void:
	enemies_remaining -= 1

	if enemies_remaining <= 0:
		_wave_complete()


func _start_next_wave() -> void:
	current_wave += 1

	var enemy_count := 3 + current_wave * 2

	enemies_remaining = enemy_count

	wave_started.emit(current_wave)

	_enemy_spawner.spawn_wave(enemy_count)


func _wave_complete() -> void:
	wave_completed.emit(current_wave)

	await get_tree().create_timer(time_between_waves).timeout

	_start_next_wave()