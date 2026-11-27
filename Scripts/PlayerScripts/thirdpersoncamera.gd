extends Node3D
## Third person camera.
## CameraPivot (this node) turns left/right, SpringArm3D tilts up/down.

@export var mouse_sensitivity := 0.003
@export var min_pitch := -70.0   ## degrees, looking down
@export var max_pitch := 10.0    ## degrees, looking up
@export var min_zoom := 2.0
@export var max_zoom := 10.0
@export var zoom_step := 0.5

@onready var spring_arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Don't let the camera bump into our own player capsule.
	spring_arm.add_excluded_object(get_parent().get_rid())


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Left/right: turn the whole pivot.
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Up/down: tilt the spring arm, with a limit so you can't flip over.
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_step, min_zoom, max_zoom)
