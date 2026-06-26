extends SceneTree
# Headless AC test for game_settings.gd. Run:
#   godot --headless --path . --script res://scripts/test_game_settings.gd

var _fail := 0

func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS  ", name)
	else:
		print("FAIL  ", name)
		_fail += 1

func _initialize() -> void:
	var GS = load("res://scripts/game_settings.gd")

	# Remove any leftover temp file from a previous run.
	var d := DirAccess.open("user://")
	if d and d.file_exists("test_gs.cfg"):
		d.remove("test_gs.cfg")

	# T1: fresh instance after reset_to_defaults -> player_count == 4
	var inst = GS.new()
	inst.reset_to_defaults()
	_check("T1 default player_count == 4", inst.get_value("match", "player_count") == 4)

	# T2: after reset_to_defaults -> cave_calibration == false
	_check("T2 default cave_calibration == false", inst.get_value("debug", "cave_calibration") == false)

	# T3: set_value then get_value reflects the new value
	inst.set_value("match", "player_count", 7)
	_check("T3 set player_count -> 7", inst.get_value("match", "player_count") == 7)

	# T4: round-trip save/load between two independent instances
	var a = GS.new()
	a.save_path = "user://test_gs.cfg"
	a.reset_to_defaults()
	a.set_value("match", "cols", 19)
	var b = GS.new()
	b.save_path = "user://test_gs.cfg"
	b.load_from_disk()
	_check("T4 round-trip cols == 19", b.get_value("match", "cols") == 19)

	# T5: missing file -> silently falls back to defaults
	var inst5 = GS.new()
	inst5.save_path = "user://does_not_exist_xyz.cfg"
	inst5.load_from_disk()
	_check("T5 missing file -> cols == 12", inst5.get_value("match", "cols") == 12)

	# T6: key erased from data falls back to DEFAULTS, not a crash
	var inst6 = GS.new()
	inst6.reset_to_defaults()
	inst6.data["match"].erase("rows")
	_check("T6 erased key falls back to DEFAULTS rows == 12", inst6.get_value("match", "rows") == 12)

	# T7: deep-copy isolation — mutating data must not corrupt the DEFAULTS const
	var inst7 = GS.new()
	inst7.reset_to_defaults()
	inst7.data["match"]["cols"] = 999
	_check("T7a DEFAULTS const untouched cols == 12", inst7.DEFAULTS["match"]["cols"] == 12)
	var inst7b = GS.new()
	inst7b.reset_to_defaults()
	_check("T7b new instance reset_to_defaults cols == 12", inst7b.get_value("match", "cols") == 12)

	if _fail == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=", _fail)
	quit()
