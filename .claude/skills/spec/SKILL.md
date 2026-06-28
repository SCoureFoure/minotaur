---
name: spec
description: >
  Capture or build a game rule/behavior against a durable spec, then leave it covered by a
  headless test. Runs the full loop: SPEC → REUSE-SCAN → CRITERIA→TESTS → BUILD → VERIFY →
  DEPOSIT. Works two ways — reverse-engineer an existing system into a spec, or build a new
  feature spec-first. The BUILD step dispatches through Warboss. Trigger when the user says
  "/spec <feature>", "write a spec for X", "capture X as a spec", "spec-driven", or asks to
  turn a requirement/finding into a regression test.
---

You are running the spec-driven loop for the **Minotaur** Godot project. A "spec" is the
durable source of truth for one rule/behavior: requirement + constraints + pinned decisions
+ acceptance criteria. Every feature leaves two artifacts — a **spec**
(`specs/<feature>.spec.md`) and a **headless test** (`scripts/test_<x>.gd`, the regression
guardrail). The spec pile is an *output*, not a precondition; it fills as systems are touched.

Read `specs/README.md` first — it holds the template, the rules, and the index.

## Two entry paths, one output

- **spec-in** — the user hands an explicit requirement. Consume it → spec → tests → build.
- **explore-out** — vague request, coverage gap, or a bug found while playing (often via the
  F12 screenshot tool — see memory `screenshot-debug-observability`). Discover the intended
  behavior (read the data modules + renderer; run the game / inspect a shot), write it down,
  fix to it.

Both converge on `{spec in repo, headless test in suite}`.

## The loop

```
1. SPEC
   - spec-in:    consume the given requirement.
   - explore-out: read the pure-data module(s) → renderer consumption → the grid/volume
                  convention. Confirm code matches reality; catch drift.
   - Surface every fork the spec forces ("is it supposed to do that?") and PIN it with
     AskUserQuestion before encoding behavior as correct. These rulings are the spec's value.
   - WRITE specs/<feature>.spec.md using the template in specs/README.md. Fill Constraints
     from CLAUDE.md invariants (connectivity guarantee, box-collision authority, pure-data
     layers, parametric scaling, the grid convention).

2. REUSE-SCAN
   - Find the existing module/renderer hooks to wire — do NOT rebuild. Honor inherited
     invariants and state them in the spec's Constraints. Keep rules in pure RefCounted
     modules (class_name + static); the renderer only instances what they return.

3. CRITERIA → TESTS
   - Each acceptance criterion → an assertion at the CHEAPEST layer that proves it:
     headless static test (scripts/test_*.gd) > headless smoke (scene loads) > F12 visual.
   - Mirror an existing test_*.gd (SceneTree: _initialize → _check(name,cond) → print
     ALL_PASS / FAILURES=n → quit). Prefer writing the failing test before the code.
   - You (the orchestrator) own the test as the membrane — define its expected values, do
     not let the builder invent them.

4. BUILD  — via Warboss (`/warboss-horde:delegate`)
   - The spec's Decisions + Acceptance criteria ARE the dense doer contract: exact entry
     point, input → expected pairs, every misreading killed, edge/OOB behavior named.
   - Cut into disjoint slices; tier each by residual entropy; dispatch the `doer` at the
     chosen model. Hand the doer the contract, NOT the verify command. (See the delegate
     skill for the full doctrine.) Trivial single-file specs may be built inline.

5. VERIFY — judge mechanically (you run it, never the doer)
   - Run the mapped suite: `godot --headless --path . --script res://scripts/test_<x>.gd`
     → ALL_PASS. (If a new class_name was added: `godot --headless --path . --import` once
     first, or the test errors with `Identifier "X" not declared`.)
   - If it touches the renderer: smoke
     `godot --headless --path . res://scenes/main.tscn --quit-after 12` (no errors).
   - Visual ACs: F12 in-game; read the PNG + sidecar JSON. Headless can't render shaders.
   - Red is a symptom — diagnose cause (test wrong / contract under-decided / wrong rung /
     genuine miss) before retrying. Bound retries.

6. DEPOSIT
   - spec + test committed in the same change set. Add the spec's row to the index table in
     specs/README.md. If the work produced a durable, non-obvious fact, also drop a note in
     .claude/memory (see that folder's README).
```

## Roles as gates (not headcount)
- **Implementer** — the Warboss `doer`, builds to the spec contract.
- **Validator** — you, judging by the mapped `test_*.gd` membrane; the doer never self-verifies.
- **Spec** — the contract both answer to.

## Worked example
`specs/maze_wall_autotile.spec.md` (AC1–AC7) ↔ `scripts/test_maze_walls.gd` — the edge-panel
wall autotile data, built through this loop via Warboss this session.

## Notes
- New behavior on an existing system still gets its own AC / spec amendment — never bundle
  silently. The spec is where "same feature or new one?" is answered.
- Minotaur has no UI explore rig / Semantics anchors (that's the Flutter sibling project).
  Its reachability layer is the **named geometry** (`Wall_L..`/`Floor_L..`), `debug_state()`,
  and the **F12 screenshot tool** — see memory `screenshot-debug-observability`.
