# Minotaur

Asymmetric hide-and-seek party game ("friendslop"). One oversized **hunter** stalks
several **hiders** through a maze. Cat and mouse.

Built in **Godot 4.7**.

## Design roadmap

Three escalating versions, same skeleton (asymmetric hunter vs hiders):

1. **Minotaur (this prototype)** — known hunter, fixed maze. De-risks movement +
   networking before any social mechanics.
2. **Reveal twist** — hunter is chosen *mid-match*; nobody knows who flips until it
   happens. Werewolf-style paranoia layered on the working base.
3. Polish — abilities, rounds, scoring.

Betrayal mechanic is built **last** — it's just "swap a hider → hunter on a
trigger" on top of a solid base.

## Status

- [x] First-person `CharacterBody3D` controller — WASD + mouselook + jump
      (`scripts/player.gd`)
- [x] Walkable test maze (`scenes/main.tscn`)
- [ ] Multiplayer host/join (ENet + RPC)
- [ ] Hunter role (bigger body, catch = overlap area)
- [ ] Win/lose + round loop
- [ ] Mid-match betrayal reveal

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
project.godot            engine config + input map
scenes/main.tscn         match root: light, maze renderer, player (main.gd)
scenes/player.tscn       CharacterBody3D + capsule + Camera
scripts/player.gd        first-person movement controller
scripts/maze_generator.gd  pure maze data: backtracker + braiding (static API)
scripts/maze_renderer.gd   grid -> 3D geometry + collision + spawn point
scripts/main.gd          builds the maze, drops the player on a floor cell
scripts/test_maze.gd     headless AC tests for the generator
assests/terrain          modular terrain meshes (Cave/Cliff/Hilly/...)
assests/character_models  player/hunter models
```
