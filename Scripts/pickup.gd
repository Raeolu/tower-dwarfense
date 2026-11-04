extends RigidBody3D


func _on_pickup_box_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var resource_manager = body.get_node("ResourceManager")
		resource_manager.change_resource_count(1)
		queue_free()
