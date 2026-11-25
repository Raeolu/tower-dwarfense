extends PlayerState

func enter():
	if player.anim_player != null:
		player.anim_player.play("FALLING", 0.4)

func physics_update(delta: float) -> void:
	# Faster falling
	player.apply_gravity(delta, player.fall_gravity_multiplier)

	player.apply_horizontal_movement(delta)
	player.rotate_to_direction(player.direction)

	# Coyote time jump: look at miro for more info
	if Input.is_action_just_pressed("jump") and player.coyote_timer > 0.0:
		transition.emit("Jump")
		return

	# Wall jump when touching a wall in the air.
	if player.is_on_wall() and Input.is_action_just_pressed("jump"):
		transition.emit("WallJump")
		return

	if Input.is_action_just_pressed("attack"):
		transition.emit("Attack")
		return

	if Input.is_action_just_pressed("bash") and player.can_dash and player.direction != Vector3.ZERO:
		transition.emit("Dash")
		return

	# Land on the floor.
	if player.is_on_floor():
		if player.direction != Vector3.ZERO:
			transition.emit("Walking")
		else:
			transition.emit("Idle")
		return
