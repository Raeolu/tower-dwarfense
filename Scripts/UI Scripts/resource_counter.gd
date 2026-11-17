extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Connects to the signal gold_value_changed on the resource_manager script:
	ResourceManager.gold_value_changed.connect(set_gold_value_label)


#Sets the gold value on the label
func set_gold_value_label():
	text = str(ResourceManager.gold) + " GOLD"
