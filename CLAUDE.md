# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Default workflow — delegate through Warboss

**The primary development path is `warboss:delegate`, not direct implementation.** When a
request involves changing code/specs/assets beyond a single trivial edit, the default is:

1. **SLICE** the work into decided units (author the entropy out — each slice should have
   one correct implementation, no open design forks).
2. **DISPATCH** via the **`/warboss-horde:delegate`** skill: route each slice to the cheapest
   `doer` subagent that can satisfy it, at the model tier the slice warrants.
3. **JUDGE** each result yourself by running the slice's verify/test command (the headless
   `test_*.gd` suites are the membrane — see Specs below).

Handle work **inline (no delegate)** only for: one-line edits, read-only Q&A, or pure
investigation. **Spec-shaped** work goes through the **`/spec`** skill, whose BUILD step
already dispatches through Warboss. When unsure whether to delegate, prefer delegate.

A project `UserPromptSubmit` hook (`.claude/hooks/warboss-default.js`) restates this each turn.

## What this is

Godot 4.7 prototype of **Minotaur** — an asymmetric *vertical descent treasure-heist*:
players land on a surface island, descend through a multi-level underground labyrinth to
loot treasure, and must carry it back up to escape a hunting minotaur. See `README.md` for
the design roadmap and current status checklist.

## Commands

Godot exe used on this machine: `C:\Users\SCora\Desktop\Godot_v4.7-stable_win64.exe`
(`godot` below = that binary). Run from the project root.

```sh
# Run the game (or press F5 in the editor)
godot --path .

# Headless smoke test — load main scene, run a few frames, exit
godot --headless --path . res://scenes/main.tscn --quit-after 8

# Run ALL headless test suites (each prints ALL_PASS / FAILURES=n on the last line)
for t in test_maze test_maze_volume test_autotile test_sizing; do
  godot --headless --path . --script res://scripts/$t.gd
done

# Run a SINGLE test suite
godot --headless --path . --script res://scripts/test_maze_volume.gd
```

**Gotcha — `class_name` registration:** a test that references a `class_name` from a
**newly added** script fails with `Identifier "X" not declared` until the project is
re-scanned. Run `godot --headless --path . --import` once after adding/renaming a script
with a `class_name`, then run the test.

## Visual feedback — screenshots + paired data

The headless tests prove *logic*; **screenshots** are how *visuals* get verified. The loop:

- **Capture:** press **F12** in-game (`scripts/screenshot.gd`). Each shot writes three things
  to `screenshots/` (`res://screenshots/`): the **PNG**, a same-named **`.json` sidecar**
  (camera pose, `depth`, `look_target`, 5-ray `in_view`, full `world_state`), and one line
  appended to **`run.log`**. Geometry is named so the data is legible —
  `Floor_L<l>_<gx>_<gy>`, `Wall_L<l>_<gx>_<gy>`, `Ramp_l<l>_<gx>_<gy>`, `Entrance_<gx>_<gy>`.
- **Capture bot (no human):** `godot --path . res://scenes/capture.tscn` (**must run
  NON-headless** — the dummy renderer produces blank images). It builds a small fixed maze,
  flies a camera through the poses from `MazeCapture.waypoints()` (spawn, overhead,
  each entrance, each level), calls `Screenshotter.capture_view()` per pose, and self-quits —
  yielding a full labelled shot set (`..._<label>.png`) without anyone pressing F12. This is
  the autonomous "sight" path; `scripts/screenshot.gd:capture_view(cam, maze, label)` is the
  shared writer both F12 and the bot use. Waypoints are pure + tested (`test_capture_waypoints.gd`).
- **Read:** never interpret a PNG alone — use the **`/read-screenshot`** skill
  (`.claude/skills/read-screenshot/SKILL.md`), which reads the PNG *with* its `.json` sidecar
  so pixels are reconciled against ground truth (where the camera was, what it pointed at,
  the seed/sizing). Default target = newest shot; or name a substring/timestamp.

Background + the named-geometry convention: `.claude/memory/screenshot-debug-observability.md`.

## Architecture — the data → render pipeline

Three layers, deliberately split so the logic is headless-testable and the rendering is
isolated:

1. **`maze_generator.gd`** (`class_name MazeGenerator`, pure static API) — one 2D maze via
   recursive backtracker + braiding. Returns a grid; no nodes.
2. **`maze_volume.gd`** (`class_name MazeVolume`, pure static API) — stacks N per-layer
   grids and carves vertical links into one `{grids, links}` Dictionary. **Pure data, no
   nodes.** This is the 3D-connectivity authority.
