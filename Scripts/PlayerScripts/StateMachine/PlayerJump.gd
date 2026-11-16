extends PlayerState

var jump_cut_applied: bool = false


func enter() -> void:
	jump_cut_applied = false
	player.coyote_timer = 0.0
	player.velocity.y = player.jump_velocity


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	# Variable jump height dependign on how long you hold jump
	if not Input.is_action_pressed("jump") and not jump_cut_applied and player.velocity.y > 0.0:
		player.velocity.y *= player.jump_cut_multiplier
		jump_cut_applied = true

	player.apply_horizontal_movement(delta)
	player.rotate_to_direction(player.direction)

	# Wall jump if touching a wall in mid-air
	if not player.is_on_floor() and player.is_on_wall() and Input.is_action_just_pressed("jump"):
		transition.emit("WallJump")
		return

	if Input.is_action_just_pressed("attack"):
		transition.emit("Attack")
		return

	if Input.is_action_just_pressed("bash") and player.can_dash and player.direction != Vector3.ZERO:
		transition.emit("Dash")
		return

	# Transition to Fall when at top of jump
	if player.velocity.y <= 0.0:
		transition.emit("Fall")
		return
