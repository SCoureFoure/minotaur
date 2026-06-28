extends Node
# Press F12 in-game to save a screenshot of the active viewport to res://screenshots/.
# Filename + sidecar .json carry context (camera pose, depth, what the camera centers on).
# Debug/dev tool.

const LEVEL_H := 3.0   # mirrors MazeRenderer.level_height default; only for the depth label

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		_shoot()

func _shoot() -> void:
	# Wait for the frame to finish drawing so the capture isn't blank/stale.
	await RenderingServer.frame_post_draw

	var vp := get_viewport()
	var cam := vp.get_camera_3d()
	var vp_size := vp.get_visible_rect().size
	var img := vp.get_texture().get_image()

	var ts := Time.get_datetime_dict_from_system()
	var ts_str := "%04d-%02d-%02d_%02d-%02d-%02d" % [ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second]

	var pos := Vector3.ZERO
	var yaw := 0.0
	var pitch := 0.0
	var depth := "unknown"
	var look_target := "none"
	if cam:
		pos = cam.global_position
		var eul := cam.global_transform.basis.get_euler()
		yaw = rad_to_deg(eul.y)
		pitch = rad_to_deg(eul.x)
		depth = "surface" if pos.y > -1.0 else ("L%d" % int(-pos.y / LEVEL_H))
		look_target = _ray_target(cam)

	# A) Fetch MazeRenderer world state safely.
	var ws := {}
	var maze := get_node_or_null("../MazeRenderer")
	if maze != null and maze.has_method("debug_state"):
		ws = maze.debug_state()

	# B) Map camera pose to the grid.
	var cs: float = float(ws.get("cell_size", 4.0))
	var lh: float = float(ws.get("level_height", 3.0))
	var cam_cell: Array
	var cam_level: int
	if cam:
		cam_cell = [roundi(pos.x / cs), roundi(pos.z / cs)]
		cam_level = -1 if pos.y > -1.0 else int(-pos.y / lh)
	else:
		cam_cell = [0, 0]
		cam_level = -1

	# C) Multi-ray "in view" sample — cached so the log line reuses the same result.
	var in_view_result: Array = _in_view(cam) if cam else []

	var base := "shot_%s_pos%d_%d_%d_yaw%d_%s_look-%s" % [
		ts_str, roundi(pos.x), roundi(pos.y), roundi(pos.z), roundi(yaw), depth, look_target]
	base = _sanitize(base)

	var dir_abs := ProjectSettings.globalize_path("res://screenshots/")
	DirAccess.make_dir_recursive_absolute(dir_abs)
	var png_path := "res://screenshots/%s.png" % base
	var json_path := "res://screenshots/%s.json" % base

	img.save_png(png_path)

	# D) Extended meta — all existing keys preserved, new keys appended.
	var meta := {
		"timestamp": ts_str,
		"camera_position": [pos.x, pos.y, pos.z],
		"camera_yaw_deg": yaw,
		"camera_pitch_deg": pitch,
		"depth": depth,
		"look_target": look_target,
		"viewport_size": [vp_size.x, vp_size.y],
		"camera_cell": cam_cell,
		"camera_level": cam_level,
		"in_view": in_view_result,
		"world_state": ws,
	}
	var f := FileAccess.open(json_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta, "  "))
		f.close()

	# E) Append one shot line to the shared run log — never truncate prior content.
	var log_path := "res://screenshots/run.log"
	var lf: FileAccess
	if FileAccess.file_exists(log_path):
		lf = FileAccess.open(log_path, FileAccess.READ_WRITE)
		if lf:
			lf.seek_end()
	else:
		lf = FileAccess.open(log_path, FileAccess.WRITE)
	if lf:
		lf.store_line("[shot] %s  cell=%s level=%d look=%s in_view=%s  file=%s.png" % [
			ts_str, str(cam_cell), cam_level, look_target, str(in_view_result), base])
		lf.close()

	print("[screenshot] ", ProjectSettings.globalize_path(png_path), "  (look-", look_target, ", ", depth, ")")

# Raycast straight out of the camera; return the name of the first solid node hit.
func _ray_target(cam: Camera3D) -> String:
	var space := cam.get_world_3d().direct_space_state
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 1000.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return "sky"
	var c = hit.get("collider")
	if c != null and c is Node:
		return String(c.name)
	return "unknown"

# Cast rays at 5 viewport fractions; return a sorted unique array of hit node names (or "sky").
func _in_view(cam: Camera3D) -> Array:
	var names := {}
	var vp_rect := get_viewport().get_visible_rect().size
	var fracs := [Vector2(0.5, 0.5), Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]
	var space := cam.get_world_3d().direct_space_state
	for fr in fracs:
		var sp := Vector2(vp_rect.x * fr.x, vp_rect.y * fr.y)
		var from := cam.project_ray_origin(sp)
		var dir := cam.project_ray_normal(sp)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 1000.0)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			names["sky"] = true
		else:
			var c = hit.get("collider")
			if c != null and c is Node:
				names[String(c.name)] = true
	var out: Array = names.keys()
	out.sort()
	return out

func _sanitize(s: String) -> String:
	return s.replace(" ", "").replace(":", "-").replace("(", "").replace(")", "").replace(",", "_")
