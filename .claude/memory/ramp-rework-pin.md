---
name: ramp-rework-pin
description: Pinned issue — descent ramps are too basic and break as level_height grows; rework later
type: project
---

**Pinned for later (user, 2026-06-28): rework the descent ramps.** Not urgent — flagged to
fix when level heights become variable.

Current ramps (`_ramp` in `maze_renderer.gd`) are a single inclined slab spanning one cell:
angle = `atan(level_height / cell_size)`. That stays walkable only while
`level_height <= cell_size` (≤45°, the player's default `floor_max_angle`). Once
level_height > cell_size it exceeds 45° and becomes unwalkable — e.g. level_height=5,
cell_size=4 → ~51° (the user hit exactly this while testing).

Two coupled problems to solve together in the rework:
1. **Walkability** — switchback / multi-cell ramps or KayKit `stairs_modular_*` so the angle
   stays walkable regardless of level_height.
2. **Visual gaps** — vertical-link drop cells are left floorless so the ramp can pass; the
   basic slab doesn't fill them, so they read as holes in the floor (visible in screenshots).
   The rework should make the descent read as a real, filled stairwell.

Context: level_height is expected to become variable / driven by other factors later, so the
ramp solution must be parametric, not tuned for a fixed height. A TODO(ramps) comment marks
the spot above `_ramp`. See [[dungeon-mesh-pipeline-kaykit]].
