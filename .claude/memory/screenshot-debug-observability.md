---
name: screenshot-debug-observability
description: The F12 screenshot tool, debug_state(), run.log, and named geometry — how to see the game and sync shots to world state
type: project
---

How to get visual + world-state feedback from the running game (headless can't render
shaders, so this is the loop for judging visuals).

**F12 in-game** (`scripts/screenshot.gd`, a `Screenshotter` Node in `main.tscn`) saves to
`res://screenshots/` (= repo `screenshots/`, gitignored): a PNG + a sidecar `.json`. The
filename encodes timestamp + camera pos + yaw + depth + `look-<centered node name>`.

**The JSON is self-contained**: camera pose/pitch, `camera_cell` [gx,gy], `camera_level`
(-1 = surface), `in_view` (5-ray frustum sample → set of named nodes visible), and
`world_state` = the full `MazeRenderer.debug_state()` dict (seed, cols/rows/layers,
level_height, cell_size, grid_w/h, entrance_cells, water_level, spawn). The seed means the
exact maze can be regenerated headlessly to reason about geometry.

**`MazeRenderer.debug_state() -> Dictionary`** is the single source of truth (clean seam,
like `get_spawn_position()`). `main.gd._write_build_log()` writes a `[build]` block to
`res://screenshots/run.log` on each launch; each F12 appends a `[shot]` line. Append-only,
chronological — read it to correlate shots to the generated world.

**Geometry is named by type + grid cell** so raycast targets are meaningful:
`Sand_gx_gy` / `Grass_gx_gy` (island cap, shore vs interior), `Floor_L{l}_gx_gy`,
`Wall_L{l}_gx_gy`, plus existing `Water`/`WaterCollision`/`Ramp_*`/`Entrance_*`/`GrassCarpet`.

**Workflow**: user F5 → F12 on anything worth showing → points Claude at `screenshots/`.
Claude reads the PNG + JSON + run.log = render + seed + grid location + what's in frame, no
verbal description needed. F12 capture needs a real GPU (headless `--headless` disables
rendering), so the user runs it, not Claude. See [[overworld-grass-water-visuals]].

A turnkey screenshot MCP (Agent Tools, Godot MCP Pro, GDAgent) was considered but skipped —
the DIY tool covers the one gap (Claude seeing the render) with no plugin/MCP setup.
`tomyud1/godot-mcp` specifically has NO screenshot capture.
