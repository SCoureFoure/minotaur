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
		mi.mesh = load("res://assests/terrain/%s.obj" % n)
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
const _LAYER_COLORS := [
	Color(0.35, 0.55, 0.75),  # layer 0 blue-gray
	Color(0.45, 0.70, 0.45),  # layer 1 green
	Color(0.75, 0.60, 0.40),  # layer 2 tan
	Color(0.70, 0.45, 0.65),  # layer 3 mauve
]

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
	_build_water()

	# Hole the SHALLOWER layer's floor at each link so the ramp can descend through.
	var holes := {}
	for lk in volume["links"]:
		var gx: int = 2 * int(lk["cx"]) + 1
		var gy: int = 2 * int(lk["cy"]) + 1
		holes["%d:%d:%d" % [int(lk["lower"]), gx, gy]] = true

	for l in range(grids.size()):
		var col: Color = _LAYER_COLORS[l % _LAYER_COLORS.size()]
		var base_y: float = _layer_y(l)
		for gy in range(grid_h):
			for gx in range(grid_w):
				if grids[l][gy][gx] == 1:
					if not holes.has("%d:%d:%d" % [l, gx, gy]):
						_volume_floor(gx, gy, base_y, col)
				else:
					_volume_wall(gx, gy, base_y, col)

	# Internal descent ramps between maze levels.
	for lk in volume["links"]:
		var gx2: int = 2 * int(lk["cx"]) + 1
		var gy2: int = 2 * int(lk["cy"]) + 1
		var lo: int = int(lk["lower"])
		_ramp(gx2, gy2, _layer_y(lo), _layer_y(lo + 1), Color(0.85, 0.55, 0.2), "Ramp_l%d_%d_%d" % [lo, gx2, gy2])

	# Entrance ramps: island surface down to the first maze level.
	for e in entrance_cells:
		_ramp(e[0], e[1], ISLAND_TOP, _layer_y(0), Color(0.9, 0.7, 0.3), "Entrance_%d_%d" % [e[0], e[1]])

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
	var grass := _calib_mat(Color(0.30, 0.50, 0.22))
	for gy in range(grid_h):
		for gx in range(grid_w):
			if hole.has("%d:%d" % [gx, gy]):
				continue
			var body := StaticBody3D.new()
			var size := Vector3(cell_size, ISLAND_THICK, cell_size)
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = size
			mesh.mesh = box
			mesh.material_override = grass
			body.add_child(mesh)
			var c := CollisionShape3D.new()
			var s := BoxShape3D.new()
			s.size = size
			c.shape = s
			body.add_child(c)
			body.position = Vector3(gx * cell_size, ISLAND_TOP - ISLAND_THICK * 0.5, gy * cell_size)
			add_child(body)

# Flat water plane ringing the island (visual + shallow catch collision).
# Water FRAME ringing the island (4 boxes), leaving the island footprint open so
# entrances aren't covered or collision-blocked. Flat blue placeholder material.
func _build_water() -> void:
	var x0: float = -cell_size * 0.5
	var x1: float = (grid_w - 1) * cell_size + cell_size * 0.5
	var z0: float = -cell_size * 0.5
	var z1: float = (grid_h - 1) * cell_size + cell_size * 0.5
	var m: float = max(grid_w, grid_h) * cell_size * 2.0
	# [center_x, center_z, size_x, size_z]
	var rings := [
		[(x0 + x1) * 0.5, z0 - m * 0.5, (x1 - x0) + 2.0 * m, m],   # north
		[(x0 + x1) * 0.5, z1 + m * 0.5, (x1 - x0) + 2.0 * m, m],   # south
		[x0 - m * 0.5, (z0 + z1) * 0.5, m, (z1 - z0)],             # west
		[x1 + m * 0.5, (z0 + z1) * 0.5, m, (z1 - z0)],             # east
	]
	var mat := _calib_mat(Color(0.13, 0.32, 0.5))
	mat.metallic = 0.2
	mat.roughness = 0.1
	for r in rings:
		var body := StaticBody3D.new()
		body.name = "Water"
		var size := Vector3(r[2], 0.2, r[3])
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		mesh.material_override = mat
		body.add_child(mesh)
		var c := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		c.shape = s
		body.add_child(c)
		body.position = Vector3(r[0], water_level, r[1])
		add_child(body)

func _volume_floor(gx: int, gy: int, base_y: float, col: Color) -> void:
	var body := StaticBody3D.new()
	var size := Vector3(cell_size, 0.5, cell_size)
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
	body.position = Vector3(gx * cell_size, base_y - 0.25, gy * cell_size)
	add_child(body)

func _volume_wall(gx: int, gy: int, base_y: float, col: Color) -> void:
	var body := StaticBody3D.new()
	var size := Vector3(cell_size, level_height, cell_size)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _calib_mat(col.darkened(0.4))
	body.add_child(mesh)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	body.add_child(c)
	body.position = Vector3(gx * cell_size, base_y + level_height * 0.5, gy * cell_size)
	add_child(body)

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
