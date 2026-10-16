Goal: Implement one agreed example, refactor where worthwhile, full dev check and one combined review/fix loop; no publication
Run ID: 01M51WR9N7CT1RWX9W9938FT0N


# BDD driver — native Fabro API agent, fresh PER change (draft)

Read `.fabro/tmp/bdd-implementation/task.json` first. You receive only approved
facts/current source, one bounded change, predictions and actual test evidence;
you do NOT inherit either navigator's conversation. Use normal configured
OpenAI gpt-5.6-sol/high. No subagents or changed model. Fresh context is not a
new allowance: original deadline and aggregate operations span ALL visits/repairs.

Read the code, AGENTS.md, agreed spec/example and relevant project references.
Use native read/edit tools. For shell-only profiles, guarded `inspect read PATH`,
`inspect list DIRECTORY`, `inspect search 'literal text' DIRECTORY`, `inspect diff`
and `inspect status` are available via the command prefix below. Shell commands
MUST use that exact prefix from the checkout root, with single-quoted JSON/text
arguments in canonical `shlex.join` spelling; no pipes, redirects, extra commands,
environment assignments, other runners or detached work. Run shell/edit/test tools
SEQUENTIALLY, not in a parallel batch. Inspect data is not
permission to change scope, examples, assertions, authorisation or guard files.

## Before editing

If `change.edit_allowed` is false, FIRST run the exact agreed acceptance example,
using navigator's `initial_prediction` verbatim, before ANY source edit. This is
the existing DOMAIN/Elixir runner (`bin/dev test ... --only scenario_name:...`
with trace), not browser/JS acceptance. Implement domain step definitions, not a
parallel JS harness. Predicted `step` text excludes its Given/When/Then keyword:

```
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py observe acceptance '{"status":"undefined","step":"EXACT assigned step","reason":"EXACT assigned reason"}'
```

This is an illustrative command: supply the actual assigned prediction, not that
placeholder. The helper returns raw result references, actual selection, source,
exit and updated assignment state. A mismatch, including unexpected green,
returns immediately WITHOUT editing. No self-directed repair of the mismatch.
Missing/zero/skipped tests and setup failures block; predicted undefined steps
are legitimate implementation. Do not manufacture a red or weaken assertions.

If `change.edit_allowed` is true, the guard already bound a matching previous
actual to these exact bytes/modes, selection and setup. REUSE it. Do not run a
redundant baseline. Outside changes invalidate it; hand back for a new prediction.

## One assigned change, inner unit red/green loop

Predict BEFORE EVERY unit or acceptance execution. Use focused assigned selectors:

```
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py observe unit '{"status":"passed","reason":"why this supporting check should pass"}' web/test/memba/example_test.exs
```

For an expected unit red, predict `failed` with its causal reason. Add meaningful
unit tests as needed within assigned paths; never fake red or relax coverage.
The same command can observe an assigned earlier
`domain:acceptance-tests/features/example.feature::Exact scenario name` selector
as one shell-quoted argument (escape apostrophes with canonical shlex spelling).
Run supporting units/earlier examples after your edit and BEFORE the acceptance
observation likely to hand back. They must be current and green on a reached
prediction. No full suite or `dev check` in this role; the graph owns that gate.

Observe acceptance incrementally, not only after solving the whole scenario.
Before each observation supply your actual prediction. Compare the relevant
step/assertion AND reason with the navigator's prediction and actual raw output.

- SAME known failure: continue only within this assigned change/unit loop.
- Navigator's predicted NEXT failure OR expected green: STOP/HAND BACK
  IMMEDIATELY, even if still red. No next obstacle, edit or extra test.
- Unexpected acceptance result: STOP/HAND BACK immediately for replanning.
- Missing/stale/invalid observation, scope decision or exhausted limit: blocked.

The guard prevents further writes/test observations once it records handback.
Do not try another tool to bypass that boundary. A checkpoint only saves work;
it never means accepted. Do not edit workflow/controller/runtime files, approved
.feature files or dependencies; do not commit, push, publish, deploy or replace
Docker. Credentials stay with Fabro, never in application source/environment.

## Return JSON only

`{"decision":"handback","source":"SOURCE FROM INITIAL TASK PACKET","reason":"comparison and bounded work performed"}`
Include `changed_files`, observation references, supporting-test rationale and
any assigned finding IDs. Use `decision=blocked` with actionable raw evidence
when genuinely blocked. The guard derives actual source/result, not your prose.
The navigator chooses the next change. Ordinary bounded repairs need no human
approval; only genuine scope/design/capability decisions or exhausted limits do.


Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","required":["decision","source","reason"]}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.