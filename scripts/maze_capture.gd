extends RefCounted
class_name MazeCapture
# Pure-data camera waypoint generator for maze screenshot fly-through.
# Computes a list of camera positions and look targets from world state.


static func waypoints(ws: Dictionary) -> Array:
	var cell_size: float = float(ws["cell_size"])
	var level_height: float = float(ws["level_height"])
	var layers: int = int(ws["layers"])
	var grid_w: int = int(ws["grid_w"])
	var grid_h: int = int(ws["grid_h"])
	var spawn: Vector3 = Vector3(float(ws["spawn"][0]), float(ws["spawn"][1]), float(ws["spawn"][2]))
	var entrance_cells: Array = ws["entrance_cells"]

	var result: Array = []

	# Step 1: spawn
	var spawn_entry: Dictionary = {
		"label": "spawn",
		"pos": Vector3(spawn.x, spawn.y + 0.6, spawn.z),
		"target": Vector3(spawn.x + 4, spawn.y + 0.6, spawn.z)
	}
	result.append(spawn_entry)

	# Step 2: overhead
	var cx: float = (grid_w - 1) * 0.5 * cell_size
	var cz: float = (grid_h - 1) * 0.5 * cell_size
	var overhead_entry: Dictionary = {
		"label": "overhead",
		"pos": Vector3(cx, 40.0, cz + 0.001),
		"target": Vector3(cx, 0.0, cz)
	}
	result.append(overhead_entry)

	# Step 3: entrances
	for i in range(entrance_cells.size()):
		var gx: int = int(entrance_cells[i][0])
		var gy: int = int(entrance_cells[i][1])
		var ex: float = gx * cell_size
		var ez: float = gy * cell_size
		var entrance_entry: Dictionary = {
			"label": "entrance_%d" % i,
			"pos": Vector3(ex, 6.0, ez + 6.0),
			"target": Vector3(ex, 0.0, ez)
		}
		result.append(entrance_entry)

	# Step 4: levels
	for l in range(layers):
		var ly: float = -(l + 1) * level_height
		var level_entry: Dictionary = {
			"label": "level_%d" % l,
			"pos": Vector3(cx, ly + 0.6, cz),
			"target": Vector3(cx + 4, ly + 0.6, cz)
		}
		result.append(level_entry)

	return result
