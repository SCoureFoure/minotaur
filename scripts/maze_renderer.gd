extends Node3D
class_name MazeRenderer
# Turns a MazeGenerator grid into 3D geometry + collision.
# v1 renders sized box primitives (reliable collision, headless-testable).
# Cave-mesh skinning hooks into _make_wall_visual / _make_floor_visual later.

@export var cols: int = 12
@export var rows: int = 12
@export var maze_seed: int = 0          # 0 => randomized each run
@export var braid: float = 0.4          # 0 = perfect maze, 1 = max loops
@export var cell_size: float = 4.0      # world units per grid square
@export var wall_height: float = 3.0
@export var build_on_ready: bool = true
# Calibration: skip the maze, lay candidate cave meshes in a labeled row next to
# a 1m reference cube so scale/pivot/orientation can be read by eye (F5). Visual
# probe for the cave-skinning autotile — not the final render.
@export var cave_calibration: bool = false
# Volume: stacked multi-layer maze (MazeVolume) with vertical ramp links instead
# of a single flat grid. First pass = box geometry, layer-colored, link markers.
@export var use_volume: bool = false
@export var layers: int = 3
@export var level_height: float = 3.0   # world-Y drop per descent level (ramp = atan(h/cell))
@export var links_per_pair: int = 3     # vertical links carved per adjacent pair
# Sizing: when auto_size_from_players is on, player_count drives cols/rows/layers
# (see size_for_players) so a small lobby = a small, fast-to-test maze.
@export var player_count: int = 4
@export var auto_size_from_players: bool = true
# Surface island: a solid grass-topped landmass at Y=0 covering the maze footprint,
# ringed by water. `entrance_count` holes drop ramps down into the first maze level.
@export var entrance_count: int = 3
@export var water_level: float = -0.6

var grid: Array = []
var grid_w: int = 0
var grid_h: int = 0
var volume: Dictionary = {}   # {grids, links} when use_volume

func _ready() -> void:
	if build_on_ready:
		build()

func build() -> void:
	for c in get_children():
		c.queue_free()

	if cave_calibration:
		_build_calibration()
		return

	if use_volume:
		_build_volume()
		return

	if maze_seed == 0:
		maze_seed = randi()
	grid = MazeGenerator.generate(cols, rows, maze_seed, braid)
	grid_h = grid.size()
	grid_w = grid[0].size()

	_spawn_floor()
	for y in range(grid_h):
		for x in range(grid_w):
			if grid[y][x] == 0:
				_spawn_wall(x, y)

# World-space center of grid square (x,y) at floor level.
func _cell_world(x: int, y: int, y_height: float) -> Vector3:
	return Vector3(x * cell_size, y_height, y * cell_size)

func _spawn_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"
	var size := Vector3(grid_w * cell_size, 1.0, grid_h * cell_size)
	var center := Vector3((grid_w - 1) * 0.5 * cell_size, -0.5, (grid_h - 1) * 0.5 * cell_size)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = center
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = center
	body.add_child(col)
	add_child(body)

func _spawn_wall(x: int, y: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Wall_%d_%d" % [x, y]
	var pos := _cell_world(x, y, wall_height * 0.5)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(cell_size, wall_height, cell_size)
	mesh.mesh = box
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cell_size, wall_height, cell_size)
	col.shape = shape
	body.add_child(col)

	body.position = pos
	add_child(body)

# --- Cave-mesh calibration probe -------------------------------------------
# Each cave piece is placed at identity scale, 3m apart, at y=0, with a floating
# name label. A 1m reference cube sits at the left end. Walk the row (F5) and
# report: real size vs the 1m cube, where the pivot sits, which way it faces.
const _CALIB_MESHES := [
	"Cave_Terrain_Floor_Normal (2)",
	"Cave_Terrain_Floor_Raised (2)",
	"Cave_Terrain_Side_Base (2)",
	"Cave_Terrain_Side_Mid (2)",
	"Cave_Terrain_Side_Top (2)",
	"Cave_Terrain_Corner_Inner_1x1_Base (2)",
	"Cave_Terrain_Corner_Outer_1x1_Base (2)",
]

