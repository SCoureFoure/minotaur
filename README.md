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

| Key | Action |
|-----|--------|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Esc | Release / recapture mouse |

## Layout

```
project.godot        engine config + input map
scenes/main.tscn     world: floor, lights, walls, player instance
scenes/player.tscn   CharacterBody3D + capsule + Camera
scripts/player.gd    movement controller
```
