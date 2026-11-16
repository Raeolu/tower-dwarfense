extends PlayerState

var jump_cut_applied: bool = false
var control_lock_timer: float = 0.0


func enter() -> void:
	jump_cut_applied = false
	player.coyote_timer = 0.0
	control_lock_timer = player.wall_jump_control_lock_time

	# Push away from the wall normal and boost upward.
	var wall_normal: Vector3 = player.get_wall_normal()
	var push_dir := Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()

	player.velocity.x = push_dir.x * player.wall_jump_pushback
	player.velocity.z = push_dir.z * player.wall_jump_pushback
	player.velocity.y = player.wall_jump_velocity

	player.rotate_to_direction(push_dir)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)

	# Variable jump height depending on how long you hold jump
	if not Input.is_action_pressed("jump") and not jump_cut_applied and player.velocity.y > 0.0:
		player.velocity.y *= player.jump_cut_multiplier
		jump_cut_applied = true

	# Zodat speler niet direct weer tegen de muur springt
	if control_lock_timer > 0.0:
		control_lock_timer = max(0.0, control_lock_timer - delta)
	else:
		player.apply_horizontal_movement(delta)
		player.rotate_to_direction(player.direction)

	if not player.is_on_floor() and player.is_on_wall() and Input.is_action_just_pressed("jump"):
		transition.emit("WallJump")
		return

	if Input.is_action_just_pressed("attack"):
		transition.emit("Attack")
		return

	if Input.is_action_just_pressed("bash") and player.can_dash and player.direction != Vector3.ZERO:
		transition.emit("Dash")
		return

	# Transition to Fall when reaching the top of the jump.
	if player.velocity.y <= 0.0:
		transition.emit("Fall")
		return
