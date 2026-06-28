extends SceneTree
# Headless AC test for maze_walls.gd. Run:
#   godot --headless --path . --script res://scripts/test_maze_walls.gd

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

func _initialize() -> void:
	# --- Grid SINGLE: one floor cell fully enclosed by walls ---
	var SINGLE = [
		[0, 0, 0],
		[0, 1, 0],
		[0, 0, 0],
	]
	var sv = MazeWalls.wall_visuals(SINGLE)
	_check("SINGLE total placements==8", sv.size() == 8)

	var sp_count = 0
	var sc_count = 0
	for d in sv:
		if d["kind"] == "panel":
			sp_count += 1
		elif d["kind"] == "corner":
			sc_count += 1
	_check("SINGLE panel count==4", sp_count == 4)
	_check("SINGLE corner count==4", sc_count == 4)

	_check("is_wall OOB x=-1 y=0 ==true", MazeWalls.is_wall(SINGLE, -1, 0) == true)
	_check("is_wall floor (1,1)==false", MazeWalls.is_wall(SINGLE, 1, 1) == false)

	# --- Grid OPEN: all floor ---
	var OPEN = [
		[1, 1, 1],
		[1, 1, 1],
		[1, 1, 1],
	]
	var ov = MazeWalls.wall_visuals(OPEN)
	var open_center_count = 0
	for d in ov:
		if d["x"] == 1 and d["y"] == 1:
			open_center_count += 1
	_check("OPEN center (1,1) zero placements", open_center_count == 0)

	# --- Grid RING: loop corridor around a center wall ---
	var RING = [
		[0, 0, 0, 0, 0],
		[0, 1, 1, 1, 0],
		[0, 1, 0, 1, 0],
		[0, 1, 1, 1, 0],
		[0, 0, 0, 0, 0],
	]
	var rv = MazeWalls.wall_visuals(RING)

	# Cell (1,1): NW corner — N and W are walls, E and S are floor.
	var r11_panels: Array = []
	var r11_corners: Array = []
	for d in rv:
		if d["x"] == 1 and d["y"] == 1:
			if d["kind"] == "panel":
				r11_panels.append(d["side"])
			else:
				r11_corners.append(d["corner"])
	_check("RING (1,1) panel count==2", r11_panels.size() == 2)
	_check("RING (1,1) panel sides=={0,3}", (0 in r11_panels) and (3 in r11_panels))
	_check("RING (1,1) corner count==1", r11_corners.size() == 1)
	_check("RING (1,1) corner==3 (NW)", r11_corners.size() == 1 and r11_corners[0] == 3)

	# Cell (2,1): N and S are walls, E and W are floor — no corners.
	var r21_panels: Array = []
	var r21_corners: Array = []
	for d in rv:
		if d["x"] == 2 and d["y"] == 1:
			if d["kind"] == "panel":
				r21_panels.append(d["side"])
			else:
				r21_corners.append(d["corner"])
	_check("RING (2,1) panel count==2", r21_panels.size() == 2)
	_check("RING (2,1) panel sides=={0,2}", (0 in r21_panels) and (2 in r21_panels))
	_check("RING (2,1) corner count==0", r21_corners.size() == 0)

	# Cell (3,1): NE corner — N and E are walls, S and W are floor.
	var r31_panels: Array = []
	var r31_corners: Array = []
	for d in rv:
		if d["x"] == 3 and d["y"] == 1:
			if d["kind"] == "panel":
				r31_panels.append(d["side"])
			else:
				r31_corners.append(d["corner"])
	_check("RING (3,1) panel count==2", r31_panels.size() == 2)
	_check("RING (3,1) panel sides=={0,1}", (0 in r31_panels) and (1 in r31_panels))
	_check("RING (3,1) corner count==1", r31_corners.size() == 1)
	_check("RING (3,1) corner==0 (NE)", r31_corners.size() == 1 and r31_corners[0] == 0)

	# Cell (2,2): the center WALL cell — must produce zero placements.
	var r22_count = 0
	for d in rv:
		if d["x"] == 2 and d["y"] == 2:
			r22_count += 1
	_check("RING (2,2) wall cell zero placements", r22_count == 0)

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()
