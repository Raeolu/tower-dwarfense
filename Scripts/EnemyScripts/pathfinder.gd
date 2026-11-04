extends Node3D
@onready var nav_agent = $"../NavigationAgent3D"
@onready var char_body_3d = $".."
@onready var player


@export var default_speed = 3.0
var speed = 100000.0
@export var turnspeed = 3.0
var look_at_player = true
@export var can_move = true
var target_y_rot : float


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	speed = default_speed
	velocity_computed()


func _physics_process(delta: float) -> void:
	#if not char_body_3d.is_on_floor() and char_body_3d.velocity.y > 0:
	#	char_body_3d.velocity = (char_body_3d.velocity + char_body_3d.get_gravity()) * delta
	
	if can_move == false:
		return
	
	nav_agent.target_position = player.position
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	nav_agent.set_velocity(new_velocity)
	var player_pos = player.global_transform.origin
	var distance = self.global_transform.origin.distance_to(player_pos)
	if distance < 2.3:
		speed = 0.001
		char_body_3d.in_range = true
	else:
		speed = default_speed
		char_body_3d.in_range = false
	
	#rotate_character()
	
	if char_body_3d.is_on_floor() == false and char_body_3d.velocity.y < 0:
		char_body_3d.velocity.y += char_body_3d.get_gravity().y * delta
	




func rotate_character():
	if look_at_player == true:
		$FaceDirection.look_at(player.position, Vector3.UP)
		char_body_3d.rotate_y(deg_to_rad($FaceDirection.rotation.y*turnspeed))
		#var player_dir = player.position - char_body_3d.position
		#target_y_rot = atan2(player_dir.x, player_dir.z)
	#elif char_body_3d.velocity.length() > 0:
		#target_y_rot = atan2(char_body_3d.velocity.x, char_body_3d.velocity.z)
	#char_body_3d.rotation.y = lerp_angle(rotation.y, target_y_rot, 0.1)


func velocity_computed():
	#this function basically just checks the velocity_computed signal from the NavigationAgent3D, 
	#and returns the safe_velocity to the on_velocity_computed function
	nav_agent.velocity_computed.connect(on_velocity_computed)

func on_velocity_computed(safe_velocity):
	char_body_3d.velocity = char_body_3d.velocity.move_toward(safe_velocity, .25)
	char_body_3d.move_and_slide()
