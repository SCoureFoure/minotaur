extends RefCounted
class_name MazeAutotile

static func wall_mask(grid: Array, x: int, y: int) -> int:
	var mask = 0
	var h = grid.size()
	var w = grid[0].size()

	# Check North neighbor (x, y - 1)
	var nx = x
	var ny = y - 1
	if nx < 0 or nx >= w or ny < 0 or ny >= h or grid[ny][nx] == 0:
		mask += 1

	# Check East neighbor (x + 1, y)
	nx = x + 1
	ny = y
	if nx < 0 or nx >= w or ny < 0 or ny >= h or grid[ny][nx] == 0:
		mask += 2

	# Check South neighbor (x, y + 1)
	nx = x
	ny = y + 1
	if nx < 0 or nx >= w or ny < 0 or ny >= h or grid[ny][nx] == 0:
		mask += 4

	# Check West neighbor (x - 1, y)
	nx = x - 1
	ny = y
	if nx < 0 or nx >= w or ny < 0 or ny >= h or grid[ny][nx] == 0:
		mask += 8

	return mask
