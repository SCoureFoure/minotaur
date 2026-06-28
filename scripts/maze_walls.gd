extends RefCounted
class_name MazeWalls

# side:   0=N, 1=E, 2=S, 3=W
# corner: 0=NE, 1=SE, 2=SW, 3=NW   (named by the two sides that flank it)

# Out-of-bounds counts as WALL.
static func is_wall(grid: Array, x: int, y: int) -> bool:
	var h = grid.size()
	var w = grid[0].size()
	if x < 0 or x >= w or y < 0 or y >= h:
		return true
	return grid[y][x] == 0

# Returns an Array of placement Dictionaries over the whole grid.
# Iterate y outer, x inner. For each FLOOR cell, emit panels first (in side
# order N,E,S,W) for every side whose neighbor is a wall, THEN corners (in
# corner order NE,SE,SW,NW) for every corner whose two flanking sides are
# both walls.
#   panel  dict: {"kind":"panel",  "x":x, "y":y, "side":s,   "rot": float(s)*90.0}
#   corner dict: {"kind":"corner", "x":x, "y":y, "corner":c, "rot": float(c)*90.0}
# Flanking sides per corner: NE->N&E, SE->S&E, SW->S&W, NW->N&W.
static func wall_visuals(grid: Array) -> Array:
	var result: Array = []
	var h = grid.size()
	if h == 0:
		return result

	# Side neighbor offsets indexed by side number: N=0, E=1, S=2, W=3.
	var side_dx = [0, 1, 0, -1]
	var side_dy = [-1, 0, 1, 0]

	# Flanking side index pairs per corner: NE->N(0)&E(1), SE->S(2)&E(1), SW->S(2)&W(3), NW->N(0)&W(3).
	var corner_sides = [
		[0, 1],  # NE (corner 0)
		[2, 1],  # SE (corner 1)
		[2, 3],  # SW (corner 2)
		[0, 3],  # NW (corner 3)
	]

	for y in range(h):
		for x in range(grid[y].size()):
			if grid[y][x] != 1:
				continue
			# Determine which of the four sides have a wall neighbor.
			var side_is_wall: Array = [false, false, false, false]
			for s in range(4):
				side_is_wall[s] = is_wall(grid, x + side_dx[s], y + side_dy[s])
			# Emit panels in order N, E, S, W.
			for s in range(4):
				if side_is_wall[s]:
					result.append({"kind": "panel", "x": x, "y": y, "side": s, "rot": float(s) * 90.0})
			# Emit corners in order NE, SE, SW, NW — only when BOTH flanking sides are walls.
			for c in range(4):
				if side_is_wall[corner_sides[c][0]] and side_is_wall[corner_sides[c][1]]:
					result.append({"kind": "corner", "x": x, "y": y, "corner": c, "rot": float(c) * 90.0})

	return result
