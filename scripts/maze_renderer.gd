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

var grid: Array = []
var grid_w: int = 0
var grid_h: int = 0

func _ready() -> void:
	if build_on_ready:
		build()

func build() -> void:
	for c in get_children():
		c.queue_free()

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

# World position above the first FLOOR cell center — where to drop a player.
func get_spawn_position() -> Vector3:
	for y in range(grid_h):
		for x in range(grid_w):
			if grid[y][x] == 1:
				return _cell_world(x, y, 1.5)
	return Vector3.ZERO

# Count of walkable cells — handy for spawning N players on distinct tiles.
func floor_cell_count() -> int:
	return MazeGenerator.count_open(grid)
