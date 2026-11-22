extends Node

signal gold_value_changed

var gold = 0

#this function can be used to add or remove gold
func adjust_gold(amount: int):
	gold += amount
	gold_value_changed.emit()
	#emit_signal("gold_value_changed")


func reset_resources():
	gold = 0
