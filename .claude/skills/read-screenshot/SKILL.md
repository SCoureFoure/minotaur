---
name: read-screenshot
description: >
  Read a Minotaur in-game screenshot together with its paired data files so the image is
  interpreted grounded in ground truth (camera pose, depth, what's in view, world state).
  Screenshots are captured in-game with F12 (see scripts/screenshot.gd) and land in
  res://screenshots/ as a PNG + a same-named .json sidecar, with one line appended to
  res://screenshots/run.log. Trigger when the user says "/read-screenshot", "look at the
  screenshot", "read the latest shot", "what does the screenshot show", or refers to a
  saved capture.
---

You are inspecting a screenshot of the **Minotaur** Godot game. Never read the PNG alone —
each shot has a paired `.json` sidecar that is ground truth for what the camera was, where
it was, and what geometry it pointed at. Read both; reconcile the pixels against the data.

## Where shots live

- Folder: `screenshots/` (i.e. `res://screenshots/`), project root.
- Per shot: `shot_<ts>_pos<x>_<y>_<z>_yaw<deg>_<depth>_look-<target>.png` plus a `.json`
  sidecar of the **same base name**.
- `screenshots/run.log` — one line per shot (ts, cell, level, look, in_view, file).

## Resolve which shot

Default = **most recent**. Map the user's words to a file:

1. No target given, or "latest"/"last": newest `.png` by mtime.
   `ls -t screenshots/*.png | head -1`
2. A substring (e.g. "the L2 one", "look-sky", a timestamp): match the filename.
   `ls screenshots/*.png | grep -i <substring>`
3. "all recent" / a count: take the newest N.

If nothing matches, list the newest few names and ask which.

## Read the pair

1. **Read the `.json` sidecar first.** Keys: `camera_position`, `camera_yaw_deg`,
   `camera_pitch_deg`, `depth` (`surface`/`L0`/`L1`…), `camera_cell`, `camera_level`,
   `look_target` (single ray hit), `in_view` (5-ray sample of node names), and
   `world_state` (`seed`, `cols/rows/layers`, `cell_size`, `level_height`, `grid_w/h`,
   `entrance_cells`, `water_level`, `spawn`). Node names encode location:
   `Floor_L<l>_<gx>_<gy>`, `Wall_L<l>_<gx>_<gy>`, `Ramp_l<l>_<gx>_<gy>`,
   `Entrance_<gx>_<gy>`, plus surface `Grass_*`/`Sand_*`/`Water`.
2. **Read the PNG** (Read tool renders it visually).
3. Optionally tail `run.log` for neighbouring shots / sequence context.

## Report

Lead with the answer to what the user asked. Then ground the image in the data:
- Where the camera is (cell, level/depth, yaw/pitch) and what it's looking at
  (`look_target`) — so "the wall on the right" becomes "`Wall_L1_10_12`".
- Reconcile anything surprising in the pixels with `in_view` + `world_state`. Holes,
  see-through gaps, floating geometry, z-fighting, lighting — name the specific node and,
  when relevant, the `maze_renderer.gd` builder responsible.
- If the finding is a durable rule/bug, offer to capture it (memory note or `/spec`).

Map world coords ↔ grid with `world_state`: cell `(gx,gy)` center is at world
`(gx*cell_size, _layer_y(l), gy*cell_size)`, and `_layer_y(l) = -(l+1)*level_height`.
Background on the tool + named-geometry convention: `.claude/memory/screenshot-debug-observability.md`.
