class_name TerrainGeneration
extends Node

var mesh : MeshInstance3D
var size_depth : int = 1000
var size_width : int = 1000
var mesh_resolution : float = 0.2

@export var max_height: float = 16.0
@export var step_height: float = 4.0
@export var slope_start: float = 0.35
@export var slope_end: float = 0.65

@export var noise : FastNoiseLite

func _ready() -> void:
	generate()

func generate():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size_width, size_depth)
	plane_mesh.subdivide_depth = int(size_depth * mesh_resolution)
	plane_mesh.subdivide_width = int(size_width * mesh_resolution)
	plane_mesh.material = preload("res://Assets/Terrain Generation/TerrainMaterial.tres")
	
	var surface = SurfaceTool.new()
	var data = MeshDataTool.new()
	surface.create_from(plane_mesh, 0)
	
	var array_plane = surface.commit()
	data.create_from_surface(array_plane, 0)
	
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		
		var y = get_noise_y(vertex.x, vertex.z)
		vertex.y = y
		
		data.set_vertex(i, vertex)
		
	array_plane.clear_surfaces()
	
	data.commit_to_surface(array_plane)
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_plane, 0)
	surface.deindex()
	surface.generate_normals()
	
	mesh  = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mesh.add_to_group("NavSource")
	add_child(mesh)
	
func get_noise_y(x, z) -> float:
	var height = noise.get_noise_2d(x, z) * max_height

	var level = floor(height / step_height)
	var fraction = fposmod(height, step_height) / step_height

	var slope = smoothstep(slope_start, slope_end, fraction)

	return (level + slope) * step_height