3. **`maze_renderer.gd`** (`class_name MazeRenderer extends Node3D`) — the **only** Node;
   turns a volume into box geometry + collision, the island surface, ramps, and the player
   spawn point. `main.gd` reads `get_spawn_position()` to drop the player.

Keep logic in the pure-data layers (1, 2) and geometry in the renderer (3). New gameplay
rules that can be expressed as data + a pass/fail check belong in a static module with a
`test_*.gd` suite, not in the renderer.

### Grid convention (shared by all three)

- `grid[y][x]`: `0` = WALL, `1` = FLOOR. Row-major.
- Dimensions: `H = rows*2+1`, `W = cols*2+1`.
- Logical cell `(cx,cy)` center is at `grid[2*cy+1][2*cx+1]`, and **every cell center is
  always FLOOR** in a generated grid. Vertical links and entrances rely on this — any cell
  center is a valid shared-open connection between layers.

### Descent geometry (in `maze_renderer`, `use_volume = true`)

- Island surface = thin grass cap at `Y ≈ 0`; maze level `l` floor at
  `_layer_y(l) = -(l+1)*level_height` (deeper = more negative).
- Ramps are inclined boxes spanning one cell: angle `atan(level_height/cell_size)`. **This
  must stay below the player's `floor_max_angle` (default 45°)** or ramps become unwalkable.
  With `level_height=3`, `cell_size=4` → ~37°.
- Walls fill upward from each floor to the level above; the island cap is the level-0 ceiling.
- All collision is box primitives. Meshes/shaders are **visual-only** and not yet wired
  (see "Hybrid visual plan").

### Connectivity guarantee

`MazeGenerator` produces one connected component per layer; `MazeVolume` adds ≥1 vertical
link per adjacent layer pair → the whole volume is provably connected. `test_maze_volume.gd`
asserts this with a 3D flood fill. **Do not break the "≥1 link per adjacent pair" rule** —
it is the only thing keeping deep levels reachable.

## Conventions

- **Tests** are `SceneTree` scripts (`_initialize()` → `_check(name, cond)` → print
  `ALL_PASS` or `FAILURES=n`, then `quit()`). They take no framework. Mirror an existing
  `test_*.gd` when adding one.
- **Pure modules** `extends RefCounted` with a `class_name` and static functions only.
- **Sizing** is driven by `MazeRenderer.size_for_players(n)` when `auto_size_from_players`
  is on — keep it pure and test it (`test_sizing.gd`). Set `player_count` small for fast
  iteration. Renderer knobs are documented in `README.md`.
- **`cave_calibration = true`** is a debug mode: skips the maze and lays candidate meshes in
  a labeled row next to a 1m reference cube to read scale/pivot by eye.

## Specs (spec-driven workflow)

Durable rules/behaviors live as specs in **`specs/`** — one `<feature>.spec.md` per system,
each paired 1:1 with a headless `test_*.gd`. This formalizes the convention above: a rule
expressed as data + a pass/fail test gets a spec capturing its requirement, inherited
constraints, pinned decisions, and acceptance criteria. Start at `specs/README.md`.

Run the loop with the **`/spec`** skill (`.claude/skills/spec/SKILL.md`):
`SPEC → REUSE-SCAN → CRITERIA→TESTS → BUILD → VERIFY → DEPOSIT`. The **BUILD** step dispatches
through Warboss (`/warboss-horde:delegate`): a spec's acceptance-criteria block is the dense
`doer` contract, and the mapped `test_*.gd` is the membrane the WARBOSS judges by. Example:
`specs/maze_wall_autotile.spec.md` ↔ `scripts/test_maze_walls.gd`.

## Hybrid visual plan (not yet wired)

Topology is owned by the maze algorithms (connectivity guaranteed); **visuals** will be
owned by mesh autotiling. `maze_autotile.gd` (`wall_mask`) already computes the
wall-neighbor bitmask for this. Synty terrain kits in `assets/terrain` are **elevation-blend**
(sloped Side/Corner pieces, not vertical wall panels) — they suit the ramps/cliffs of a
descent, not flat corridor walls. The `assets/shaders` (sky/water) and `BinbunGrass` packs
are present but unwired; the grass `.tres` references `res://assets/BinbunGrass/...` while the
pack sits at `res://assets/terrain/BinbunGrass/` — repath when integrating.

Note: the assets directory is `assets` (`res://assets/...`). It was previously the
misspelled `assests`; a duplicate untracked `assets/` copy caused UID collisions that
broke `.glb` import, so the two were collapsed into the single tracked `assets/`.
