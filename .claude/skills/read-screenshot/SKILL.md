---
name: read-screenshot
description: >
  Read a Minotaur in-game screenshot together with its paired data files so the image is
  interpreted grounded in ground truth (camera pose, depth, what's in view, world state).
  Screenshots are captured in-game with F12 (see scripts/screenshot.gd) and land in
  res://screenshots/ as a PNG + a same-named .json sidecar, with one line appended to
  res://screenshots/run.log. Trigger when the user says "/read-screenshot", "look at the
  screenshot", "read the latest shot", "what does the screenshot show", or refers to a
  saved capture.
---

You are routing a request to inspect a screenshot of the **Minotaur** Godot game. This
skill resolves *which* shot is meant; the actual pixel + sidecar interpretation is
delegated to the `screenshot-judge` subagent.

## Where shots live

- Folder: `screenshots/` (i.e. `res://screenshots/`), project root.
- Per shot: `shot_<ts>_pos<x>_<y>_<z>_yaw<deg>_<depth>_look-<target>.png` plus a `.json`
  sidecar of the **same base name**.
- `screenshots/run.log` — one line per shot (ts, cell, level, look, in_view, file).

## Resolve which shot

Default = **most recent**. Map the user's words to a file:

1. No target given, or "latest"/"last": newest `.png` by mtime.
   `ls -t screenshots/*.png | head -1`
2. A substring (e.g. "the L2 one", "look-sky", a timestamp): match the filename.
   `ls screenshots/*.png | grep -i <substring>`
3. "all recent" / a count: take the newest N.

If nothing matches, list the newest few names and ask which.

## Route to the judge (never read the PNG here)

Never `Read` a screenshot PNG or its `.json` sidecar into the main agent's own context —
pixel and sidecar interpretation belongs to the `screenshot-judge` subagent (defined in
`.claude/agents/screenshot-judge.md`). Rationale: images read into the main context are
replayed at orchestrator prices on every later turn.

## Dispatch

1. Resolve the shot filename(s) using **Resolve which shot** above.
2. Build the judging input: the explicit PNG path(s) plus EITHER a numbered checklist of
   concrete expected facts derived from what the user asked — phrase each as
   `expected -> observable`, e.g. "Rogue_Hooded model visible, not the capsule" — OR the
   user's open question verbatim if it can't be reduced to a checklist.
3. Dispatch via the Agent tool: `subagent_type: screenshot-judge`; pick the model per
   call — `haiku` when the input is a checklist, `sonnet` when it's an open
   visual-judgment question (e.g. "does the lighting look right").
4. The subagent returns a first line `VERDICT: pass|fail|unclear` plus grounded findings
   naming specific nodes.

## Relay

Lead with the verdict, answering what the user asked. Quote the judge's grounded
findings. Do NOT re-read the image to double-check — if the verdict is `unclear`, either
sharpen the checklist and re-dispatch once, or escalate to the user. If the finding is a
durable rule/bug, offer to capture it (memory note or `/spec`).

Sidecar schema, node naming, and coordinate math live in `.claude/agents/screenshot-judge.md`.
