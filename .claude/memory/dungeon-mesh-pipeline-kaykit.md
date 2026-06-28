---
name: dungeon-mesh-pipeline-kaykit
description: How the underground tunnel walls/floors/ceilings are skinned with KayKit meshes via the autotile data
type: project
---

The descent maze is skinned with KayKit DungeonRemastered meshes (in `assests/props/...`),
all driven from data, all in `maze_renderer.gd`. Topology/collision stay as invisible boxes;
visuals are GPU-instanced meshes on top (the "hybrid visual plan" from CLAUDE.md, now real).

**Collision vs visual split**: `_volume_wall`/`_volume_floor` build StaticBody3D + BoxShape3D
ONLY (no mesh — the old colored placeholder boxes were removed). Cells are named
`Wall_L{l}_gx_gy` / `Floor_L{l}_gx_gy` for raycast/screenshot reference.

**Walls** (`_build_wall_visuals` + `MazeWalls.wall_visuals`): edge-panel autotile. For each
floor cell, `wall.gltf` panel on each side facing a wall + `wall_pillar.gltf` at concave
corners. Two MultiMeshes "WallPanels"/"WallPillars" (one draw call each).

**Floors** (`_build_floor_visuals`): `floor_tile_large.gltf`, one per non-hole floor cell,
MultiMesh "FloorTiles", seated at `base_y + 0.02` (up against wall base molding).

**Ceilings**: deeper levels get their ceiling FOR FREE — floor tiles are two-sided, so
level L's floor is level L+1's ceiling. The TOP level (layer 0) has no level above, so
`_build_ceiling_visuals` adds a "CeilingTiles" layer just under the grass cap
(`ISLAND_TOP - ISLAND_THICK - 0.05`) over layer-0 floor cells, EXCLUDING entrance cells
(those stay open to the sky).

**Two-sided**: KayKit meshes render single-sided (see-through from behind). `_two_sided_mat`
duplicates the mesh's surface-0 material and sets `cull_mode = CULL_DISABLED`, applied as
material_override to walls/pillars/floors/ceiling. This is what makes floors visible from
below (= ceilings) and stops entrance-shaft see-through.

**Scaling is parametric**: KayKit grid is 4m (= default cell_size). All meshes scale
`(cell_size/4, level_height/4, cell_size/4)` via `WALL_NATIVE := 4.0`, so they track grid +
level-height changes. `KAYKIT_GLTF` const holds the gltf base path.

Known visual gap: vertical-link drop cells are floorless (a ramp passes through), so they
read as holes in the floor — tied to the [[ramp-rework-pin]]. See [[dungeon-autotile-walls]]
for the pure data layer and [[screenshot-debug-observability]] for how to inspect it.
