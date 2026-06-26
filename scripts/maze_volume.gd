extends RefCounted
class_name MazeVolume
# Pure-data multi-layer maze volume — no nodes, no rendering.
# Stacks independent per-layer grids produced by MazeGenerator and
# carves vertical ramp links between adjacent layer pairs.
# grid[y][x]: 0=WALL, 1=FLOOR.  Logical cell (cx,cy) at grid (2*cx+1, 2*cy+1).


static func generate(cols: int, rows: int, layers: int, rng_seed: int, braid: float, links_per_pair: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	# Step 1 — Derive one distinct seed per layer BEFORE generating any grid,
	# in ascending layer order, so every layer differs even when braid/cols/rows match.
	var layer_seeds: Array = []
	for _l in range(layers):
		layer_seeds.append(rng.randi())

	# Step 2 — Generate each layer independently using its derived seed.
	var grids: Array = []
	for l in range(layers):
		grids.append(MazeGenerator.generate(cols, rows, layer_seeds[l], braid))

	# Step 3 — Build vertical ramp links for each adjacent layer pair.
	# n is capped at the pool size so we never request more distinct cells than exist.
	var links: Array = []
	var pool_size: int = cols * rows
	var n: int = min(links_per_pair, pool_size)

	for lower in range(layers - 1):
		# Candidate pool: all logical cell coordinates, in row-major order.
		var pool: Array = []
		for cy in range(rows):
			for cx in range(cols):
				pool.append([cx, cy])

		# Partial Fisher-Yates shuffle: move n distinct cells to pool[0..n-1].
		for i in range(n):
			var j: int = i + rng.randi() % (pool_size - i)
			var tmp = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp

		# Record the first n shuffled cells as ramp links for this pair.
		for i in range(n):
			links.append({
				"cx": pool[i][0],
				"cy": pool[i][1],
				"lower": lower,
				"type": "ramp"
			})

	return {"grids": grids, "links": links}
