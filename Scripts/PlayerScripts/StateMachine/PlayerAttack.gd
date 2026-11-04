extends PlayerState

@export var attack_move_speed_factor = 0.5
@export var attack_duration = 0.2
@export var attack_damage = 5

@onready var attack_test_mesh = $"../../Visuals/AttackTestMesh"
@onready var hitbox = $"../../Visuals/AttackArea"

func enter():
	hitbox.monitoring = true
	attack_test_mesh.show()
	
	await get_tree().create_timer(attack_duration).timeout
	transition.emit("Idle")


func exit():
	hitbox.monitoring = false
	attack_test_mesh.hide()


func physics_update(_delta: float):
	if player.direction:
		player.velocity.x = player.direction.x * (player.SPEED * attack_move_speed_factor)
		player.velocity.z = player.direction.z * (player.SPEED * attack_move_speed_factor)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	
	#rotates the player to the direction. Check the player script for more info.
	player.rotate_to_direction(player.direction)



func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("resource"):
		body.take_damage(attack_damage)
