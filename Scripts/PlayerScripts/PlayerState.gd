extends Node
class_name PlayerState

signal transition

#All other player states derive from this PLayerState script. The signal transition is used
#to switch between states.

@export var player: Player

func _ready() -> void:
	pass

func enter():
	pass

func exit():
	pass


func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
