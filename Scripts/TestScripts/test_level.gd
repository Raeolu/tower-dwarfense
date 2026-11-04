extends Node3D

@onready var player = $player
var freeze_slow = 0.01
var freeze_time = 0.2
var velocity

func _physics_process(delta):
	get_tree().call_group("enemy", "update_target_location", player.global_transform.origin)


func freeze():
	Engine.time_scale = freeze_slow
	await get_tree().create_timer(freeze_time * freeze_slow).timeout
	#await get_tree().create_timer(freeze_time, true, false, true).timeout
	Engine.time_scale = 1
