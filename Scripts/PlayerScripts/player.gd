extends CharacterBody3D
class_name Player

const SPEED = 6.0
const JUMP_VELOCITY = 4.5

var direction = Vector3(0, 0, 0)

var can_dash = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	move_and_slide()


func rotate_to_direction(direction):
	if direction:
		$Visuals/FaceDirection.look_at(position + direction)
		$Visuals.rotate_y(deg_to_rad($Visuals/FaceDirection.rotation.y * 10))
