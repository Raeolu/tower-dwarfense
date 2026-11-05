extends StaticBody3D

var current_target = null
var can_shoot = true
var projectile = preload("res://Scenes/Projectiles/cannonball.tscn")

@onready var turret_base = $basic_turret/Base
@onready var turret_superstructure = $basic_turret/Superstructure

@export var range: Area3D
@export var rotation_speed = 3.0
@export var projectile_spawn_position:Node3D
@export var projectile_force = 18

func _physics_process(delta: float) -> void:
	if current_target != null:
		rotate_towards_target(delta)
		check_if_target_is_still_in_range()
		if can_shoot:
			instantiate_projectile()
			start_cooldown()
	
	else:
		get_new_target()

func instantiate_projectile():
	var instancedProjectile = projectile.instantiate()
	instancedProjectile.position = projectile_spawn_position.global_position
	get_tree().current_scene.add_child(instancedProjectile)
	var current_rotation = turret_superstructure.global_transform.basis.z.normalized()
	instancedProjectile.apply_central_impulse(current_rotation * projectile_force *-1)

func start_cooldown():
	can_shoot = false
	await get_tree().create_timer(0.5).timeout
	can_shoot = true

func check_if_target_is_still_in_range():
	var targets_in_range = range.get_overlapping_bodies()
	if targets_in_range.has(current_target):
		return
	else:
		current_target = null

func get_new_target():
	var possible_targets = range.get_overlapping_bodies()
	var shortest_distance = INF
	
	for obj in possible_targets:
		if obj.is_in_group("enemy"):
			var distance = global_position.distance_to(obj.global_position)
			
			if distance < shortest_distance:
				shortest_distance = distance
				current_target = obj
	
	return current_target



func rotate_towards_target(delta):
	var target_pos = current_target.global_position
	target_pos.y = global_position.y
	
	var direction = (target_pos - global_position).normalized()
	if direction == Vector3.ZERO:
		return
	
	var target_angle = atan2(-direction.x, -direction.z)
	
	turret_superstructure.rotation.y = rotate_toward(turret_superstructure.rotation.y, target_angle, delta * rotation_speed)