func _build_calibration() -> void:
	# Ground slab so the player has something to stand on (top at y=0).
	var ground := StaticBody3D.new()
	ground.name = "CalibGround"
	var gsize := Vector3(40.0, 1.0, 40.0)
	var gcenter := Vector3(8.0, -0.5, 6.0)
	var gmesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = gsize
	gmesh.mesh = gbox
	gmesh.position = gcenter
	gmesh.material_override = _calib_mat(Color(0.18, 0.18, 0.20))
	ground.add_child(gmesh)
	var gcol := CollisionShape3D.new()
	var gshape := BoxShape3D.new()
	gshape.size = gsize
	gcol.shape = gshape
	gcol.position = gcenter
	ground.add_child(gcol)
	add_child(ground)

	var ref := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	ref.mesh = cube
	ref.position = Vector3(-3.0, 0.5, 0.0)
	ref.material_override = _calib_mat(Color.WHITE)
	add_child(ref)
	add_child(_calib_label("1m REF CUBE", Vector3(-3.0, 1.8, 0.0)))

	# Distinct color per piece so a screenshot is legible.
	var colors := [
		Color(0.20, 0.80, 0.30),  # Floor_Normal   green
		Color(0.55, 0.95, 0.45),  # Floor_Raised   light green
		Color(0.20, 0.55, 0.95),  # Side_Base      blue
		Color(0.30, 0.75, 0.95),  # Side_Mid       cyan
		Color(0.55, 0.45, 0.95),  # Side_Top       violet
		Color(0.95, 0.55, 0.20),  # Corner_Inner   orange
		Color(0.95, 0.25, 0.25),  # Corner_Outer   red
	]
	var x := 0.0
	var i := 0
	for n in _CALIB_MESHES:
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/terrain/%s.obj" % n)
		mi.position = Vector3(x, 0.0, 0.0)
		mi.name = n
		mi.material_override = _calib_mat(colors[i])
		add_child(mi)
		add_child(_calib_label(n.replace(" (2)", ""), Vector3(x, 2.2, 0.0)))
		x += 3.0
		i += 1

func _calib_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

# Shared lush-green gradient used by both the island ground material and the
# blade material so a single edit recolors all grass at once.
func _grass_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(0.26, 0.46, 0.18),
		Color(0.36, 0.58, 0.26),
		Color(0.50, 0.70, 0.34),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 1
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 0)
	return t

func _is_shore(gx: int, gy: int) -> bool:
	return gx == 0 or gy == 0 or gx == grid_w - 1 or gy == grid_h - 1

# Sand gradient: damp-dark to dry-light tan/beige, mirrors _grass_gradient() layout.
func _sand_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(0.62, 0.52, 0.34),
		Color(0.78, 0.69, 0.48),
		Color(0.90, 0.82, 0.62),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 1
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 0)
	return t

func _calib_label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	return l

# --- Multi-layer DESCENT volume (boxes + walkable ramps) --------------------
# Layer 0 = surface (world Y = 0); each deeper layer sits at Y = -layer*level_height.
# Walls fill upward from each floor toward the shallower level. At a link the
# SHALLOWER layer's floor is holed and a ramp descends through it to the deeper
# layer's floor (single cell, atan(level_height/cell_size) < 45deg = walkable).
# Box collision throughout.
# Map a lobby size to maze dimensions (cols, rows, layers). More players => bigger
# board + deeper; clamped so it stays gener-able and testable. Pure + headless-tested.
static func size_for_players(n: int) -> Vector3i:
	var side: int = clampi(4 + n, 4, 20)
	var depth: int = clampi(2 + n / 2, 2, 6)
	return Vector3i(side, side, depth)

# World-Y of maze layer l's floor top. The island occupies Y=0, so the first
# maze level (l=0) sits one level_height below it.
func _layer_y(l: int) -> float:
	return -(l + 1) * level_height

var entrance_cells: Array = []   # [gx, gy] grid coords of surface entrances

