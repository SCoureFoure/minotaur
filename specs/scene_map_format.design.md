# Design draft — Declarative Scene / Map Format (+ focused inspect)

Status: **DRAFT / options open.** Not a spec yet — a menu of choices to pick from,
then formalize via `/spec`. Origin: needing to *focus* the capture bot on one feature,
which grew into "an authored map format with layered attribute modifiers."
See memory `inspect-scene-composer-need.md`.

## The problem (two needs, one format)

1. **Focus / inspect**: compose a tiny, exact arrangement (a few cells, chosen
   materials, precise camera) to study ONE interaction — instead of only whole-maze
   waypoint captures. Static shots also miss motion artifacts (z-fight flicker).
2. **Authored maps with modifiers**: a base grid (JSON/YAML) + *layered attributes*
   that transform individual objects — e.g. a base floor block **+** `crawl_hole`
   attribute → a gap a small character can crawl through, a big one can't.

Same format serves both: a small authored map IS the focus fixture.

## What exists today (what the format compiles down to)

- `maze_generator` → `grid[y][x]`, `0=wall / 1=floor`. **That bit is the entire
  per-cell vocabulary.**
- `maze_volume` → stacks grids + carves `links` → `{grids, links}` (pure data).
- `maze_renderer` → boxes (floor/wall/ramp) + KayKit visual skin, from that data.
- **No per-cell attributes / materials / variants exist.** Ramps + entrances live in
  side-channels (`links`, `entrance_cells`), not on the cell. Every new attribute =
  new renderer interpretation + a `test_*.gd`.

---

## DECISION 1 — Base representation

- **1A. Dense 2D array of type codes** (per layer). Readable, mirrors `grid[y][x]`.
  `[["#","#","#"], ["#",".","."], ...]`
- **1B. Sparse `"x,y": {...}` dict.** Compact for large / mostly-empty maps; worse to
  eyeball.
- *Lean: **1A** for authored/inspect maps (small, want to read them); revisit 1B only
  if maps get large.*

## DECISION 2 — Modifier model (the core idea)

How "layer an attribute onto an object to change it" is expressed.

- **2A. Per-cell object.** Each cell carries its own mods:
  `{ "type":"floor", "mods":[ {"crawl_hole":{"size":"small"}} ] }`
  - + one cell's full state is local and obvious.
  - − tedious to apply an attribute across many cells; verbose.
- **2B. Layered passes (image-layer style).** Base type array + stacked sparse
  "modifier layers", each a coord→attr map, applied in order.
  - + literally "layers of attributes"; each concern isolated (a `crawl_holes` layer,
    a `materials` layer).
  - − order-dependent; a cell's final state is spread across layers.
- **2C. Selector + component (ECS-lite).** Base type array + a list of rules
  `{ "select": {...}, "apply": {...} }`. One rule paints many cells.
  `{ "select":{"region":[2,2,4,4]}, "apply":{"crawl_hole":{"size":"small"}} }`
  - + most composable + terse; one rule → many cells; rules stack cleanly.
  - − indirection (must resolve selectors to see a cell's result).
- *Lean: **2C** — directly expresses "add an attribute that turns object X into Y,"
  scales, composes. **2B** is the runner-up if you want a more visual/explicit feel.*

Selector kinds (if 2C): `cell:[x,y]`, `region:[x,y,w,h]`, `type:"floor"`,
`all`, maybe `predicate` later. Apply = one attribute + params.

## DECISION 3 — File format

- **3A. JSON.** Godot parses natively, zero deps. Slightly noisy to hand-write. *(lean)*
- **3B. YAML.** Nicer to author; needs a Godot addon/parser (dependency + risk).
- **3C. Godot `Resource` (.tres).** Editor-native, inspector-editable; NOT plain-text
  hand-editable, harder to diff/gen.
- *Lean: **3A JSON** now (native, diffable, model-writable). Could add a YAML front-end
  later if hand-authoring gets painful.*

## DECISION 4 — Authoring vs annotating (where it plugs in)

- **4A. Authored test maps only.** Format fully describes a small fixed map; bypasses
  the random generator. Simplest; ideal for inspect fixtures + regression scenes.
- **4B. Annotate procedural mazes.** Modifiers apply ON TOP of a generated `{grids,
  links}` (drop crawl-holes / material zones into a random level by selector).
  Powerful; needs stable cell addressing across seeds.
- **4C. Both.** Authored base OR "seed + modifiers"; same modifier engine either way.
  - *Lean: build **4A first** (unblocks focus/inspect immediately), design the modifier
    engine so **4B** drops in later (same `apply` step over a different base).*

## DECISION 5 — Attribute vocabulary v1 (start tiny)

Each attribute = defined renderer behavior + a headless `test_*.gd`.

- **`material`** — override a cell's surface material (zones, debugging).
- **`omit`** — skip a builder for a cell (isolate geometry in inspect).
- **`entrance`** / **`ramp`** — promote a cell (fold today's side-channels onto cells).
- **`crawl_hole`** — carve a bottom gap + smaller collision; **size-gated traversal**
  (see Decision 6).
- *Lean: v1 = `material` + `omit` + `entrance`/`ramp` (pure geometry/visual, easy tests).
  `crawl_hole` in v2 once gameplay sizing is decided.*

## DECISION 6 — Gameplay reach of `crawl_hole`

- **6A. Visual/collision only now** — hole geometry + a smaller collision opening; no
  character-size rules yet.
- **6B. Full size-gated traversal** — define character size classes; small passes,
  large blocked. A real gameplay rule (fits the asymmetric heist: minotaur can't follow
  through a crawl-hole?).
- *Lean: **6A first** (make the geometry real + tested), **6B** as its own spec — it
  touches player/enemy size + the minotaur chase.*

## DECISION 7 — Inspect / focus tooling (separate but related)

- Camera: exact `pos` + `look_target` in the map file (not fixed waypoints) → aim at
  the precise seam.
- Builder toggles + material overrides via `omit` / `material` attributes.
- **Motion-flicker catcher** (deferred per your call): capture 2 micro-jittered frames
  + write a pixel-diff so z-fighting shows without watching motion. Revisit after the
  format lands.

---

## Recommended starting shape (if we take the leans)

JSON • dense base array (1A) • selector+component modifiers (2C) • authored-first with
an annotate-ready engine (4C→4A) • v1 attrs `material`/`omit`/`entrance`/`ramp` (5) •
`crawl_hole` visuals-only later (6A). Formalize via `/spec`:
`specs/scene_map_format.spec.md` ↔ `scripts/test_scene_map.gd` (parse + apply →
assert resulting `{grids, links, cell_attrs}`), then a renderer hook + inspect scene.

## Open questions to settle next session

- Pick 2B vs 2C (modifier model) — the one real fork.
- v1 attribute set + does `crawl_hole` land now (6A) or wait.
- Coordinate addressing for 4B annotate mode (how selectors survive across seeds).
- Does this replace the ad-hoc `entrance_cells`/`links` side-channels, or coexist?
