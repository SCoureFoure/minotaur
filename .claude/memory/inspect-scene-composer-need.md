---
name: inspect-scene-composer-need
description: Dev-tooling gap — need a way to compose focused custom scenes (specific grid matrix + materials + exact camera) instead of only whole-maze waypoint captures
metadata:
  type: feedback
---

The `capture.tscn` waypoint bot ([[capture]] skill) captures the WHOLE maze from a
fixed pose list (spawn/overhead/entrance/level). It cannot **focus**: isolate a single
feature (e.g. the level-0 ceiling seam), aim the camera at an exact pose/target, or
arrange a specific small grid of cells/materials to study one interaction. Static shots
also miss **motion** artifacts (z-fighting flicker reads fine in a still frame).

**Why:** when debugging a specific visual bug I wasted a round guessing from whole-maze
stills and adding a throwaway look-up pose. The right tool is a **parametric inspect
scene composer**: hand-specify (a) a tiny grid matrix per layer (explicit wall/floor/
ramp/entrance cells) OR a cropped region of a real seed, (b) which builders run + per-
material overrides, (c) an exact camera pos+look_target (and/or an orbit / multi-angle),
optionally (d) a small camera jitter + frame-diff to surface z-fighting that a single
still hides. Reuse `maze_renderer.gd` builders by injecting a custom `{grids, links}`
volume instead of the random generator.

**How to apply:** build this before the next visual-debug task; it makes focused visual
slices cheap and delegatable (composer produces the artifact; WARBOSS judges it). Relates
to [[capture]] and the screenshot observability convention.