func _build_volume() -> void:
	if maze_seed == 0:
		maze_seed = randi()
	if auto_size_from_players:
		var dim := size_for_players(player_count)
		cols = dim.x
		rows = dim.y
		layers = dim.z
	volume = MazeVolume.generate(cols, rows, layers, maze_seed, braid, links_per_pair)
	var grids: Array = volume["grids"]
	grid_h = grids[0].size()
	grid_w = grids[0][0].size()

	_pick_entrances()
	_build_island()
	_build_grass()
	_build_grass_carpet()
	_build_water()

	# Hole the SHALLOWER layer's floor at each link so the ramp can descend through.
	var holes := {}
	for lk in volume["links"]:
		var gx: int = 2 * int(lk["cx"]) + 1
		var gy: int = 2 * int(lk["cy"]) + 1
		holes["%d:%d:%d" % [int(lk["lower"]), gx, gy]] = true

	for l in range(grids.size()):
		var base_y: float = _layer_y(l)
		for gy in range(grid_h):
			for gx in range(grid_w):
				if grids[l][gy][gx] == 1:
					if not holes.has("%d:%d:%d" % [l, gx, gy]):
						_volume_floor(gx, gy, base_y, l)
				else:
					_volume_wall(gx, gy, base_y, l)

	# Internal descent ramps between maze levels.
	for lk in volume["links"]:
		var gx2: int = 2 * int(lk["cx"]) + 1
		var gy2: int = 2 * int(lk["cy"]) + 1
		var lo: int = int(lk["lower"])
		_ramp(gx2, gy2, _layer_y(lo), _layer_y(lo + 1), Color(0.85, 0.55, 0.2), "Ramp_l%d_%d_%d" % [lo, gx2, gy2])

	# Entrance ramps: island surface down to the first maze level.
	for e in entrance_cells:
		_ramp(e[0], e[1], ISLAND_TOP, _layer_y(0), Color(0.9, 0.7, 0.3), "Entrance_%d_%d" % [e[0], e[1]])

	# Visual wall skin: GPU-instanced KayKit panels + pillars over every layer.
	_build_wall_visuals()
	_build_floor_visuals()
	_build_ceiling_visuals()

# Choose distinct logical-cell centers as surface entrances (open in maze layer 0).
func _pick_entrances() -> void:
	entrance_cells = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maze_seed ^ 0x5151
	var pool: Array = []
	for cy in range(rows):
		for cx in range(cols):
			pool.append([2 * cx + 1, 2 * cy + 1])
	var n: int = clampi(entrance_count, 1, pool.size())
	for i in range(n):
		var j: int = i + rng.randi() % (pool.size() - i)
		var tmp = pool[i]; pool[i] = pool[j]; pool[j] = tmp
		entrance_cells.append(pool[i])

# Thin grass cap at the surface, one tile per grid cell, holes at entrances. Sits
# a hair above the maze wall tops (no z-fight); maze level-0 corridors stay open
# below it (it is their ceiling). Top face at ISLAND_TOP.
const ISLAND_TOP := 0.05
const ISLAND_THICK := 0.5

