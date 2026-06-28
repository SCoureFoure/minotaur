# Spec — Maze wall autotile (edge-panel data)

> Status: active · Feature: maze_wall_autotile · Added: 2026-06-28
> Source of truth for `MazeWalls.wall_visuals(grid)` — which wall visual pieces go where,
> given one maze layer's grid. Pure data; the renderer instances meshes from it.

## Requirement
Given a single maze layer's 2D grid (`grid[y][x]`, 0=wall 1=floor), produce the placements
for an **edge-panel** wall skin: for each FLOOR cell, a wall **panel** sits on each side
whose neighbor is a wall, and a corner **pillar** sits at each corner where the two flanking
sides are both walls. The output is pure data (`Array` of placement `Dictionary`); the
renderer (`maze_renderer.gd`) maps each placement to a KayKit mesh transform. This is the
"visuals owned by autotiling, topology owned by the maze algorithms" split.

## Out of scope (future work)
- **Mesh transforms / rendering** — the renderer's `_build_wall_visuals()` consumes this and
  positions `wall.gltf`/`wall_pillar.gltf`; that mapping is verified by smoke + F12, not here.
- **8-neighbor diagonal corner refinement** (inner vs outer corner meshes) — current scheme
  uses only the two flanking sides; a future amendment may add diagonal awareness.
- **Floors / ceilings / ramps** — separate concerns; see memory `dungeon-mesh-pipeline-kaykit`
  and the [[ramp-rework-pin]].

## Constraints (inherited)
- **Pure data, no nodes.** `MazeWalls` is `extends RefCounted`, `class_name MazeWalls`,
  static functions only (project convention for rule modules).
- **Box collision stays the authority.** This module is visual-placement data only; it never
  touches collision or the connectivity guarantee.
- **Grid convention.** `grid[y][x]`: 0=WALL, 1=FLOOR, row-major. Out-of-bounds counts as WALL.

## Decisions (pinned 2026-06-28)
- **Only FLOOR cells emit** placements. Wall cells emit nothing.
- **Side index**: 0=N, 1=E, 2=S, 3=W. Neighbor coords N=(x,y-1) E=(x+1,y) S=(x,y+1) W=(x-1,y).
- **Corner index**: 0=NE, 1=SE, 2=SW, 3=NW — named by the two sides that flank it. A corner
  emits **only when BOTH flanking sides are walls**: NE→N&E, SE→S&E, SW→S&W, NW→N&W.
  (Opposite-side pairs, e.g. N&S, never make a corner.)
- **Emission order** per floor cell: panels first (side order N,E,S,W), then corners
  (corner order NE,SE,SW,NW).
- **Rotation** is `float(index) * 90.0` degrees (panel uses `side`, corner uses `corner`).
- **Out-of-bounds = WALL** (so border cells get panels).
- **Placement dict shapes**:
  - panel: `{"kind":"panel", "x":gx, "y":gy, "side":s, "rot": s*90.0}`
  - corner: `{"kind":"corner", "x":gx, "y":gy, "corner":c, "rot": c*90.0}`

## Acceptance criteria (Given / When / Then)
1. **AC1 — fully enclosed floor cell.** Given `[[0,0,0],[0,1,0],[0,0,0]]`, then
   `wall_visuals` returns exactly 8 placements: 4 panels (all sides) + 4 corners (all corners).
2. **AC2 — out-of-bounds is wall.** `is_wall(grid,-1,0) == true`; `is_wall(grid,1,1) == false`
   for the center floor cell.
3. **AC3 — open interior emits nothing.** Given all-floor `[[1,1,1],[1,1,1],[1,1,1]]`, the
   center cell `(1,1)` contributes 0 placements (all neighbors floor).
4. **AC4 — corner needs BOTH flanking sides (NW).** In the ring
   `[[0,0,0,0,0],[0,1,1,1,0],[0,1,0,1,0],[0,1,1,1,0],[0,0,0,0,0]]`, cell `(1,1)` has exactly
   2 panels (sides {0,3} = N,W) and exactly 1 corner (corner 3 = NW).
5. **AC5 — opposite walls make no corner.** In the ring, cell `(2,1)` (walls N and S, floors
   E and W) has 2 panels (sides {0,2}) and **0 corners**.
6. **AC6 — NE corner.** In the ring, cell `(3,1)` (walls N and E) has 2 panels (sides {0,1})
   and exactly 1 corner (corner 0 = NE).
7. **AC7 — wall cells silent.** In the ring, the center wall cell `(2,2)` contributes 0
   placements.

## Verifies-with
- Headless suite: `scripts/test_maze_walls.gd` (AC1–AC7, named assertions) —
  `godot --headless --path . --script res://scripts/test_maze_walls.gd` → `ALL_PASS`.
  (After adding/renaming a `class_name`, run `godot --headless --path . --import` once first.)
- Renderer consumption (`_build_wall_visuals`): verified by smoke
  (`godot --headless --path . res://scenes/main.tscn --quit-after 12`) + F12 — corridor walls
  read as KayKit brick panels with corner pillars, correctly oriented per side.
