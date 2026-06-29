---
name: floor-shaft-visual-holes
description: Why see-through "holes in the floor" appear in dungeon screenshots — descent shafts, visual-only, not a fall-through bug
metadata:
  type: project
---

Screenshots sometimes show see-through holes in the dungeon floor (you can see the level
below, or a column straight up to the green surface grass). **This is the vertical
descent shafts, not a bug.** Confirmed by reading `screenshots/*.png` on 2026-06-28.

**Cause (in `scripts/maze_renderer.gd`):**
- At each vertical link, the shallower layer's floor is removed for the WHOLE cell — both
  collision box (`_volume_floor` skipped via the `holes` set, ~L269-284) and visual tile
  (`_build_floor_visuals`, same `holes` set, ~L709-726).
- The only thing filling that cell opening is a thin (0.25) tilted ramp slab (`_ramp`,
  ~L608-636). Its flat footprint covers the cell in XZ, but because it's tilted + thin,
  most of the square opening is empty air → you see through to the adjacent level.
- Entrances do the same through the grass cap; an entrance cell stacked over link cells
  makes a see-through column from surface to a deep level (the green-grass-through-floor).

**Ruled out:** floor-tile tiling/scale. Probed `floor_tile_large.gltf` = exactly 4×4,
centered, matches `WALL_NATIVE=4.0`. No tile gaps.

**Gameplay impact: none.** Collision floor is full `cell_size` everywhere except link
cells, and every link cell has a ramp — no orphan holes, can't fall through unexpectedly.
Purely visual.

**If fixing later:** widen/thicken the ramp, or add a 3/4-tile floor collar around each
shaft so the opening is ramp-width not full-cell. Related: [[ramp-rework-pin]],
[[dungeon-mesh-pipeline-kaykit]], [[screenshot-debug-observability]].
