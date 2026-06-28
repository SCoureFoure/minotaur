# Project memory (Minotaur)

Durable, project-specific notes for Claude Code, versioned with the repo. Each file is one
fact with frontmatter (`name`, `description`, `type`). Cross-links use `[[name]]`.

- [game-concept-descent-heist](game-concept-descent-heist.md) — the core game: vertical loot-extraction dungeon vs the minotaur
- [build-state-and-next-steps](build-state-and-next-steps.md) — what's built + prioritized next steps
- [workflow-core-before-polish](workflow-core-before-polish.md) — build mechanics first, defer polish/textures
- [overworld-grass-water-visuals](overworld-grass-water-visuals.md) — how island grass/water shaders are wired + tuning knobs
- [screenshot-debug-observability](screenshot-debug-observability.md) — F12 screenshot tool, debug_state(), run.log, named geometry — the visual-feedback loop
- [dungeon-mesh-pipeline-kaykit](dungeon-mesh-pipeline-kaykit.md) — how tunnel walls/floors/ceilings are skinned with KayKit meshes (autotile + MultiMesh, two-sided, box collision)
- [ramp-rework-pin](ramp-rework-pin.md) — PINNED: ramps too basic, break >45° as level_height grows; rework later

> Auto-recall reads the global path (`~/.claude/projects/<this-project>/memory/`), which now
> holds only a pointer back here. Keep these in sync; treat this folder as the source of truth.
