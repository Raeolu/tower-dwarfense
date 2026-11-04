extends Node

var resource_count = 0

@onready var resource_UI = $"../PlayerUI/MarginContainer/VBoxContainer/ResourceCounter"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func change_resource_count(num):
	resource_count += num
	resource_UI.text = str(resource_count) + " GOLD"
	
