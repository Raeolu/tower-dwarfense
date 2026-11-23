extends CharacterBody3D
class_name Player

@export var speed: float = 6.0
@export var ground_acceleration: float = 30.0
@export var ground_deceleration: float = 24.0
@export var air_acceleration: float = 18.0
@export var air_deceleration: float = 8.0
## Extra acceleration multiplier when turning against current momentum
@export var turn_acceleration_multiplier: float = 2.0

@export var jump_velocity: float = 6.0
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.5
## Gravity multiplier applied while falling so descent feels less floaty.
@export var fall_gravity_multiplier: float = 1.4
## Grace time (in seconds) after walking off a ledge during which the player can still jump.
@export var coyote_time: float = 0.15

@export var wall_jump_velocity: float = 6.0
@export var wall_jump_pushback: float = 7.0
@export var wall_jump_control_lock_time: float = 0.15

var direction: Vector3 = Vector3.ZERO
var can_dash: bool = true
## See miro for Celeste example
var coyote_timer: float = 0.0


func _physics_process(delta: float) -> void:
	# Update coyote timer based on floor state.
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Get the input direction.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	direction = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	move_and_slide()


func apply_gravity(delta: float, gravity_multiplier: float = 1.0) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravity_multiplier * delta


func apply_horizontal_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var current_horizontal := Vector2(velocity.x, velocity.z)
	var target_horizontal := Vector2(direction.x, direction.z) * (speed * speed_multiplier)

	var accel_rate: float
	if direction != Vector3.ZERO:
		accel_rate = ground_acceleration if is_on_floor() else air_acceleration
		# Extra acceleratie als je omkeert
		if current_horizontal.length_squared() > 0.1 and current_horizontal.dot(target_horizontal) < 0.0:
			accel_rate *= turn_acceleration_multiplier
	else:
		accel_rate = ground_deceleration if is_on_floor() else air_deceleration

	var new_horizontal := current_horizontal.move_toward(target_horizontal, accel_rate * delta)
	velocity.x = new_horizontal.x
	velocity.z = new_horizontal.y


func rotate_to_direction(direction):
	if direction:
		$Visuals/FaceDirection.look_at(position + direction)
		$Visuals.rotate_y(deg_to_rad($Visuals/FaceDirection.rotation.y * 10))
