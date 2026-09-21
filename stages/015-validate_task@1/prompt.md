Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M32CS1V82BB8NKYPWHVM7ZV5


Independently review the current candidate task for `docs/iterations/064-leave-and-remove-group-members/plan.md`. Do not edit files.

Decide from live repository state, not from summarized context alone. Read the approved plan, sibling `todo.md`, `.delivery/execution-state.json`, `.delivery/current-worker-packet.json`, `.delivery/latest-worker-result.json`, recent Fabro checkpoint commits and the relevant changed files. The candidate is the packet's `todo_line`, which must match the first unchecked todo line and must remain unchecked until accepted. If task identity, packet provenance, or candidate state is ambiguous, return `blocked` rather than approving a different task.

Fabro checkpoints candidate work after every node. A clean working tree means work may already be saved, not that it is accepted or absent. Review the full candidate for the packet, including earlier attempts and the latest revision; do not restrict review to the last checkpoint's diff. On revision, check the previous review's gaps as well as regressions introduced by the correction.

## Acceptance criteria

Accept only if all are true:

- The current worker packet is present, current, and tied to the first unchecked todo line.
- `.delivery/latest-worker-result.json` is present, matches the packet identity and says `ready_for_review`; a `replan` or `human_blocked` result is not acceptance evidence.
- The first pending task has concrete code/config/test/documentation evidence appropriate to its packet scope; a todo-only/artifact-only change is not implementation.
- The work satisfies the approved plan, packet constraints and relevant accepted ADRs.
- Any planner todo splits/additions/reordering preserve required scope. No required work was deleted, weakened, checked off prematurely or silently deferred.
- Relevant automated tests were added/updated and focused validation passed. A reported blocker is evidence for revision or escalation, not acceptance.
- Do not rerun the worker's successful tests by default. Inspect the exact commands, exit statuses, and evidence in `.delivery/latest-worker-result.json` against the current candidate. Rerun a specific focused test only when that evidence is missing, stale, contradictory, or inadequate, and state the reason in the verdict.
- Do not run `dev check`, `dev check --quick`, `dev ci`, or any other unscoped full-suite command in ordinary validation.
- Ordinary browser-facing tasks have focused browser/component/JS/CSS evidence appropriate to the change; do not require a duplicate full `dev check` solely because the task changes UI, routing, or acceptance support. The deterministic final gate still must pass before publication. If this task explicitly requires a full final-validation run, require its successful exit evidence before accepting the task; passing scenario counts without a final exit status do not prove the gate passed.
- Acceptance feature files (`*.feature`, including under `acceptance-tests/`) were not edited unless the plan's `## Allowed acceptance feature changes` section names the exact file and allowed kind of change. Any permitted edit stays within that permission and preserves the promised coverage.
- The task is a small, independently useful slice with a checkpoint evidence trail.

## Verdict

Return one JSON object matching the supplied schema, with exactly these fields:

- `decision`: `accept`, `revise`, or `blocked`.
- `task`: the exact selected unchecked todo line from the packet, including its `- [ ]` prefix and task text.
- `reason`: concise evidence from files, tests, plan/ADR constraints and worker-result provenance. For `revise`, include the specific remaining gaps and actionable corrections. For `blocked`, state the actual blocker or question.

Choose `revise` when the candidate has gaps but the task remains clear and safe to correct. The delivery planner will prepare the repair packet before another worker attempt. Choose `blocked` for ambiguity, unsafe work, a required decision/tooling fix, stale/mismatched artifacts, or repeated non-transient lack of progress. The workflow separately enforces the bounded revision worker limit; do not invent a per-task retry allowance.

Do not emit Markdown around the JSON, routing fields, node IDs or an `outcome`. The workflow applies the verdict and checks off only an accepted task. Provider errors, timeouts and invalid output are execution failures handled by Fabro, not task verdicts.

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","additionalProperties":false,"required":["decision","task","reason"],"properties":{"decision":{"type":"string","enum":["accept","revise","blocked"]},"task":{"type":"string","pattern":"^[\\t ]*- \\[ \\] \\S[^\\r\\n]*$"},"reason":{"type":"string","pattern":"\\S"}}}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.