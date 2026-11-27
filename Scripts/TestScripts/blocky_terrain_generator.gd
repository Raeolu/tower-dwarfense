@tool
class_name BlockyTerrain
extends Node3D

## Simple blocky terrain.
##
## The map is a grid of square cells. Every cell gets one of three heights:
##   -1 = hole      0 = ground      1 = platform
## The spawn in the middle and every path are always ground.
##
## Paths: add a Path3D as a child of this node and click points on it with the curve tool.
##
## How it works:
##   1. pick_heights()  decides the height of every cell (noise, paths, spawn)
##   2. build_mesh()    draws every cell as a flat square, plus a wall on each side that drops down


# ============================================================ settings (Inspector)

@export_tool_button("New random map") var new_map_button := new_map
@export_tool_button("Smooth all paths") var smooth_paths_button := smooth_paths

@export_group("Size")
@export var cells_per_side := 80
@export var cell_size := 2.0                 ## metres

@export_group("Heights")
@export var platform_height := 5.0           ## metres up
@export var hole_depth := 0.75               ## metres down (lower than the jump, so you can climb out)
@export var island_depth := 8.0              ## how far the edge of the island goes down

@export_group("Noise")
@export var noise: FastNoiseLite
@export var world_seed := 0                  ## 0 = a random map every time
@export_range(-1.0, 1.0) var hole_below := -0.25      ## noise lower than this = hole
@export_range(-1.0, 1.0) var platform_above := 0.25   ## noise higher than this = platform

@export_group("Flat areas")
@export var spawn_radius := 10.0             ## metres of flat ground around the middle
@export var path_width := 4.0                ## width of the dirt
@export var path_flat_width := 8.0           ## width of the flat ground around a path

@export_group("Colours")
@export var color_ground := Color(0.36, 0.62, 0.26)
@export var color_platform := Color(0.55, 0.72, 0.34)
@export var color_hole := Color(0.27, 0.5, 0.22)
@export var color_path := Color(0.56, 0.44, 0.29)
@export var color_spawn := Color(0.5, 0.47, 0.42)
@export var color_rock_wall := Color(0.5, 0.5, 0.52)

@export_group("Ores")
@export var ore_scene: PackedScene
@export_range(0.0, 100.0, 0.1, "suffix:%") var ore_chance := 2.0   ## chance per cell
var _ore_container: Node3D


# ============================================================ data

var heights := {}       # Vector2i(x, z) -> -1, 0 or 1
var path_cells := {}    # Vector2i(x, z) -> true, for cells drawn as dirt
var near_path_cells := {}   # Vector2i(x, z) -> true, for the flat ground around a path (includes the dirt)
var spawn_cells := {}       # Vector2i(x, z) -> true, for the flat spawn area in the middle
var path_distances := {}    # Vector2i(x, z) -> metres to the closest path (only cells close to a path)
var map_noise: FastNoiseLite   # the noise used for this map (already has the map seed)

var _seed := 0
var _mesh_instance: MeshInstance3D
var _rebuild_planned := false


# ============================================================ start

func _ready() -> void:
	add_to_group("terrain")
	new_map()


## Makes a completely new map (new random seed).
func new_map() -> void:
	_seed = world_seed if world_seed != 0 else randi()
	rebuild()


## Builds the map again with the same seed (for example after you moved a path point).
func rebuild() -> void:
	_rebuild_planned = false
	set_process(true)
	watch_paths()
	pick_heights()
	place_ores()
	build_mesh()


# ============================================================ step 1: heights

func pick_heights() -> void:
	heights.clear()
	path_cells.clear()
	near_path_cells.clear()
	spawn_cells.clear()

	# A copy of the noise, so changing the seed does not change the noise saved in the scene.
	map_noise = noise.duplicate() if noise else FastNoiseLite.new()
	map_noise.seed = _seed

	path_distances = measure_path_distances()

	for x in cells_per_side:
		for z in cells_per_side:
			var cell := Vector2i(x, z)
			var center := cell_center(cell)
			var distance_to_path: float = path_distances.get(cell, INF)   # INF = far from every path

			if distance_to_path < path_width / 2.0:
				path_cells[cell] = true

			var in_spawn := center.length() < spawn_radius
			var near_path := distance_to_path < path_flat_width / 2.0
			if in_spawn:
				spawn_cells[cell] = true
			if near_path:
				near_path_cells[cell] = true
			if in_spawn or near_path:
				heights[cell] = 0
				continue

			var value := map_noise.get_noise_2d(center.x, center.z)   # a number from -1 to 1
			if value < hole_below:
				heights[cell] = -1
			elif value > platform_above:
				heights[cell] = 1
			else:
				heights[cell] = 0


