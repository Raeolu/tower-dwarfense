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
	if player.is_on_floor():
		transition.emit("Idle")
	else:
		transition.emit("Fall")


func exit():
	hitbox.monitoring = false
	attack_test_mesh.hide()


func physics_update(delta: float):
	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta, attack_move_speed_factor)
	player.rotate_to_direction(player.direction)



func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("resource"):
		body.take_damage(attack_damage)
