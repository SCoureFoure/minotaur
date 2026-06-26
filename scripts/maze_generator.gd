class_name MazeGenerator
# Pure-data maze generator — no nodes, no rendering.
# Grid: H = rows*2+1, W = cols*2+1.  grid[y][x]: 0=WALL, 1=FLOOR.
# Logical cell (cx,cy) sits at grid (2*cx+1, 2*cy+1).


static func generate(cols: int, rows: int, rng_seed: int, braid: float) -> Array:
	var H: int = rows * 2 + 1
	var W: int = cols * 2 + 1

	# Step 1 — Init grid all-WALL.
	var grid: Array = []
	for _y in range(H):
		var row: Array = []
		for _x in range(W):
			row.append(0)
		grid.append(row)

	# Per-cell visited flags indexed [cy][cx].
	var visited: Array = []
	for _cy in range(rows):
		var vrow: Array = []
		for _cx in range(cols):
			vrow.append(false)
		visited.append(vrow)

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Step 2 — Iterative DFS (recursive-backtracker).
	# Start cell (0,0): mark centre FLOOR, push to stack.
	grid[1][1] = 1
	visited[0][0] = true
	var stack: Array = [[0, 0]]  # each entry: [cx, cy]

	while stack.size() > 0:
		var cx: int = stack[-1][0]
		var cy: int = stack[-1][1]

		# Collect unvisited orthogonal neighbours (in cell coordinates).
		var neighbors: Array = []
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = cx + d[0]
			var ny: int = cy + d[1]
			if nx >= 0 and nx < cols and ny >= 0 and ny < rows and not visited[ny][nx]:
				neighbors.append([nx, ny, d[0], d[1]])

		if neighbors.size() > 0:
			# Pick a random unvisited neighbour.
			var idx: int = rng.randi() % neighbors.size()
			var nx: int = neighbors[idx][0]
			var ny: int = neighbors[idx][1]
			var dx: int = neighbors[idx][2]
			var dy: int = neighbors[idx][3]

			# Carve: wall square between the two cells → FLOOR.
			grid[cy * 2 + 1 + dy][cx * 2 + 1 + dx] = 1
			# Neighbour centre → FLOOR.
			grid[ny * 2 + 1][nx * 2 + 1] = 1

			visited[ny][nx] = true
			stack.append([nx, ny])
		else:
			stack.pop_back()

	# Step 3 — Braiding: for each dead-end cell, with probability `braid`
	# open one currently-WALL neighbour direction that is not the outer border.
	if braid > 0.0:
		for cy in range(rows):
			for cx in range(cols):
				var gx: int = cx * 2 + 1
				var gy: int = cy * 2 + 1

				# Count FLOOR orthogonal neighbours in grid space.
				var floor_count: int = 0
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					if grid[gy + d[1]][gx + d[0]] == 1:
						floor_count += 1

				if floor_count != 1:
					continue

				# This is a dead end — attempt to braid with probability `braid`.
				if rng.randf() >= braid:
					continue

				# Collect directions where the adjacent grid square is WALL
				# and is not on the outer border.
				var carvable: Array = []
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var wgx: int = gx + d[0]
					var wgy: int = gy + d[1]
					if wgx > 0 and wgx < W - 1 and wgy > 0 and wgy < H - 1:
						if grid[wgy][wgx] == 0:
							carvable.append(d)

				if carvable.size() == 0:
					continue

				var d = carvable[rng.randi() % carvable.size()]
				# Open the wall square.
				grid[gy + d[1]][gx + d[0]] = 1
				# Open the cell centre beyond (always already FLOOR after DFS,
				# but set explicitly per spec).
				grid[gy + d[1] * 2][gx + d[0] * 2] = 1

	return grid


# True iff all FLOOR cells form one 4-connected component.
# (named is_fully_connected to avoid clashing with Object.is_connected)
static func is_fully_connected(grid: Array) -> bool:
	var H: int = grid.size()
	if H == 0:
		return true
	var W: int = grid[0].size()

	# Find first FLOOR cell to seed the flood fill.
	var sx: int = -1
	var sy: int = -1
	for y in range(H):
		for x in range(W):
			if grid[y][x] == 1:
				sx = x
				sy = y
				break
		if sx != -1:
			break

	if sx == -1:
		return true  # No FLOOR cells — vacuously connected.

	# BFS flood fill using an index into the queue (avoids pop_front cost).
	var seen: Array = []
	for _y in range(H):
		var vrow: Array = []
		for _x in range(W):
			vrow.append(false)
		seen.append(vrow)

	seen[sy][sx] = true
	var queue: Array = [[sx, sy]]
	var qi: int = 0
	var filled: int = 1

	while qi < queue.size():
		var cx: int = queue[qi][0]
		var cy: int = queue[qi][1]
		qi += 1
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = cx + d[0]
			var ny: int = cy + d[1]
			if nx >= 0 and nx < W and ny >= 0 and ny < H:
				if not seen[ny][nx] and grid[ny][nx] == 1:
					seen[ny][nx] = true
					queue.append([nx, ny])
					filled += 1

	# Compare reached count against total FLOOR count.
	var total: int = 0
	for row in grid:
		for cell in row:
			if cell == 1:
				total += 1

	return filled == total


# Number of grid cells equal to 1 (FLOOR).
static func count_open(grid: Array) -> int:
	var count: int = 0
	for row in grid:
		for cell in row:
			if cell == 1:
				count += 1
	return count


# Number of logical cell centres (odd x, odd y) that are FLOOR
# and have exactly one FLOOR orthogonal neighbour.
static func count_dead_ends(grid: Array) -> int:
	var H: int = grid.size()
	if H == 0:
		return 0
	var W: int = grid[0].size()
	var rows: int = (H - 1) / 2
	var cols: int = (W - 1) / 2
	var count: int = 0

	for cy in range(rows):
		for cx in range(cols):
			var gx: int = cx * 2 + 1
			var gy: int = cy * 2 + 1
			if grid[gy][gx] != 1:
				continue
			var floor_neighbors: int = 0
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = gx + d[0]
				var ny: int = gy + d[1]
				if nx >= 0 and nx < W and ny >= 0 and ny < H:
					if grid[ny][nx] == 1:
						floor_neighbors += 1
			if floor_neighbors == 1:
				count += 1

	return count
