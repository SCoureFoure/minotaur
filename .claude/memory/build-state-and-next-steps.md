---
name: build-state-and-next-steps
description: Minotaur build state as of 2026-06-26 and the prioritized next steps
type: project
---

Build state (2026-06-26), all headless tests green:

- `maze_generator.gd` — single connected maze (backtracker + braid). 7/7.
- `maze_volume.gd` — `MazeVolume.generate(cols,rows,layers,seed,braid,links_per_pair)`
  → stacked layers + vertical links, provably 3D-connected. 10/10.
- `maze_autotile.gd` — `wall_mask` neighbor bitmask (for future mesh autotiling). 7/7.
- `maze_renderer.gd` — DESCENT build (`use_volume`): **island surface** (grass cap at
  Y≈0, water ring) on top; maze underground at `_layer_y(l) = -(l+1)*level_height`;
  `entrance_count` holes with ramps down; internal ramps at links; box collision.
  Player-count sizing via `size_for_players`. 6/6.
- All geometry is **box primitives + flat colors** — placeholder. Cave meshes only
  appear in the `cave_calibration` debug mode.

Verify: `godot --headless --path . --script res://scripts/test_*.gd` → `ALL_PASS`.

NEXT STEPS, prioritized (see [[workflow-core-before-polish]] — mechanics before polish):
1. **Loot loop** — treasure pickup deep + carry-back-to-surface = escape/win. Asset
   `Beach_Prop_Treasure_Chest` exists. This is the core motivation of
   [[game-concept-descent-heist]].
2. **Minotaur role** — bigger body, catch = overlap area, traps.
3. **Multiplayer skeleton** — ENet host/join, sync players + maze seed.
4. **Capture / rescue** mechanic.
5. **Visual pass (polish)** — cave-mesh skinning underground (use `wall_mask`),
   BinbunGrass on island, water/sky shaders. NOTE: grass `.tres` paths are BROKEN
   (`res://assets/BinbunGrass/...ground.gdshader` vs actual
   `res://assests/terrain/BinbunGrass/...grass.gdshader`); user OK'd moving/reorg.
   Also: ramp on/off smoothness + surface z-fight cleanup.

Delegation: this work runs under the warboss-horde (`/warboss-horde:delegate`) — pure
data/logic slices dispatched to doer (haiku/sonnet), visual slices iterated by the
WARBOSS with the user via F5 screenshots.
