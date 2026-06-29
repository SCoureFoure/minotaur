#!/usr/bin/env node
// warboss-default — UserPromptSubmit hook (minotaur project).
// Injects a standing reminder that the DEFAULT development path is
// warboss:delegate: slice the work, then dispatch `doer` subagents.
// Does not force a skill — the model judges per-turn whether the prompt
// is real dev work (delegate) or trivial/read-only (handle inline).

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    JSON.parse(input); // validate; we don't branch on content
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext:
          "DEV DEFAULT = warboss:delegate. If this turn changes code/specs/assets " +
          "with more than ~one trivial edit: SLICE the work, then run the " +
          "/warboss-horde:delegate skill to route each slice to the cheapest `doer` " +
          "subagent that satisfies it, judging by the verify/test command. " +
          "Author entropy out of each slice before dispatch. " +
          "Inline (no delegate) ONLY for: one-line edits, read-only Q&A, or pure investigation. " +
          "Spec-shaped work goes through /spec (its BUILD step already dispatches Warboss). " +
          "If unsure whether to delegate, prefer delegate."
      }
    }));
  } catch (e) {
    // Silent fail — never block the prompt.
  }
});