func _build_island() -> void:
	var hole := {}
	for e in entrance_cells:
		hole["%d:%d" % [e[0], e[1]]] = true
	var ground_mat := load("res://assets/terrain/BinbunGrass/src/materials/grass_01/grass_ground_01.tres").duplicate()
	ground_mat.set_shader_parameter("color_gradient", _grass_gradient())
	var ground_fn := FastNoiseLite.new()
	ground_fn.frequency = 0.05
	var ground_noise := NoiseTexture2D.new()
	ground_noise.seamless = true
	ground_noise.noise = ground_fn
	ground_mat.set_shader_parameter("noise_texture", ground_noise)
	var sand_mat := load("res://assets/terrain/BinbunGrass/src/materials/grass_01/grass_ground_01.tres").duplicate()
	sand_mat.set_shader_parameter("color_gradient", _sand_gradient())
	var sand_fn := FastNoiseLite.new()
	sand_fn.frequency = 0.05
	var sand_noise := NoiseTexture2D.new()
	sand_noise.seamless = true
	sand_noise.noise = sand_fn
	sand_mat.set_shader_parameter("noise_texture", sand_noise)
	for gy in range(grid_h):
		for gx in range(grid_w):
			if hole.has("%d:%d" % [gx, gy]):
				continue
			var body := StaticBody3D.new()
			body.name = ("Sand_%d_%d" if _is_shore(gx, gy) else "Grass_%d_%d") % [gx, gy]
			var size := Vector3(cell_size, ISLAND_THICK, cell_size)
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = size
			mesh.mesh = box
			mesh.material_override = sand_mat if _is_shore(gx, gy) else ground_mat
			body.add_child(mesh)
			var c := CollisionShape3D.new()
			var s := BoxShape3D.new()
			s.size = size
			c.shape = s
			body.add_child(c)
			body.position = Vector3(gx * cell_size, ISLAND_TOP - ISLAND_THICK * 0.5, gy * cell_size)
			add_child(body)

# GPU-instanced grass clumps scattered across island tiles (visual only, no collision).
# Uses one MultiMeshInstance3D per clump mesh (4 total max). Seeded from maze_seed.
func _build_grass() -> void:
	var grass_paths := [
		"res://assets/terrain/Hilly_Prop_Grass_Clump_1 (2).obj",
		"res://assets/terrain/Hilly_Prop_Grass_Clump_2 (2).obj",
		"res://assets/terrain/Hilly_Prop_Grass_Clump_3 (2).obj",
		"res://assets/terrain/Hilly_Prop_Grass_Clump_4 (2).obj",
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = maze_seed ^ 0x6A55

	var hole := {}
	for e in entrance_cells:
		hole["%d:%d" % [e[0], e[1]]] = true

	# Collect transform lists per mesh index before creating any nodes.
	var transforms: Array = [[], [], [], []]

	for gy in range(grid_h):
		for gx in range(grid_w):
			if hole.has("%d:%d" % [gx, gy]):
				continue
			if _is_shore(gx, gy):
				continue
			if rng.randf() < 0.5:
				# Place 2 clumps on this eligible tile.
				for _c in range(2):
					var mi: int = rng.randi() % 4
					var jx: float = (rng.randf() * 2.0 - 1.0) * cell_size * 0.4
					var jz: float = (rng.randf() * 2.0 - 1.0) * cell_size * 0.4
					var pos := Vector3(gx * cell_size + jx, ISLAND_TOP, gy * cell_size + jz)
					var yaw: float = rng.randf() * TAU
					var scale: float = 0.8 + rng.randf() * 0.6
					var basis := Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale, scale))
					transforms[mi].append(Transform3D(basis, pos))

	for idx in range(4):
		if transforms[idx].size() == 0:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = load(grass_paths[idx])
		mm.instance_count = transforms[idx].size()
		for i in range(transforms[idx].size()):
			mm.set_instance_transform(i, transforms[idx][i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Grass_%d" % idx
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)

# GPU-instanced BinbunGrass billboard carpet — ONE MultiMeshInstance3D (one draw call).
# No collision. Blade count capped at 25000 for perf. Seeded from maze_seed.
func _build_grass_carpet() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.4, 0.4)
	quad.subdivide_width = 2
	quad.subdivide_depth = 2
	quad.center_offset = Vector3(0, 0.2, 0)   # base at y=0, tip at 0.4

	var grass_mat := load("res://assets/terrain/BinbunGrass/src/materials/grass_01/grass_01.tres")
	grass_mat.set_shader_parameter("wind_velocity", Vector2(0.6, 0.35))
	grass_mat.set_shader_parameter("random_variation", 0.1)
	grass_mat.set_shader_parameter("color_gradient", _grass_gradient())
	quad.material = grass_mat

	var rng := RandomNumberGenerator.new()
	rng.seed = maze_seed ^ 0x2C3A

	var hole := {}
	for e in entrance_cells:
		hole["%d:%d" % [e[0], e[1]]] = true

	var eligible := 0
	for gy in range(grid_h):
		for gx in range(grid_w):
			if not hole.has("%d:%d" % [gx, gy]):
				if not _is_shore(gx, gy):
					eligible += 1
	if eligible == 0:
		return
	var target_per_tile := 40
	var cap := 60000
	var per_tile: int = mini(target_per_tile, maxi(1, cap / eligible))
	var transforms: Array = []

	for gy in range(grid_h):
		for gx in range(grid_w):
			if hole.has("%d:%d" % [gx, gy]):
				continue
			if _is_shore(gx, gy):
				continue
			for _b in range(per_tile):
				var jx: float = (rng.randf() * 2.0 - 1.0) * cell_size * 0.5
				var jz: float = (rng.randf() * 2.0 - 1.0) * cell_size * 0.5
				var pos := Vector3(gx * cell_size + jx, ISLAND_TOP, gy * cell_size + jz)
				var yaw: float = rng.randf() * TAU
				var sc: float = 0.7 + rng.randf() * 0.8
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc))
				transforms.append(Transform3D(basis, pos))

	if transforms.is_empty():
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "GrassCarpet"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

