extends PlayerState


func update(_delta: float):
	#transition to the walking state when a the player script receives a direction
	if player.direction:
		transition.emit("Walking")

func physics_update(_delta: float):
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	#player.velocity = player.direction * player.SPEED
	
	if Input.is_action_just_pressed("attack"):
		transition.emit("attack")
	
