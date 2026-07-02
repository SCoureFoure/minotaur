#!/usr/bin/env node
// warboss-default — UserPromptSubmit hook (minotaur project).
// Injects a standing reminder that the DEFAULT development path is
// warboss:delegate: slice the work, then dispatch `doer` subagents.
// Does not force a skill — the model judges per-turn whether the prompt
// is real dev work (delegate) or trivial/read-only (handle inline).
// Routes screenshot/capture prompts to the screenshot-judge subagent.

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const prompt = String(data.prompt || '');
    let ctx =
      "DEV DEFAULT = warboss:delegate. If this turn changes code/specs/assets " +
      "with more than ~one trivial edit: SLICE the work, then run the " +
      "/warboss-horde:delegate skill to route each slice to the cheapest `doer` " +
      "subagent that satisfies it, judging by the verify/test command. " +
      "Author entropy out of each slice before dispatch. " +
      "Inline (no delegate) ONLY for: one-line edits, read-only Q&A, or pure investigation. " +
      "Spec-shaped work goes through /spec (its BUILD step already dispatches Warboss). " +
      "If unsure whether to delegate, prefer delegate.";
    if (/screenshot|capture|\bshot\b|look right|visuals?/i.test(prompt)) {
      ctx += " IMAGE ROUTING: never Read a PNG or its sidecar in the main context - dispatch the screenshot-judge subagent (model haiku for checklist verdicts, sonnet for open visual judgment) and relay its VERDICT.";
    }
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: ctx
      }
    }));
  } catch (e) {
    // Silent fail — never block the prompt.
  }
});
