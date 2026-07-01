extends SceneTree
# Headless membrane for MazeCapture.waypoints(world_state).
# Mirrors the test_*.gd convention: _check() accumulates, prints ALL_PASS / FAILURES=n.

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("ok   ", name)
	else:
		print("FAIL ", name)
		_fail += 1

func _approx(a: float, b: float) -> bool:
	return abs(a - b) < 0.001

func _initialize() -> void:
	var ws := {
		"cell_size": 4.0,
		"level_height": 3.5,
		"layers": 3,
		"grid_w": 15,
		"grid_h": 15,
		"spawn": [20.0, 1.55, 44.0],
		"entrance_cells": [[9, 11], [5, 1]],
	}
	var wps: Array = MazeCapture.waypoints(ws)

	# Shape: each entry is a Dictionary with label:String, pos:Vector3, target:Vector3.
	_check("returns Array", wps is Array)
	_check("all entries well-formed", _all_well_formed(wps))

	# Count = 1 spawn + 1 overhead + len(entrances) + layers.
	_check("count = 2 + entrances + layers", wps.size() == 2 + 2 + 3)

	var by := _by_label(wps)

	# spawn: eye 0.6 above the spawn world position.
	_check("has spawn", by.has("spawn"))
	if by.has("spawn"):
		var s: Dictionary = by["spawn"]
		_check("spawn.pos.y = spawn_y + 0.6", _approx(s["pos"].y, 1.55 + 0.6))
		_check("spawn.pos.xz = spawn.xz", _approx(s["pos"].x, 20.0) and _approx(s["pos"].z, 44.0))

	# overhead: high above island center, looking straight down.
	_check("has overhead", by.has("overhead"))
	if by.has("overhead"):
		var o: Dictionary = by["overhead"]
		_check("overhead.pos.y = 40", _approx(o["pos"].y, 40.0))
		_check("overhead.target.y = 0", _approx(o["target"].y, 0.0))
		# center_x = (grid_w-1)/2 * cell_size = 7 * 4 = 28
		_check("overhead center x = 28", _approx(o["target"].x, 28.0))
		_check("overhead center z = 28", _approx(o["target"].z, 28.0))

	# entrance_0: target sits at the entrance cell world position (gx*cs, 0, gy*cs).
	_check("has entrance_0", by.has("entrance_0"))
	if by.has("entrance_0"):
		var e: Dictionary = by["entrance_0"]
		_check("entrance_0 target = (9*4, 0, 11*4)",
			_approx(e["target"].x, 36.0) and _approx(e["target"].y, 0.0) and _approx(e["target"].z, 44.0))

	# level_1: eye at that layer's floor Y = -(1+1)*level_height, +0.6 eye.
	_check("has level_1", by.has("level_1"))
	if by.has("level_1"):
		var l: Dictionary = by["level_1"]
		_check("level_1.pos.y = -(2)*3.5 + 0.6", _approx(l["pos"].y, -(2) * 3.5 + 0.6))

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()

func _all_well_formed(wps: Array) -> bool:
	for w in wps:
		if not (w is Dictionary):
			return false
		if not (w.has("label") and w.has("pos") and w.has("target")):
			return false
		if not (w["label"] is String and w["pos"] is Vector3 and w["target"] is Vector3):
			return false
	return true

func _by_label(wps: Array) -> Dictionary:
	var d := {}
	for w in wps:
		if w is Dictionary and w.has("label"):
			d[w["label"]] = w
	return d
