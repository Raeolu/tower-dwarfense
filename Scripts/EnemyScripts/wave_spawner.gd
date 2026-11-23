class_name WaveSpawner
extends Node3D

signal wave_started(wave_index: int)
signal wave_finished_spawning(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_completed
signal enemy_spawned(enemy: Node3D)

enum _State {
	IDLE,
	SPAWNING,
	WAITING_FOR_CLEAR,
	WAITING_NEXT_WAVE,
	FINISHED,
}

@export var spawn_points: Array[Node3D] = []
@export var waves: Array[WaveData] = []
@export var auto_start: bool = true
@export_range(0.0, 60.0, 0.5, "or_greater", "suffix:s") var delay_between_waves: float = 5.0
@export var wait_for_wave_clear: bool = false

@export var simple_enemy_scene: PackedScene = preload("res://Scenes/Testing/enemy.tscn")
@export var fast_enemy_scene: PackedScene = preload("res://Scenes/Testing/enemy_fast_example.tscn")

var current_wave_index: int = -1

var _state: _State = _State.IDLE
var _spawn_queue: Array[PackedScene] = []
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.0
var _wave_delay_timer: float = 0.0
var _active_enemies: int = 0
var _wave_total_enemies: int = 0
var _wave_spawned_enemies: int = 0
var _last_spawn_point_name: String = "-"
var _paused: bool = false


func _ready() -> void:
	add_to_group("wave_spawner")

	if auto_start and not waves.is_empty():
		start_spawning()


func _process(delta: float) -> void:
	if _paused:
		return

	match _state:
		_State.SPAWNING:
			_spawn_timer -= delta
			while _state == _State.SPAWNING and _spawn_timer <= 0.0 and not _spawn_queue.is_empty():
				var next_scene: PackedScene = _spawn_queue.pop_front()
				_spawn_enemy(next_scene)
				_spawn_timer += _spawn_interval
			if _state == _State.SPAWNING and _spawn_queue.is_empty():
				_finish_current_wave_spawning()

		_State.WAITING_NEXT_WAVE:
			_wave_delay_timer -= delta
			if _wave_delay_timer <= 0.0:
				start_wave(current_wave_index + 1)


func start_spawning() -> void:
	_paused = false
	_active_enemies = 0
	_spawn_queue.clear()
	start_wave(0)


func stop_spawning() -> void:
	_paused = false
	_state = _State.IDLE
	_spawn_queue.clear()


func pause() -> void:
	_paused = true


func resume() -> void:
	_paused = false


func is_paused() -> bool:
	return _paused


func start_wave(wave_index: int) -> void:
	if wave_index < 0 or wave_index >= waves.size():
		return

	var wave := waves[wave_index]

	current_wave_index = wave_index
	_spawn_queue.clear()

	for group in wave.enemy_groups:
		var enemy_scene := _get_scene_for_type(group.enemy_type)

		for i in range(group.count):
			_spawn_queue.append(enemy_scene)

	_spawn_interval = 1.0 / maxf(wave.spawn_rate, 0.001)
	_spawn_timer = 0.0
	_wave_total_enemies = _spawn_queue.size()
	_wave_spawned_enemies = 0
	_last_spawn_point_name = "-"
	_state = _State.SPAWNING
	wave_started.emit(current_wave_index)

	if _spawn_queue.is_empty():
		_finish_current_wave_spawning()


func _get_scene_for_type(enemy_type: EnemyGroup.EnemyType) -> PackedScene:
	match enemy_type:
		EnemyGroup.EnemyType.SIMPLE:
			return simple_enemy_scene
		EnemyGroup.EnemyType.FAST:
			return fast_enemy_scene
	return null


func _spawn_enemy(enemy_scene: PackedScene) -> void:
	var spawn_point: Node3D = spawn_points.pick_random()
	var instance := enemy_scene.instantiate()
	var enemy := instance as Node3D

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_point.global_position

	_active_enemies += 1
	_wave_spawned_enemies += 1
	_last_spawn_point_name = spawn_point.name
	enemy.tree_exited.connect(_on_enemy_removed, CONNECT_ONE_SHOT)
	enemy_spawned.emit(enemy)


func _finish_current_wave_spawning() -> void:
	wave_finished_spawning.emit(current_wave_index)
	if wait_for_wave_clear and _active_enemies > 0:
		_state = _State.WAITING_FOR_CLEAR
	else:
		if _active_enemies == 0:
			wave_cleared.emit(current_wave_index)
		_advance_or_finish()


func _on_enemy_removed() -> void:
	_active_enemies = maxi(_active_enemies - 1, 0)
	if _state == _State.WAITING_FOR_CLEAR and _active_enemies == 0:
		wave_cleared.emit(current_wave_index)
		_advance_or_finish()


func _advance_or_finish() -> void:
	if current_wave_index + 1 < waves.size():
		_wave_delay_timer = maxf(delay_between_waves, 0.0)
		_state = _State.WAITING_NEXT_WAVE
	else:
		_state = _State.FINISHED
		all_waves_completed.emit()


func get_state_name() -> String:
	if _paused and _state != _State.FINISHED:
		return "Paused"

	match _state:
		_State.IDLE:
			return "Idle"
		_State.SPAWNING:
			return "Spawning"
		_State.WAITING_FOR_CLEAR:
			return "Waiting for Clear"
		_State.WAITING_NEXT_WAVE:
			return "Next Wave Delay"
		_State.FINISHED:
			return "Finished"
	return "Unknown"


func get_debug_info() -> Dictionary:
	var current_spawn_rate := 0.0
	if current_wave_index >= 0 and current_wave_index < waves.size() and waves[current_wave_index] != null:
		current_spawn_rate = waves[current_wave_index].spawn_rate

	var valid_spawn_count := 0
	for sp in spawn_points:
		if sp != null and is_instance_valid(sp):
			valid_spawn_count += 1

	return {
		"state": get_state_name(),
		"wave_index": current_wave_index,
		"wave_count": waves.size(),
		"spawned": _wave_spawned_enemies,
		"total": _wave_total_enemies,
		"active_enemies": _active_enemies,
		"next_wave_in": maxf(_wave_delay_timer, 0.0) if _state == _State.WAITING_NEXT_WAVE else 0.0,
	}
