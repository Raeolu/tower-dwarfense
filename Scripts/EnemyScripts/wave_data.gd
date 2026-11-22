@tool
class_name WaveData
extends Resource

@export_range(0.05, 100.0, 0.1, "or_greater", "suffix:enemies/s") var spawn_rate: float = 1.0

@export var enemy_groups: Array[EnemyGroup] = []


func _init() -> void:
	resource_local_to_scene = true
