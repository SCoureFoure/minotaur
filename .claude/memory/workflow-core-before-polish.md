---
name: workflow-core-before-polish
description: How the user wants Minotaur built — core mechanics first, polish/textures later
type: feedback
---

For Minotaur, land **core game concepts first** (traversal, descent, loot/extraction,
minotaur, multiplayer skeleton), THEN layer on polish, textures, and mesh skinning.

**Why:** user wants playable core loop validated before investing in look. Stated 2026-06-26
while ramps were rough ("not very smooth to get on and off") — he chose to defer ramp polish
and keep moving on mechanics.

**How to apply:** when a feature is functional-but-ugly, confirm the mechanic works, note the
polish as a deferred TODO, and move to the next core concept rather than perfecting visuals.
Build/test knobs (e.g. maze size, [[game-concept-descent-heist]] player count) count as core —
they make iteration cheaper. Cave-mesh skinning is polish; defer until mechanics are in.
