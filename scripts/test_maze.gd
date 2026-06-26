extends SceneTree
# Headless AC test for maze_generator.gd. Run:
#   godot --headless --path . --script res://scripts/test_MazeGenerator.gd

# global class_name MazeGenerator

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

func _initialize() -> void:
	# A1 DIMS
	var g = MazeGenerator.generate(5, 5, 1, 0.0)
	_check("A1 height", g.size() == 5 * 2 + 1)
	var widths_ok := true
	for row in g:
		if row.size() != 5 * 2 + 1:
			widths_ok = false
	_check("A1 widths", widths_ok)

	# A2 BORDER all wall
	var H: int = g.size()
	var W: int = g[0].size()
	var border_ok := true
	for x in range(W):
		if g[0][x] != 0 or g[H - 1][x] != 0:
			border_ok = false
	for y in range(H):
		if g[y][0] != 0 or g[y][W - 1] != 0:
			border_ok = false
	_check("A2 border all wall", border_ok)

	# A3 CENTERS all floor
	var centers_ok := true
	for cy in range(5):
		for cx in range(5):
			if g[cy * 2 + 1][cx * 2 + 1] != 1:
				centers_ok = false
	_check("A3 centers floor", centers_ok)

	# A4 CONNECTED across many seeds + braids
	var conn_ok := true
	for s in range(40):
		for b in [0.0, 0.3, 1.0]:
			if not MazeGenerator.is_fully_connected(MazeGenerator.generate(8, 8, s, b)):
				conn_ok = false
	_check("A4 connected (40 seeds x 3 braids)", conn_ok)

	# A5 DETERMINISM
	var a = MazeGenerator.generate(8, 8, 12345, 0.0)
	var b2 = MazeGenerator.generate(8, 8, 12345, 0.0)
	_check("A5 determinism", str(a) == str(b2))

	# A6 PERFECT MAZE COUNT (braid=0 -> spanning tree)
	var count_ok := true
	for s in range(20):
		var gg = MazeGenerator.generate(9, 7, s, 0.0)
		if MazeGenerator.count_open(gg) != 2 * 9 * 7 - 1:
			count_ok = false
	_check("A6 perfect-maze open count == 2*cols*rows-1", count_ok)

	# A7 BRAID REDUCES DEAD ENDS
	var de_braid = MazeGenerator.count_dead_ends(MazeGenerator.generate(10, 10, 7, 1.0))
	var de_perfect = MazeGenerator.count_dead_ends(MazeGenerator.generate(10, 10, 7, 0.0))
	_check("A7 braid reduces dead ends (%d < %d)" % [de_braid, de_perfect], de_braid < de_perfect)

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()


