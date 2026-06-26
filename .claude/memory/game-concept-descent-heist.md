---
name: game-concept-descent-heist
description: Minotaur's core game concept — vertical descent treasure-heist vs the minotaur
type: project
---

Minotaur is a **vertical descent treasure-heist**, not a flat hide-and-seek.

Core loop (decided 2026-06-26):
- Players start on the **surface of Minos** (the minotaur's island), find a labyrinth
  **entrance**, and descend **into the ground** — a vertical tower going DOWN.
- Motivation to go deeper: **loot/treasure**. Deeper = better loot but longer, deadlier escape.
- Players must **carry treasure back UP to the surface to escape** — extraction is the win.
- The **minotaur** hunts: lays **traps**, **captures** players. Possible **rescue** mechanic for captured players (undecided).
- **Social axis undecided**: coop vs competitive among players is the explicit open design
  question — goal is to let people "play how they want."

Architecture fit: the layered [[build-state-and-next-steps]] volume models this directly —
**layer 0 = surface, increasing layer index = deeper underground**; vertical links/ramps =
descent paths. The up/down traversal gets real stakes from the carry-loot-out loop. Cave
terrain kit (sloped Side/Corner meshes) = the ramps/cliffs between depth levels, not corridor walls.
