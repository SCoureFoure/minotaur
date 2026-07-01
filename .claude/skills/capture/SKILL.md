---
name: capture
description: >
  Run the autonomous capture bot to SEE the game without a human pressing F12. It builds a
  small fixed maze, flies a camera through decided poses (spawn, top-down overhead, each
  entrance, each underground level), saves a labelled PNG + .json sidecar per pose, then this
  skill reads those shots grounded in their sidecars. Use whenever correctness is a VISUAL fact
  — maze/geometry/ramp/model/lighting/texture changes — and no fresh screenshot already exists.
  Trigger on "/capture", "run the capture bot", "show me the maze", "does it look right",
  "grab shots", "check the visuals", or after any change whose effect can only be judged by eye.
---

# Capture (autonomous sight)

The headless tests prove *logic*; this skill proves *visuals* with no human in the loop. It runs
`scenes/capture.tscn`, which drives a camera through `MazeCapture.waypoints()` and writes one
labelled shot per pose via `Screenshotter.capture_view()`.

## Run the bot

`godot` below = the Godot binary named in CLAUDE.md (`C:\Users\SCora\Desktop\Godot_v4.7-stable_win64.exe`).

```sh
godot --path . res://scenes/capture.tscn
```

**Must run NON-headless.** `--headless` uses the dummy renderer and every PNG comes out blank.
The bot builds a small deterministic maze, captures, and **self-quits** (a window flashes briefly).

## What it produces

Shots land in `screenshots/` (`res://screenshots/`), each as `shot_<ts>_..._<label>.png` plus a
same-named `.json` sidecar, with one line appended to `run.log`. Labels, in order:

- `spawn` — eye-level at the player spawn
- `overhead` — top-down of the whole island (best for maze layout / connectivity)
- `entrance_0`, `entrance_1`, ... — one per surface entrance, looking down into it
- `level_0`, `level_1`, ... — eye-level at each underground layer's center

## Read the shots

Never interpret a PNG alone — read each with its `.json` sidecar exactly as the
`read-screenshot` skill does (`.claude/skills/read-screenshot/SKILL.md`): the sidecar carries
`camera_position`, `camera_yaw_deg`/`pitch`, `depth`, `look_target`, 5-ray `in_view`, and full
`world_state`, so pixels are reconciled against ground truth. Default: read the newest set (match
the shared timestamp), leading with `overhead` for layout questions and the relevant `level_*`
for depth questions. Report what changed, grounding each claim in a named node (e.g.
`Wall_L1_8_6`) from `in_view`/`look_target`.

## Notes

- Deterministic: the bot uses a fixed seed (`bot_seed` in `scripts/capture_bot.gd`) and a small
  6x6x3 maze, so runs are repeatable and fast. Change `bot_seed` to see a different layout.
- The pose list is pure and tested — `scripts/maze_capture.gd` (`MazeCapture.waypoints`) with
  `scripts/test_capture_waypoints.gd`.
