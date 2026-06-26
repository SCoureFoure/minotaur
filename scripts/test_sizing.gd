extends SceneTree
# Headless AC test for MazeRenderer.size_for_players. Run:
#   godot --headless --path . --script res://scripts/test_sizing.gd

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

func _initialize() -> void:
	_check("S1 n=1 -> 5x5x2", MazeRenderer.size_for_players(1) == Vector3i(5, 5, 2))
	_check("S2 n=2 -> 6x6x3", MazeRenderer.size_for_players(2) == Vector3i(6, 6, 3))
	_check("S3 n=4 -> 8x8x4", MazeRenderer.size_for_players(4) == Vector3i(8, 8, 4))
	_check("S4 n=8 -> 12x12x6", MazeRenderer.size_for_players(8) == Vector3i(12, 12, 6))
	_check("S5 n=100 clamps high -> 20x20x6", MazeRenderer.size_for_players(100) == Vector3i(20, 20, 6))
	_check("S6 n=0 clamps low -> 4x4x2", MazeRenderer.size_for_players(0) == Vector3i(4, 4, 2))

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()