# Single seamless water plane covering the island footprint plus a wide margin
# (visual + shallow catch collision). One StaticBody3D, one BoxShape3D.
func _build_water() -> void:
	var x0: float = -cell_size * 0.5
	var x1: float = (grid_w - 1) * cell_size + cell_size * 0.5
	var z0: float = -cell_size * 0.5
	var z1: float = (grid_h - 1) * cell_size + cell_size * 0.5
	var m: float = max(grid_w, grid_h) * cell_size * 2.0
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/water/water.gdshader")

	var fn_wave := FastNoiseLite.new()
	fn_wave.frequency = 0.01
	var tex_wave := NoiseTexture2D.new()
	tex_wave.seamless = true
	tex_wave.noise = fn_wave
	mat.set_shader_parameter("wave_texture", tex_wave)

	var fn_foam := FastNoiseLite.new()
	fn_foam.frequency = 0.05
	var tex_foam := NoiseTexture2D.new()
	tex_foam.seamless = true
	tex_foam.noise = fn_foam
	mat.set_shader_parameter("foam_texture", tex_foam)

	var fn_normal := FastNoiseLite.new()
	fn_normal.frequency = 0.02
	var tex_normal := NoiseTexture2D.new()
	tex_normal.seamless = true
	tex_normal.as_normal_map = true
	tex_normal.bump_strength = 4.0
	tex_normal.noise = fn_normal
	mat.set_shader_parameter("wave_normal_texture", tex_normal)

	mat.set_shader_parameter("surface_color", Color(0.13, 0.42, 0.62, 1.0))
	mat.set_shader_parameter("depth_color", Color(0.04, 0.12, 0.28, 1.0))
	mat.set_shader_parameter("wave_foam_amount", 0.25)
	mat.set_shader_parameter("foam_start", 0.5)
	mat.set_shader_parameter("foam_end", 0.75)
	mat.set_shader_parameter("foam_exponent", 3.0)
	mat.set_shader_parameter("edge_foam_depth_size", 0.4)
	# Ring (frame) water: one continuous mesh with a rectangular hole over the island
	# footprint, so entrance pits show the maze below instead of water, and there is no
	# internal seam (single surface). Inner edge tucks under the grass cap by `tuck`.
	var tuck: float = 0.2
	var ox0: float = x0 - m
	var ox1: float = x1 + m
	var oz0: float = z0 - m
	var oz1: float = z1 + m
	var ix0: float = x0 + tuck
	var ix1: float = x1 - tuck
	var iz0: float = z0 + tuck
	var iz1: float = z1 - tuck

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Helper inlined: each band is a quad (a,b,c,d) -> tris (a,b,c)+(a,c,d), normal up.
	var bands := [
		[Vector3(ox0, 0, oz0), Vector3(ox1, 0, oz0), Vector3(ox1, 0, iz0), Vector3(ox0, 0, iz0)],  # north
		[Vector3(ox0, 0, iz1), Vector3(ox1, 0, iz1), Vector3(ox1, 0, oz1), Vector3(ox0, 0, oz1)],  # south
		[Vector3(ox0, 0, iz0), Vector3(ix0, 0, iz0), Vector3(ix0, 0, iz1), Vector3(ox0, 0, iz1)],  # west
		[Vector3(ix1, 0, iz0), Vector3(ox1, 0, iz0), Vector3(ox1, 0, iz1), Vector3(ix1, 0, iz1)],  # east
	]
	for q in bands:
		for tri in [[q[0], q[1], q[2]], [q[0], q[2], q[3]]]:
			for v in tri:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v.x, v.z))
				st.add_vertex(v)
	var ring_mesh := st.commit()

	var body := StaticBody3D.new()
	body.name = "Water"
	var mesh := MeshInstance3D.new()
	mesh.mesh = ring_mesh
	mesh.material_override = mat
	body.add_child(mesh)
	body.position = Vector3(0, water_level, 0)
	add_child(body)

	# Collision: thin catch boxes OUTSIDE the footprint only (never over entrance pits).
	# [center_x, center_z, size_x, size_z]
	var coll_bands := [
		[(ox0 + ox1) * 0.5, (oz0 + z0) * 0.5, ox1 - ox0, z0 - oz0],  # north
		[(ox0 + ox1) * 0.5, (z1 + oz1) * 0.5, ox1 - ox0, oz1 - z1],  # south
		[(ox0 + x0) * 0.5, (z0 + z1) * 0.5, x0 - ox0, z1 - z0],      # west
		[(x1 + ox1) * 0.5, (z0 + z1) * 0.5, ox1 - x1, z1 - z0],      # east
	]
	for cb in coll_bands:
		var cbody := StaticBody3D.new()
		cbody.name = "WaterCollision"
		var ccol := CollisionShape3D.new()
		var cshape := BoxShape3D.new()
		cshape.size = Vector3(cb[2], 0.2, cb[3])
		ccol.shape = cshape
		cbody.add_child(ccol)
		cbody.position = Vector3(cb[0], water_level, cb[1])
		add_child(cbody)