# ============================================================ step 2: mesh

func build_mesh() -> void:
	# Remove the old terrain first.
	if is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := cell_size / 2.0

	for cell in heights:
		var top := height_in_metres(heights[cell])
		var c := cell_center(cell)

		# The flat top of the cell.
		add_square(st,
				Vector3(c.x - half, top, c.z - half), Vector3(c.x + half, top, c.z - half),
				Vector3(c.x + half, top, c.z + half), Vector3(c.x - half, top, c.z + half),
				Vector3.UP, cell_color(cell))

		# A wall on every side where the neighbour is lower.
		for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbour: Vector2i = cell + direction
			var bottom := -island_depth                     # outside the map
			if heights.has(neighbour):
				bottom = height_in_metres(heights[neighbour])
			if bottom >= top:
				continue

			var out := Vector3(direction.x, 0, direction.y)  # points from this cell to the neighbour
			var along := Vector3(-out.z, 0, out.x)           # runs along the edge
			var edge := c + out * half
			var left := edge - along * half
			var right := edge + along * half
			add_square(st,
					Vector3(left.x, top, left.z), Vector3(right.x, top, right.z),
					Vector3(right.x, bottom, right.z), Vector3(left.x, bottom, left.z),
					out, color_rock_wall)

	# One material for everything: the colour comes from each corner (vertex colour).
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	st.set_material(material)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	_mesh_instance.mesh = st.commit()
	_mesh_instance.add_to_group("NavSource")
	add_child(_mesh_instance)
	_mesh_instance.create_trimesh_collision()   # makes the same triangles solid
	var body := _mesh_instance.get_child(0) as StaticBody3D
	body.set_collision_layer_value(5, true)


## Adds a square (two triangles) to the mesh. `facing` is the direction the square looks at.
## The corners just have to go around the square; the order is fixed here so it is never invisible.
func add_square(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, facing: Vector3, color: Color) -> void:
	if (b - a).cross(c - a).dot(facing) > 0.0:
		var swap := b
		b = d
		d = swap
	for corner in [a, b, c, a, c, d]:
		st.set_normal(facing)
		st.set_color(color)
		st.add_vertex(corner)


func cell_color(cell: Vector2i) -> Color:
	if cell_center(cell).length() < spawn_radius:
		return color_spawn
	if path_cells.has(cell):
		return color_path
	match heights[cell]:
		1: return color_platform
		-1: return color_hole
		_: return color_ground


# ============================================================ paths

## Every Path3D child, copied with all heights set to 0,
## so distances are measured along the ground and not through the air.
func get_flat_paths() -> Array[Curve3D]:
	var result: Array[Curve3D] = []
	for child in get_children():
		if not (child is Path3D) or child.curve == null or child.curve.point_count < 2:
			continue
		var flat := Curve3D.new()
		for i in child.curve.point_count:
			# Use the whole transform, so moved AND rotated paths end up in the right place.
			# Handles are directions, so they only get rotated (basis), not moved.
			var point: Vector3 = child.transform * child.curve.get_point_position(i)
			var handle_in: Vector3 = child.transform.basis * child.curve.get_point_in(i)
			var handle_out: Vector3 = child.transform.basis * child.curve.get_point_out(i)
			point.y = 0
			handle_in.y = 0
			handle_out.y = 0
			flat.add_point(point, handle_in, handle_out)
		result.append(flat)
	return result


