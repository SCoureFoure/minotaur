# Specs

Durable source of truth for the game's **rules and behavior**. One file per feature:
`specs/<feature>.spec.md`. Each spec pairs with a headless test suite (`scripts/test_*.gd`)
— the regression guardrail. The spec pile is an **output**, not a precondition: it fills
as systems are touched.

This sits directly on top of the project's existing convention (see `CLAUDE.md`): *new
rules that can be expressed as data + a pass/fail check belong in a pure static module with
a `test_*.gd` suite.* A spec is that rule written down — requirement + constraints + pinned
decisions + acceptance criteria — before (or alongside) the module and its test.

## Two entry paths, one output

- **spec-in** — an explicit requirement is handed in → spec → tests → build.
- **explore-out** — behavior discovered while probing or fixing (often via the F12
  screenshot tool, see memory `screenshot-debug-observability`) → written down → fixed to
  → captured as `{spec, test}`.

Both converge on `{spec in repo, headless test in suite}`.

## How this drives Warboss (the build engine)

The spec **is** the contract the WARBOSS (`/warboss-horde:delegate`) needs. The two loops
are the same loop:

| spec step | warboss step |
|-----------|--------------|
| Decisions pinned + AC as Given/When/Then | author the entropy out — dense contract, `input → expected`, kill misreadings |
| Reuse-scan (wire existing modules, don't rebuild) | cut into disjoint slices, reuse not rebuild |
| AC ↔ a `test_*.gd` assertion at the cheapest layer | the **membrane** the WARBOSS runs to judge |
| Build | dispatch the `doer` at the chosen rung |
| Verify | judge mechanically (run the suite) |
| Deposit | commit `{spec, test}` |

So a spec's **Acceptance criteria block is the doer contract**, and the `test_*.gd` mapped
1:1 to those ACs is the **membrane**. Run the `/spec` skill to drive the whole loop.

## Rules

- Every non-trivial rule/behavior deposits `{spec, test_*.gd}`.
- Acceptance criteria map **1:1 to assertions at the cheapest layer that proves them**:
  - **headless static test** (`scripts/test_*.gd`, pure data) — preferred; deterministic.
  - **headless smoke** (`godot --headless --path . res://scenes/main.tscn --quit-after N`)
    — proves it loads/builds without error.
  - **F12 screenshot** — only for visual ACs a headless run can't judge (shader/mesh look).
    Record the expected look in words; the PNG + sidecar JSON is the evidence.
- New behavior on an existing system gets its own AC / spec amendment — never bundle
  silently. The spec is where "same feature or new one?" is answered.
- Pin every fork before encoding it as correct (`AskUserQuestion` for Leader calls).
- Keep the data→render split: rules live in pure `RefCounted` modules with a `class_name`
  and static functions; the renderer only instances what they return. Specs cover the data
  layer; the renderer is verified by smoke + F12.

## Spec template

```markdown
# Spec — <feature title>

> Status: active · Feature: <slug> · Added: <YYYY-MM-DD>
> Source of truth for <what behavior>.

## Requirement
<one paragraph: what happens and why>

## Out of scope (future work)
- <anything deliberately not covered; link the spec that will, if known>

## Constraints (inherited)
- <the invariants this rides on — e.g. connectivity guarantee, box-collision authority,
  pure-data layers, parametric scaling. Pull from CLAUDE.md.>

## Decisions (pinned <date>)
- <each fork resolved: conventions, indexing, defaults, edge/OOB behavior>

## Acceptance criteria (Given / When / Then)
1. AC1 — <happy path, as concrete input → expected>
2. AC2 — <edge / validation; include a case that fails under the wrong reading>
3. ... (one per distinct behavior)

## Verifies-with
- Headless suite: `scripts/test_<x>.gd` — `godot --headless --path . --script res://scripts/test_<x>.gd`
- Smoke (if it touches the renderer): `godot --headless --path . res://scenes/main.tscn --quit-after 12`
- F12 (visual ACs only): <what to look for>, or "n/a"
```

## Index

| Spec | Feature | Status |
|------|---------|--------|
| [maze_wall_autotile](maze_wall_autotile.spec.md) | Edge-panel wall autotile data (`MazeWalls`) | active |
