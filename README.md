# Minotaur

Asymmetric **vertical descent treasure-heist**. Players land on the surface of Minos
(the minotaur's island), find a labyrinth entrance, and descend into the ground to
loot treasure — then must carry it back **up** to the surface to escape. The
**minotaur** hunts: lays traps, captures players (rescue mechanic TBD). Deeper =
better loot but a longer, deadlier escape.

Built in **Godot 4.7**.

## Design roadmap

1. **Descent prototype (current)** — island surface + multi-level underground maze
   (guaranteed connected), walkable ramps between levels, player-count sizing.
2. **Core loop** — loot pickup + carry-out-to-escape win, minotaur role, multiplayer.
3. **Polish** — cave-mesh skinning, grass/water/sky shaders, traps, social layer
   (coop vs competitive).

## Status

- [x] First-person `CharacterBody3D` controller — WASD + mouselook + jump
      (`scripts/player.gd`)
- [x] Procedural single maze — backtracker + braiding, guaranteed connected
      (`scripts/maze_generator.gd`, 7/7 headless ACs)
- [x] Multi-level **maze volume** — stacked layers + vertical links, provably
      connected in 3D (`scripts/maze_volume.gd`, 10/10 headless ACs)
- [x] Descent renderer — island surface (grass + water ring), entrances with ramps
      down, box collision, layer-colored levels (`scripts/maze_renderer.gd`)
- [x] Player-count sizing — lobby size drives maze dims (6/6 headless ACs)
- [ ] Loot pickup + carry-out-to-escape win condition
- [ ] Minotaur role (bigger body, catch = overlap, traps)
- [ ] Multiplayer host/join (ENet + RPC)
- [ ] Capture / rescue mechanic
- [ ] Visual pass: cave meshes, BinbunGrass, water/sky shaders

## Run

Open the project in Godot 4.7 (`Godot_v4.7-stable_win64.exe` → Import →
`project.godot`) and press **F5**. Or headless smoke test:

```sh
godot --headless --path . --import --quit          # validate project
godot --headless --path . res://scenes/main.tscn --quit-after 10   # run 10 frames
```

## Controls

Bindings live in `project.godot` under `[input]`; the `Action` column is the
input-action name to use in code (`Input.is_action_*`).

### Active

| Key | Action (input map) | Does |
|-----|--------------------|------|
| W A S D | `move_forward` / `move_back` / `move_left` / `move_right` | Walk |
| Mouse | — | Look (yaw + pitch, clamped) |
| Space | `jump` | Jump |
| Esc | `ui_cancel` | Release / recapture mouse cursor |

### Planned (not bound yet)

| Key | Action (input map) | Does |
|-----|--------------------|------|
| Shift | `sprint` | Sprint |
| Ctrl / C | `crouch` | Crouch / hide |
| E | `interact` | Use / grab |
| Mouse 1 | `lunge` | Hunter catch / attack |

> Adding a control = add the binding under `[input]` in `project.godot`, then
> read it via its action name in the relevant script. Keep this table in sync.

## Layout

```
project.godot              engine config + input map
scenes/main.tscn           match root: env, light, maze renderer, player (main.gd)
scenes/player.tscn         CharacterBody3D + capsule + Camera
scripts/player.gd          first-person movement controller
scripts/maze_generator.gd  pure maze data: backtracker + braiding (static API)
scripts/maze_volume.gd     stacks layers + vertical links -> connected 3D volume
scripts/maze_autotile.gd   wall-neighbor bitmask (for future mesh autotiling)
scripts/maze_renderer.gd   volume -> island + underground levels + ramps + spawn
scripts/main.gd            builds the maze, drops the player on the surface
scripts/test_maze.gd       headless ACs: generator
scripts/test_maze_volume.gd   headless ACs: 3D volume + connectivity
scripts/test_autotile.gd   headless ACs: wall-neighbor mask
scripts/test_sizing.gd     headless ACs: player-count -> maze dims
assests/terrain            modular terrain meshes (Cave/Cliff/Beach/BinbunGrass/...)
assests/shaders            sky + water shader packs (not yet wired)
assests/character_models   player/hunter models
```

## Renderer knobs (`MazeRenderer` in `main.tscn`)

| Export | Does |
|--------|------|
| `use_volume` | multi-level descent build (vs flat single maze) |
| `player_count` + `auto_size_from_players` | lobby size → maze dims |
| `cols` / `rows` / `layers` | manual dims (when auto off) |
| `level_height` | world-Y drop per level (ramp angle = `atan(h/cell_size)`) |
| `links_per_pair` | vertical links carved per adjacent level pair |
| `entrance_count` | surface entrances (island holes + ramps down) |
| `cave_calibration` | debug: lay cave meshes in a labeled row to read scale |

## Tests (headless)

```sh
for t in test_maze test_maze_volume test_autotile test_sizing; do
  godot --headless --path . --script res://scripts/$t.gd
done   # each prints ALL_PASS
```
