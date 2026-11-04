extends PlayerState

@export var dash_velocity = 20.0
@export var dash_duration = 0.2
@export var dash_direction_influence_multiplier = 1.0

var dash_direction = Vector3(0,0,0)

func enter():
	dash_direction = player.direction
	player.velocity = dash_direction * dash_velocity
	
	#sets the state back to idle after the dash duration
	await get_tree().create_timer(dash_duration).timeout
	transition.emit("Idle")
	

func physics_update(_delta: float):
	print(player.direction)
	#player.velocity.x = player.velocity.x * (player.direction.x * dash_direction_influence_multiplier)
	#player.velocity.y = player.velocity.y * (player.direction.y * dash_direction_influence_multiplier)
	player.velocity.y = 0.0
	
	#rotates the player to the direction. Check the player script for more info.
	player.rotate_to_direction(player.velocity)
