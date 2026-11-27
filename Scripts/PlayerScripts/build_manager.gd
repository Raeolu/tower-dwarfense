extends Node3D
@export var camera: Camera3D
@export var cannon_turret: PackedScene
@export var turret_preview_scene: PackedScene
@export var turret_cost: int = 3

@onready var build_raycast = $BuildRaycast
@onready var build_area_check = $BuildAreaCheck

var build_mode = false
var ghost_turret: Node3D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build_mode"):
		if build_mode:
			exit_build_mode()
		else:
			start_build_mode()
	
	if !build_mode:
		return
	
	update_preview_position()
	update_build_raycast_and_area_position()
	
	if Input.is_action_just_pressed("attack"):
		place_turret()

func start_build_mode():
	build_mode = true
	ghost_turret = turret_preview_scene.instantiate()
	add_child(ghost_turret)

func exit_build_mode():
	build_mode = false
	if ghost_turret:
		ghost_turret.queue_free()
		ghost_turret = null

func update_build_raycast_and_area_position():
	build_raycast.global_position = get_mouse_ground_position() + Vector3(0, .5, 0)
	build_area_check.global_position = get_mouse_ground_position() + Vector3(0, .5, 0)

func place_turret():
	#if can_place returns a negative value, dont place turret
	if !can_place():
		return
	
	#CHECK IF PLAYER HAS ENOUGH MONEY
	if ResourceManager.gold < turret_cost:
		print("NOT ENOUGH GOLD")
		return
	
	#TAKE THE GOLD FROM THE RESOURCE MANAGER
	ResourceManager.adjust_gold(-turret_cost)
	
	#ADD THE TURRET TO THE SCENE
	var turret = cannon_turret.instantiate()
	turret.position = get_mouse_ground_position()
	get_tree().current_scene.add_child(turret)

func can_place():
	if build_raycast.is_colliding():
		var colliding_surface = build_raycast.get_collider()
		if colliding_surface.get_collision_layer_value(5):
			if build_area_check.get_overlapping_bodies().is_empty():
				return true
	
	return false

func update_preview_position():
	if !ghost_turret:
		return
	
	var hit_position = get_mouse_ground_position()
	
	if hit_position == Vector3.ZERO:
		return
	ghost_turret.global_position = hit_position
	
	update_preview_color()

func update_preview_color():
	var valid = can_place()
	set_preview_material_color(Color.GREEN if valid else Color.RED)

func set_preview_material_color(color: Color):
	var mesh_instances = ghost_turret.find_children("*", "MeshInstance3D")
	
	for Mesh in mesh_instances:
		var mat = Mesh.material_override
		
		if mat == null:
			mat = StandardMaterial3D.new()
			Mesh.material_override = mat
		
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.5

func get_mouse_ground_position() -> Vector3:
	# With a captured mouse we aim from the middle of the screen.
	var mouse_pos = get_viewport().get_mouse_position()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_pos = get_viewport().get_visible_rect().size / 2

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000.0)
	query.exclude = [get_parent().get_rid()]   # don't hit our own player
	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		return result.position
	return Vector3.ZERO
	
	if result:
		return result.position
	
	return Vector3.ZERO