## Gives every point of every path handles, so the path bends smoothly through its points
## instead of making sharp corners. Each handle points from the previous point towards the next one.
## You can still fine-tune a handle by hand afterwards.
func smooth_paths() -> void:
	for child in get_children():
		if not (child is Path3D) or child.curve == null:
			continue
		var curve: Curve3D = child.curve
		var last := curve.point_count - 1
		for i in curve.point_count:
			var before := curve.get_point_position(maxi(i - 1, 0))
			var after := curve.get_point_position(mini(i + 1, last))
			var handle := (after - before) * 0.25   # bigger number = wider bends
			curve.set_point_in(i, -handle)
			curve.set_point_out(i, handle)


## Walks along every path in small steps and, at each step, measures the squares around it.
## Returns { square: metres to the path }, only for squares close to a path.
## (Much faster than asking every square of the map how far the path is.)
func measure_path_distances() -> Dictionary:
	var result := {}
	var reach := ceili(path_flat_width / 2.0 / cell_size) + 1   # how many squares around each step
	for path in get_flat_paths():
		path.bake_interval = cell_size / 2.0                     # one step every half square
		for step in path.get_baked_points():
			var step_cell := cell_at(step)
			for dx in range(-reach, reach + 1):
				for dz in range(-reach, reach + 1):
					var cell := step_cell + Vector2i(dx, dz)
					var distance := cell_center(cell).distance_to(step)
					if distance < result.get(cell, INF):
						result[cell] = distance
	return result


## Rebuild the map whenever a path is added, removed or changed.
func watch_paths() -> void:
	if not child_entered_tree.is_connected(_on_child_changed):
		child_entered_tree.connect(_on_child_changed)
		child_exiting_tree.connect(_on_child_changed)
	for child in get_children():
		if child is Path3D and not child.curve_changed.is_connected(plan_rebuild):
			child.curve_changed.connect(plan_rebuild)


func _on_child_changed(child: Node) -> void:
	if child is Path3D:
		plan_rebuild()


## A path changed: remember that the map has to be rebuilt. _process() does the actual rebuild.
func plan_rebuild() -> void:
	_rebuild_planned = true
	set_process(true)   # make sure _process() runs, also right after the editor reloaded this script


## Rebuilds only once the left mouse button is let go, so dragging a path point stays smooth
## and the terrain updates once when you drop the point.
func _process(_delta: float) -> void:
	if _rebuild_planned and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		rebuild()


# ============================================================ helpers

## Height level (-1, 0, 1) -> metres.
func height_in_metres(level: int) -> float:
	match level:
		1: return platform_height
		-1: return -hole_depth
		_: return 0.0


## The middle of a cell, in metres. The map is centred on this node.
func cell_center(cell: Vector2i) -> Vector3:
	var map_half := cells_per_side * cell_size / 2.0
	return Vector3((cell.x + 0.5) * cell_size - map_half, 0, (cell.y + 0.5) * cell_size - map_half)


## Which cell a position is in.
func cell_at(pos: Vector3) -> Vector2i:
	var map_half := cells_per_side * cell_size / 2.0
	return Vector2i(floori((pos.x + map_half) / cell_size), floori((pos.z + map_half) / cell_size))


## Ground height (metres) at a position. Use it to place turrets, trees, enemies.
func height_at(pos: Vector3) -> float:
	return height_in_metres(heights.get(cell_at(pos), 0))


## True when a position is on the dirt of a path (for example to forbid building there).
func is_on_path(pos: Vector3) -> bool:
	return path_cells.has(cell_at(pos))
	
func place_ores():
	
	if is_instance_valid(_ore_container):
		_ore_container.queue_free()
	_ore_container = Node3D.new()
	_ore_container.name = "Ores"
	add_child(_ore_container)

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	
	for x in cells_per_side:
		for z in cells_per_side:
			var cell := Vector2i(x, z)
			
			if cell in spawn_cells or cell in near_path_cells:
				continue

			# Only on normal ground (level 0), not on platforms (1) or in holes (-1).
			if heights[cell] != 0:
				continue

			if rng.randf() < ore_chance / 100.0:
				var ore := ore_scene.instantiate()
				ore.position = cell_center(cell)
				ore.position.y = height_in_metres(heights[cell]) + 0.3
				_ore_container.add_child(ore)
