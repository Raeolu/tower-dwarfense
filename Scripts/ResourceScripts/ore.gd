extends Node

var resource_dropped = preload("res://Scenes/Resources/Pickup.tscn")

var health = 15.0


func take_damage(num):
	health -= num
	if health <= 0:
		destroy()


func destroy():
	var resource_instance = resource_dropped.instantiate()
	resource_instance.position = self.position
	get_tree().current_scene.add_child(resource_instance)
	queue_free()
