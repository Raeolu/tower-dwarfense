extends PlayerState


func physics_update(delta: float):
	if not player.is_on_floor():
		transition.emit("Fall")
		return

	if Input.is_action_just_pressed("jump"):
		transition.emit("Jump")
		return

	if Input.is_action_just_pressed("attack"):
		transition.emit("Attack")
		return

	if Input.is_action_just_pressed("bash") and player.can_dash and player.direction != Vector3.ZERO:
		transition.emit("Dash")
		return

	if player.direction != Vector3.ZERO:
		transition.emit("Walking")
		return

	# Smoothly deceleratie in plaats van direct stoppen
	player.apply_horizontal_movement(delta)
