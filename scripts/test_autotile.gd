extends SceneTree
# Headless AC test for maze_autotile.gd. Run:
#   godot --headless --path . --script res://scripts/test_autotile.gd

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

func _initialize() -> void:
	var g = [
		[0, 0, 0],
		[0, 1, 1],
		[0, 1, 0],
	]
	_check("B1 interior floor mask=9", MazeAutotile.wall_mask(g, 1, 1) == 9)
	_check("B2 edge floor OOB east mask=7", MazeAutotile.wall_mask(g, 2, 1) == 7)
	_check("B3 corner wall cell mask=15", MazeAutotile.wall_mask(g, 0, 0) == 15)

	var open = [
		[1, 1, 1],
		[1, 1, 1],
		[1, 1, 1],
	]
	_check("B4 fully-open center mask=0", MazeAutotile.wall_mask(open, 1, 1) == 0)

	# Extra independent checks (not handed to doer).
	# Single isolated floor in all-wall 3x3: all 4 neighbors wall -> 15.
	var iso = [
		[0, 0, 0],
		[0, 1, 0],
		[0, 0, 0],
	]
	_check("B5 isolated floor mask=15", MazeAutotile.wall_mask(iso, 1, 1) == 15)
	# Open-grid edge cell (0,1): N=(0,0)=1->0, E=(1,1)=1->0, S=(0,2)=1->0, W OOB->+8 => 8
	_check("B6 open-grid west-edge mask=8", MazeAutotile.wall_mask(open, 0, 1) == 8)
	# Open-grid top edge (1,0): N OOB->+1, others floor => 1
	_check("B7 open-grid north-edge mask=1", MazeAutotile.wall_mask(open, 1, 0) == 1)

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()
