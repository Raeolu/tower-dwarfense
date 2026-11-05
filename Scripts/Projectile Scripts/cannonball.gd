extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	linear_velocity.y = 0.0

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(5)
		queue_free()
