extends SceneTree
# Headless AC test for maze_volume.gd. Run:
#   godot --headless --path . --script res://scripts/test_maze_volume.gd

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

# Flood fill the full 3D structure: 4-connected within each layer's FLOOR cells,
# plus a vertical edge at each link cell center between layer `lower` and lower+1.
# Returns true iff every FLOOR cell across every layer is reached.
func _volume_connected(res: Dictionary) -> bool:
	var grids: Array = res["grids"]
	var links: Array = res["links"]
	var L: int = grids.size()
	if L == 0:
		return true
	var H: int = grids[0].size()
	var W: int = grids[0][0].size()

	# Vertical adjacency set keyed "l:x:y" (grid coords) -> array of target layers.
	var vlinks := {}
	for lk in links:
		var gx: int = 2 * int(lk["cx"]) + 1
		var gy: int = 2 * int(lk["cy"]) + 1
		var lo: int = int(lk["lower"])
		for pair in [[lo, gx, gy, lo + 1], [lo + 1, gx, gy, lo]]:
			var key: String = "%d:%d:%d" % [pair[0], pair[1], pair[2]]
			if not vlinks.has(key):
				vlinks[key] = []
			vlinks[key].append(pair[3])

	# total floor count
	var total: int = 0
	var seed_cell := []
	for l in range(L):
		for y in range(H):
			for x in range(W):
				if grids[l][y][x] == 1:
					total += 1
					if seed_cell.is_empty():
						seed_cell = [l, x, y]
	if total == 0:
		return true

	var seen := {}
	var queue := [seed_cell]
	seen["%d:%d:%d" % [seed_cell[0], seed_cell[1], seed_cell[2]]] = true
	var qi := 0
	var reached := 1
	while qi < queue.size():
		var cur = queue[qi]
		qi += 1
		var cl: int = cur[0]
		var cx: int = cur[1]
		var cy: int = cur[2]
		# 4-connected in-layer
		for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var nx: int = cx + d[0]
			var ny: int = cy + d[1]
			if nx >= 0 and nx < W and ny >= 0 and ny < H and grids[cl][ny][nx] == 1:
				var k: String = "%d:%d:%d" % [cl, nx, ny]
				if not seen.has(k):
					seen[k] = true
					reached += 1
					queue.append([cl, nx, ny])
		# vertical links
		var vk: String = "%d:%d:%d" % [cl, cx, cy]
		if vlinks.has(vk):
			for tl in vlinks[vk]:
				if grids[tl][cy][cx] == 1:
					var k2: String = "%d:%d:%d" % [tl, cx, cy]
					if not seen.has(k2):
						seen[k2] = true
						reached += 1
						queue.append([tl, cx, cy])
	return reached == total

func _links_distinct_per_pair(res: Dictionary) -> bool:
	var by_lower := {}
	for lk in res["links"]:
		var lo = lk["lower"]
		if not by_lower.has(lo):
			by_lower[lo] = {}
		var key = "%d,%d" % [lk["cx"], lk["cy"]]
		if by_lower[lo].has(key):
			return false
		by_lower[lo][key] = true
	return true

func _initialize() -> void:
	# V1 dims
	var r = MazeVolume.generate(4, 4, 3, 7, 0.0, 2)
	_check("V1 grids count", r["grids"].size() == 3)
	var dims_ok := true
	for g in r["grids"]:
		if g.size() != 9:
			dims_ok = false
		for row in g:
			if row.size() != 9:
				dims_ok = false
	_check("V1 grid dims 9x9", dims_ok)

	# V2 link count = links_per_pair * (layers-1)
	_check("V2 link count == 4", r["links"].size() == 4)

	# V3 link fields valid + cells floor in both layers
	var fields_ok := true
	for lk in r["links"]:
		if not (lk["cx"] >= 0 and lk["cx"] < 4 and lk["cy"] >= 0 and lk["cy"] < 4):
			fields_ok = false
		if not (lk["lower"] >= 0 and lk["lower"] < 2):
			fields_ok = false
		if lk["type"] != "ramp":
			fields_ok = false
		var gx = 2 * lk["cx"] + 1
		var gy = 2 * lk["cy"] + 1
		if r["grids"][lk["lower"]][gy][gx] != 1:
			fields_ok = false
		if r["grids"][lk["lower"] + 1][gy][gx] != 1:
			fields_ok = false
	_check("V3 link fields valid + both-floor", fields_ok)

	# V4 distinct per pair
	_check("V4 links distinct per pair", _links_distinct_per_pair(r))

	# V5 determinism
	var a = MazeVolume.generate(4, 4, 3, 99, 0.3, 2)
	var b = MazeVolume.generate(4, 4, 3, 99, 0.3, 2)
	_check("V5 determinism", str(a) == str(b))

	# V6 3D connectivity across several configs
	var conn_ok := true
	for s in range(15):
		for lp in [1, 3]:
			if not _volume_connected(MazeVolume.generate(6, 5, 4, s, 0.3, lp)):
				conn_ok = false
	_check("V6 volume connected (15 seeds x 2 link counts, 4 layers)", conn_ok)

	# V7 single layer -> no links, key present
	var one = MazeVolume.generate(4, 4, 1, 7, 0.0, 2)
	_check("V7 single layer grids=1", one["grids"].size() == 1)
	_check("V7 single layer links empty + present", one.has("links") and one["links"].size() == 0)

	# V8 clamp: pool 2x2=4, links_per_pair=10 -> 4 links, distinct, all lower 0
	var c = MazeVolume.generate(2, 2, 2, 7, 0.0, 10)
	var clamp_ok = c["links"].size() == 4 and _links_distinct_per_pair(c)
	for lk in c["links"]:
		if lk["lower"] != 0:
			clamp_ok = false
	_check("V8 clamp to pool size", clamp_ok)

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()
