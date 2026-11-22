extends RigidBody3D


func _on_pickup_box_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		ResourceManager.adjust_gold(1)
		queue_free()
