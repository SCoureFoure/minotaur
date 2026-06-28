---
name: overworld-grass-water-visuals
description: How the overworld grass/water look is wired in maze_renderer.gd and the knobs to tune it
type: project
---

Overworld (island surface + water ring) visuals, all in `scripts/maze_renderer.gd`,
built from `_build_volume()` in order: `_build_island()` → `_build_grass()` →
`_build_grass_carpet()` → `_build_water()`.

**Water** = `_build_water()` builds a flat RING via SurfaceTool — ONE continuous mesh
(4 bands / 8 tris) with a rectangular HOLE over the island footprint, wearing
`assests/shaders/water/water.gdshader`. Evolution: 4-box ring (seam between pieces) →
single full plane (no seam but flooded entrance pits) → single ring MESH with a hole
(no seam AND no flooding — current). Inner edge tucks `cell_size*0.5` under the grass cap
to hide the boundary. Shader has `cull_disabled` (line 13) so the ring shows regardless of
winding. Visual = one StaticBody3D "Water" (mesh only, no collision child); collision =
4 thin "WaterCollision" catch-boxes OUTSIDE the footprint (never over entrance pits, so
descent isn't blocked). `USE_CAUSTICS` OFF (caustics texture doesn't ship). wave/foam/normal
= procedural `NoiseTexture2D`. Foam thinned (was too white): `wave_foam_amount 0.25`,
`foam_start 0.5`, `foam_end 0.75`, `foam_exponent 3.0`, `edge_foam_depth_size 0.4`.

**Grass** = three layers stacked for a carpet look (user explicitly did NOT want bald green
with scattered tufts):
1. Island cap material = BinbunGrass `grass_ground_01.tres` (noise+gradient ground shader)
   — the carpet base. NOT flat `_calib_mat` green anymore. Its `noise_texture` is
   overridden in code with a finer FastNoiseLite (freq 0.05) to avoid big blotches.
2. `_build_grass_carpet()` = ONE MultiMesh of billboard QuadMesh blades using
   `grass_01.tres`. Coverage is EVEN: counts eligible tiles, `per_tile = min(40,
   cap/eligible)` with `cap=60000`, every tile gets `per_tile` blades (no bald far side).
   scale [0.7,1.5], wind on, cast_shadow OFF.
3. `_build_grass()` = sparser Synty 3D clump props (MultiMesh) sprinkled for depth,
   cast_shadow OFF.

Grass casts NO shadows (cast_shadow OFF on both MultiMeshes) — the DirectionalLight made
harsh blade shadows that read as splotchy.

**Color knob**: `_grass_gradient()` returns a 3-stop green `GradientTexture2D` shared by
BOTH ground + blade materials (`color_gradient` shader param) — edit those 3 `Color()`
stops to recolor all grass at once.

**Perf rule (user constraint)**: grass must stay GPU-instanced MultiMesh (one draw call
each), instance counts capped, never one node per blade/clump, no grass collision.

The BinbunGrass `.tres` files referenced a broken `res://assets/BinbunGrass/...` prefix
(CLAUDE.md flagged it); `grass_01.tres` + `grass_ground_01.tres` are now repathed to
`res://assests/terrain/BinbunGrass/...` (note double-s `assests` + `terrain/`).
See [[build-state-and-next-steps]].
