extends PlayerState

func enter():
	pass

func exit():
	pass

func physics_update(delta: float):
	if not player.is_on_floor():
		transition.emit("Fall")
	elif Input.is_action_just_pressed("jump"):
		transition.emit("Jump")
	elif Input.is_action_just_pressed("attack"):
		transition.emit("attack")

	elif Input.is_action_just_pressed("bash") and player.can_dash == true:
		transition.emit("Dash")

	#Sets the state to idle if no direction is currently being given by the player script.
	elif !player.direction:
		transition.emit("Idle")

	# Smooth accelerationnn
	player.apply_horizontal_movement(delta)
	#rotates the player to the direction. Check the player script for more info.
	player.rotate_to_direction(player.direction)