func _volume_floor(gx: int, gy: int, base_y: float, l: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Floor_L%d_%d_%d" % [l, gx, gy]
	var size := Vector3(cell_size, 0.5, cell_size)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	body.add_child(c)
	body.position = Vector3(gx * cell_size, base_y - 0.25, gy * cell_size)
	add_child(body)

func _volume_wall(gx: int, gy: int, base_y: float, l: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Wall_L%d_%d_%d" % [l, gx, gy]
	var size := Vector3(cell_size, level_height, cell_size)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	body.add_child(c)
	body.position = Vector3(gx * cell_size, base_y + level_height * 0.5, gy * cell_size)
	add_child(body)

# TODO(ramps): ramps are a single inclined slab; angle = atan(level_height/cell_size),
# which exceeds the player's 45deg floor_max_angle once level_height > cell_size
# (e.g. level_height=5, cell=4 -> 51deg, unwalkable). Rework to stairs/switchbacks when
# level_height becomes variable. See memory: ramp-rework-pin.
func _ramp(gx: int, gy: int, top_y: float, bot_y: float, col: Color, name: String) -> void:
	# Inclined slab inside cell (gx,gy): rises by (top_y-bot_y) over one cell of run
	# along +X, so the +X end meets top_y and the -X end meets bot_y. Thin to limit
	# the lip where it meets the upper floor. atan(rise/run) < 45deg = walkable.
	var cx_w: float = gx * cell_size
	var cz_w: float = gy * cell_size
	var rise: float = top_y - bot_y
	var run: float = cell_size
	var span: float = sqrt(run * run + rise * rise)
	var angle: float = atan2(rise, run)

	var size := Vector3(span, 0.25, cell_size)
	var xform := Transform3D(Basis(Vector3(0, 0, 1), angle), Vector3(cx_w, (top_y + bot_y) * 0.5, cz_w))

	var body := StaticBody3D.new()
	body.name = name
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _calib_mat(col)
	body.add_child(mesh)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	body.add_child(c)
	body.transform = xform
	add_child(body)

# --- KayKit visual wall skin (GPU-instanced, no collision) ------------------
# KayKit wall mesh native size (X & Y); used to scale to our grid.
const WALL_NATIVE := 4.0
const KAYKIT_GLTF := "res://assets/props/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/"

# Extract a Mesh from a PackedScene (.gltf). Frees the temp instance.
# Returns null if the file cannot be loaded or contains no MeshInstance3D.
func _mesh_from_gltf(path: String) -> Mesh:
	var packed = load(path)
	if packed == null:
		return null
	var inst = packed.instantiate()
	var m := _find_mesh_rec(inst)
	inst.free()
	return m

func _find_mesh_rec(n: Node) -> Mesh:
	if n is MeshInstance3D:
		return (n as MeshInstance3D).mesh
	for c in n.get_children():
		var r := _find_mesh_rec(c)
		if r != null:
			return r
	return null

# Build two MultiMeshInstance3D nodes — "WallPanels" and "WallPillars" — from
# MazeWalls.wall_visuals over every layer in volume["grids"]. Visual only.
func _build_wall_visuals() -> void:
	var wall_mesh := _mesh_from_gltf(KAYKIT_GLTF + "wall.gltf")
	var pillar_mesh := _mesh_from_gltf(KAYKIT_GLTF + "wall_pillar.gltf")
	if wall_mesh == null or pillar_mesh == null:
		return
	var grids: Array = volume["grids"]
	var sxz: float = cell_size / WALL_NATIVE
	var sy: float = level_height / WALL_NATIVE
	var scale_v := Vector3(sxz, sy, sxz)
	var half: float = cell_size * 0.5

	# side index -> planar offset from cell center to that edge (N,E,S,W)
	var side_off := [Vector3(0,0,-half), Vector3(half,0,0), Vector3(0,0,half), Vector3(-half,0,0)]
	# corner index -> planar offset to that corner (NE,SE,SW,NW)
	var corner_off := [Vector3(half,0,-half), Vector3(half,0,half), Vector3(-half,0,half), Vector3(-half,0,-half)]

	var panel_xforms: Array = []
	var pillar_xforms: Array = []

	for l in range(grids.size()):
		var base_y: float = _layer_y(l)
		for p in MazeWalls.wall_visuals(grids[l]):
			var gx: int = int(p["x"])
			var gy: int = int(p["y"])
			var rot_y: float = deg_to_rad(float(p["rot"]))
			var basis := Basis(Vector3.UP, rot_y).scaled(scale_v)
			if p["kind"] == "panel":
				var off: Vector3 = side_off[int(p["side"])]
				var pos := Vector3(gx * cell_size + off.x, base_y, gy * cell_size + off.z)
				panel_xforms.append(Transform3D(basis, pos))
			else:
				var coff: Vector3 = corner_off[int(p["corner"])]
				var cpos := Vector3(gx * cell_size + coff.x, base_y, gy * cell_size + coff.z)
				pillar_xforms.append(Transform3D(basis, cpos))

	_add_wall_multimesh(wall_mesh, panel_xforms, "WallPanels")
	_add_wall_multimesh(pillar_mesh, pillar_xforms, "WallPillars")

func _build_floor_visuals() -> void:
	var floor_mesh := _mesh_from_gltf(KAYKIT_GLTF + "floor_tile_large.gltf")
	if floor_mesh == null:
		return
	var grids: Array = volume["grids"]
	# Same hole set the box builder uses, so tiles match the walkable floor.
	var holes := {}
	for lk in volume["links"]:
		var hgx: int = 2 * int(lk["cx"]) + 1
		var hgy: int = 2 * int(lk["cy"]) + 1
		holes["%d:%d:%d" % [int(lk["lower"]), hgx, hgy]] = true
	var sxz: float = cell_size / WALL_NATIVE
	var scale_v := Vector3(sxz, 1.0, sxz)
	var xforms: Array = []
	for l in range(grids.size()):
		var base_y: float = _layer_y(l)
		var gh: int = grids[l].size()
		var gw: int = grids[l][0].size()
		for gy in range(gh):
			for gx in range(gw):
				if grids[l][gy][gx] != 1:
					continue
				if holes.has("%d:%d:%d" % [l, gx, gy]):
					continue
				var pos := Vector3(gx * cell_size, base_y + 0.02, gy * cell_size)
				xforms.append(Transform3D(Basis().scaled(scale_v), pos))
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = floor_mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "FloorTiles"
	var fts := _two_sided_mat(floor_mesh)
	if fts != null:
		mmi.material_override = fts
	add_child(mmi)

func _build_ceiling_visuals() -> void:
	var ceil_mesh := _mesh_from_gltf(KAYKIT_GLTF + "floor_tile_large.gltf")
	if ceil_mesh == null:
		return
	var grids: Array = volume["grids"]
	if grids.is_empty():
		return
	var ent := {}
	for e in entrance_cells:
		ent["%d:%d" % [e[0], e[1]]] = true
	var sxz: float = cell_size / WALL_NATIVE
	var top_y: float = ISLAND_TOP - ISLAND_THICK - 0.05   # just below the grass cap
	var g0: Array = grids[0]
	var xforms: Array = []
	for gy in range(g0.size()):
		for gx in range(g0[gy].size()):
			if g0[gy][gx] != 1:
				continue
			if ent.has("%d:%d" % [gx, gy]):
				continue
			xforms.append(Transform3D(Basis().scaled(Vector3(sxz, 1.0, sxz)), Vector3(gx * cell_size, top_y, gy * cell_size)))
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ceil_mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "CeilingTiles"
	var ts := _two_sided_mat(ceil_mesh)
	if ts != null:
		mmi.material_override = ts
	add_child(mmi)

func _two_sided_mat(mesh: Mesh) -> Material:
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var m = mesh.surface_get_material(0)
	if m == null:
		return null
	var dup = m.duplicate()
	if dup is BaseMaterial3D:
		dup.cull_mode = BaseMaterial3D.CULL_DISABLED
	return dup

func _add_wall_multimesh(mesh: Mesh, xforms: Array, node_name: String) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = node_name
	var ts := _two_sided_mat(mesh)
	if ts != null:
		mmi.material_override = ts
	add_child(mmi)

# Snapshot of the current build for logging / screenshot metadata.
func debug_state() -> Dictionary:
	var ent: Array = []
	for e in entrance_cells:
		ent.append([e[0], e[1]])
	var sp := get_spawn_position()
	return {
		"seed": maze_seed,
		"cols": cols,
		"rows": rows,
		"layers": layers,
		"level_height": level_height,
		"cell_size": cell_size,
		"grid_w": grid_w,
		"grid_h": grid_h,
		"entrance_cells": ent,
		"water_level": water_level,
		"spawn": [sp.x, sp.y, sp.z],
	}

# World position above the first FLOOR cell center — where to drop a player.
func get_spawn_position() -> Vector3:
	if cave_calibration:
		return Vector3(6.0, 2.0, 12.0)
	if use_volume:
		# Spawn on the island surface (Y=0) a couple cells from the first entrance.
		if not entrance_cells.is_empty():
			var e = entrance_cells[0]
			var sx: int = clampi(e[0] + 2, 1, grid_w - 1)
			return Vector3(sx * cell_size, ISLAND_TOP + 1.5, e[1] * cell_size)
		return Vector3((grid_w - 1) * 0.5 * cell_size, ISLAND_TOP + 1.5, (grid_h - 1) * 0.5 * cell_size)
	for y in range(grid_h):
		for x in range(grid_w):
			if grid[y][x] == 1:
				return _cell_world(x, y, 1.5)
	return Vector3.ZERO

# Count of walkable cells — handy for spawning N players on distinct tiles.
func floor_cell_count() -> int:
	return MazeGenerator.count_open(grid)
