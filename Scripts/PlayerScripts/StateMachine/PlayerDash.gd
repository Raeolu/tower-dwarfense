extends PlayerState

@export var dash_velocity = 20.0
@export var dash_duration = 0.2
@export var dash_cooldown = 0.5
@export var dash_direction_influence_multiplier = 1.0

var dash_direction = Vector3(0,0,0)

#DASH ATTACK STUFF
@onready var pickaxe_hitbox = $"../../Visuals/dwarf/Armature/Skeleton3D/BoneAttachment3D/PickaxeHitbox"
@export var dash_attack_damage = 10.0
var is_signal_connected = false

func enter():
	pickaxe_hitbox.monitoring = true
	player.coyote_timer = 0.0
	dash_direction = player.direction
	player.velocity = dash_direction * dash_velocity
	start_dash_cooldown()
	
	if player.anim_player != null:
		player.anim_player.play("DASH", 0.1)
		if is_signal_connected == false: #this connects the anim_player signal to the _on_animation_finished function
			player.anim_player.animation_finished.connect(_on_animation_finished)
			is_signal_connected = true
	
	#sets the state back to idle after the dash duration
	#await get_tree().create_timer(dash_duration).timeout
	#if player.is_on_floor():
		#transition.emit("Idle")
	#else:
		#transition.emit("Fall")

func exit():
	pickaxe_hitbox.monitoring = false

func physics_update(_delta: float):
	#player.velocity.x = player.velocity.x * (player.direction.x * dash_direction_influence_multiplier)
	#player.velocity.y = player.velocity.y * (player.direction.y * dash_direction_influence_multiplier)
	player.velocity.y = 0.0

	#rotates the player to the direction. Check the player script for more info.
	player.rotate_to_direction(player.velocity)


func start_dash_cooldown():
	player.can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	player.can_dash = true

func _on_animation_finished(anim_name: StringName) -> void:
	if player.is_on_floor():
		transition.emit("Idle")
	else:
		transition.emit("Fall")

func _on_pickaxe_hitbox_body_entered(body: Node3D) -> void:
	if $"..".current_state == $".": #Lees: als state_machine.current_state == this state.
		if body.is_in_group("enemy") or body.is_in_group("resource"):
			body.take_damage(dash_attack_damage)
