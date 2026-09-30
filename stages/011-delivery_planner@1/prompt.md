Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M3RCMKB0QE3KXT99PMFV8E8B


Prepare the next bounded implementation handoff for `docs/iterations/067-live-projection-queries/plan.md`.

Use your file-reading tools. Do not edit application code, tests, feature files, ADRs, or the approved `plan.md`. You may edit only this iteration's `todo.md`. Do not write `.delivery/` files: Fabro validates your final JSON response against `schemas/planner-output.json`, then a deterministic stage writes those artifacts and the existing guard checks their semantics.

## Required inputs to read

- `docs/iterations/067-live-projection-queries/plan.md` in full and the sibling `todo.md`.
- The durable planner baseline at `.delivery/_guard/planner-guard-baseline.json` in the same iteration directory, plus `git rev-parse HEAD` for the binding checkpoint created immediately before this planner visit. Use that `git rev-parse HEAD` value as `source_baseline` in every output object. Do not copy the baseline JSON's `pre_planner_head`: that is the predecessor captured before the trusted checkpoint commit and the guard will reject it.
- Existing `.delivery/execution-state.json`, `.delivery/current-worker-packet.json`, `.delivery/latest-worker-result.json`, and `.delivery/latest-review.json` when present. Read `.delivery/history.jsonl` only for targeted investigation/resume, not as routine growing input.
- Relevant accepted code and tests in the repository. Inspect files directly; do not trust notes as ground truth.
- ADRs and reference docs explicitly cited by the plan or needed for the selected work.

## Planner responsibilities

Prepare exactly one current worker packet when work remains. You own task selection, semantic splitting/reordering, prerequisite insertion, and revision preparation. Workers no longer choose or split tasks.

You may split, combine, or reorder pending todo lines and add technical prerequisites only to satisfy the approved plan. Preserve every checked todo line exactly. Preserve accepted code records. Record where each replaced pending obligation went.

Do not:

- edit the approved `plan.md` or any source, test, feature scenario, acceptance criterion, ADR, or project doc;
- delete, weaken, or silently defer plan obligations;
- mark tasks accepted or check them off;
- promote unaccepted candidate work to accepted evidence;
- create another readiness review loop.

If the plan/acceptance contract needs a business decision, return a human-blocked result explaining the ambiguity, leave the todo unchecked, and do not prepare a worker packet.

## Structured final response

Return **only** one JSON object with `execution_state`, `planner_result`, and `current_worker_packet`, matching `schemas/planner-output.json`. Do not put a Markdown fence or prose around the JSON. These become the three durable `.delivery/` artifacts after the deterministic writer checks your `todo.md` edit and trusted baseline. The schema defines the packet's exact reference shape; the guard also requires a non-empty path and facts for every reference.

- Use `schema_version: 1` and the same `plan_path`, `todo_path`, and `source_baseline` in all non-null objects. `source_baseline` is `git rev-parse HEAD` at planner start (the binding checkpoint), **not** `pre_planner_head`.
- In `execution_state`, preserve `accepted_tasks` exactly as the checked `todo.md` lines; map every remaining line to a `pending_obligations` object with task identity, origin, status, coverage, replaced-line lineage and candidate origins. Preserve all unaccepted candidate origins. `coverage_map` must account for every accepted line and pending id, with the exact `scope` key for each mapping (no aliases). Explain splitting/reordering or review handling in `planner_note`.
- In `planner_result`, set `decision` to `ready`, `all_done`, or `human_blocked`; a blocked result needs an `actionable_reason`.
- For `ready`, supply a `current_worker_packet` object for the **first unchecked** todo line. Use a fresh `packet_id`, `implementation` or `revision` attempt, one bounded `outcome`, scope and exclusions, relevant references with their necessary facts, constraints, focused validation, completion evidence, and matching candidate origins. Include latest review/worker summaries when relevant.
- For `human_blocked` or `all_done`, return `current_worker_packet: null`. If no unchecked tasks remain, `execution_state.pending_obligations` is empty. The guard still checks that `all_done` cannot discard prior pending work.

Fabro schema-validation errors should be repaired in your final response; do not bypass the deterministic writer by writing files directly.

## Packet quality bar

Make the packet bounded and fresh. Summarize the necessary facts and cite relevant file paths/symbols rather than asking the worker to reconstruct prior history. Include focused validation and completion evidence to return. For an ordinary implementation or revision packet, `focused_validation` must not include `dev check`, `dev check --quick`, `dev ci`, or another unscoped full-suite command: the deterministic `dev_check` node owns the iteration-wide gate and has its own 30-minute timeout. Include a full-suite command only when the selected todo line is itself the explicit final-validation task. Exclude broad run logs, repeated prior summaries, old setup output, and unrelated task history.

When preparing a revision, keep the same pending obligation/task identity and include the latest review gaps. The deterministic workflow still enforces the existing bounded revision worker visit limit; do not reset it by inventing a different task for the same rejected work.

Finish by emitting only the structured JSON response. Do not emit routing JSON; the deterministic writer and guard read the validated response and artifacts.

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","additionalProperties":false,"required":["execution_state","planner_result","current_worker_packet"],"properties":{"execution_state":{"type":"object","required":["schema_version","plan_path","todo_path","source_baseline","accepted_tasks","pending_obligations","candidate_origins","coverage_map","planner_note"],"properties":{"schema_version":{"const":1},"plan_path":{"type":"string","minLength":1},"todo_path":{"type":"string","minLength":1},"source_baseline":{"type":"string","minLength":1},"accepted_tasks":{"type":"array","items":{"type":"string"}},"pending_obligations":{"type":"array","items":{"type":"object"}},"candidate_origins":{"type":"array","items":{"type":"object"}},"coverage_map":{"type":"array","items":{"type":"object"}},"planner_note":{"type":"string","minLength":1}}},"planner_result":{"type":"object","required":["schema_version","plan_path","todo_path","source_baseline","decision"],"properties":{"schema_version":{"const":1},"plan_path":{"type":"string","minLength":1},"todo_path":{"type":"string","minLength":1},"source_baseline":{"type":"string","minLength":1},"decision":{"type":"string","enum":["ready","all_done","human_blocked"]},"actionable_reason":{"type":"string","minLength":1}}},"current_worker_packet":{"type":["object","null"],"required":["schema_version","packet_id","task_id","todo_line","attempt","plan_path","todo_path","source_baseline","outcome","scope","scope_exclusions","references","constraints","focused_validation","completion_evidence_required","candidate_origins"],"properties":{"schema_version":{"const":1},"packet_id":{"type":"string","minLength":1},"task_id":{"type":"string","minLength":1},"todo_line":{"type":"string","minLength":1},"attempt":{"type":"string","enum":["implementation","revision"]},"plan_path":{"type":"string","minLength":1},"todo_path":{"type":"string","minLength":1},"source_baseline":{"type":"string","minLength":1},"outcome":{"type":"string","minLength":1},"scope":{"type":"array","minItems":1,"items":{"type":"string"}},"scope_exclusions":{"type":"array","items":{"type":"string"}},"references":{"type":"array","minItems":1,"items":{"type":"object","required":["path","facts"],"properties":{"path":{"type":"string","minLength":1},"facts":{"type":"string","minLength":1}}}},"constraints":{"type":"array","items":{"type":"string"}},"focused_validation":{"type":"array","minItems":1,"items":{"type":"string"}},"completion_evidence_required":{"type":"array","minItems":1,"items":{"type":"string"}},"candidate_origins":{"type":"array","items":{"type":"object"}}}}}}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.