extends Node

#This state machine runs the enter, exit, update and physics update functions on
#whichever of its children is currently the current_state. Only one can be the current_state

@export var initial_state : PlayerState

var current_state : PlayerState
var states : Dictionary = {}


func _ready() -> void:
	for child in get_children(): #Add all possible states to dictionary
		if child is PlayerState:
			states[child.name.to_lower()] = child #to_lower converts string to lowercase, in case of bad capitalisation
			child.transition.connect(on_state_transition)
	
	if initial_state: #if an initial state is assigned, call its enter function and set it to current state
		initial_state.enter()
		current_state = initial_state
	
	print(states)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	
	$"../StateLabel".text = str(current_state)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_state_transition(new_state_name):
	var old_state = current_state
	
	if old_state != current_state:
		return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	
	current_state = new_state
