@tool
class_name EnemyGroup
extends Resource

enum EnemyType {
	SIMPLE,
	FAST,
}

@export var enemy_type: EnemyType = EnemyType.SIMPLE
@export_range(1, 1000, 1, "or_greater") var count: int = 1