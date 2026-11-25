extends PlayerState

@export var attack_move_speed_factor = 0.5
@export var attack_duration = 1.0
@export var attack_damage = 5

@onready var attack_test_mesh = $"../../Visuals/AttackTestMesh"
@onready var pickaxe_hitbox = $"../../Visuals/dwarf/Armature/Skeleton3D/BoneAttachment3D/PickaxeHitbox"
@onready var hitbox = $"../../Visuals/AttackArea"


var is_signal_connected = false


func enter():
	pickaxe_hitbox.monitoring = true
	if player.anim_player != null:
		player.anim_player.play("ATTACK", 0.1)
		if is_signal_connected == false: #this connects the anim_player signal to the _on_animation_finished function
			player.anim_player.animation_finished.connect(_on_animation_finished)
			is_signal_connected = true


func exit():
	pickaxe_hitbox.monitoring = false



func physics_update(delta: float):
	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta, attack_move_speed_factor)
	player.rotate_to_direction(player.direction)

func _on_animation_finished(anim_name: StringName) -> void:
	if player.is_on_floor():
		transition.emit("Idle")
	else:
		transition.emit("Fall")

func _on_attack_area_body_entered(body: Node3D) -> void: #this function is called when the animation finishes
	if body.is_in_group("enemy") or body.is_in_group("resource"):
		body.take_damage(attack_damage)


func _on_pickaxe_hitbox_body_entered(body: Node3D) -> void:
	if $"..".current_state == $".": #Lees: als state_machine.current_state == this state.
		if body.is_in_group("enemy") or body.is_in_group("resource"):
			body.take_damage(attack_damage)
