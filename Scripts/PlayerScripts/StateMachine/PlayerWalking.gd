extends PlayerState

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	#Sets the state to idle if no direction is currently being given by the player script.
	if !player.direction:
		transition.emit("Idle")

func physics_update(_delta: float):
	#if a direction is found in the player script, move the player
	if player.direction:
		player.velocity.x = player.direction.x * player.SPEED
		player.velocity.z = player.direction.z * player.SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	
	if Input.is_action_just_pressed("attack"):
		transition.emit("attack")
	
	elif Input.is_action_just_pressed("bash") and player.can_dash == true:
		transition.emit("Dash")
		
		
	
	#rotates the player to the direction. Check the player script for more info.
	player.rotate_to_direction(player.direction)
	
