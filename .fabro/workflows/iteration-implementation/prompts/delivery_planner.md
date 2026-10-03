Prepare the next bounded implementation handoff for `{{ inputs.plan_path }}`.

Use your file-reading tools. Do not edit application code, tests, feature files, ADRs, or the approved `plan.md`. You may edit only this iteration's `todo.md`. Do not write `.delivery/` files: Fabro validates your final JSON response against `schemas/planner-output.json`, then a deterministic stage writes those artifacts and the existing guard checks their semantics.

## Required inputs to read

- `{{ inputs.plan_path }}` in full and the sibling `todo.md`.
- The durable planner baseline at `.delivery/_guard/planner-guard-baseline.json` in the same iteration directory, plus `git rev-parse HEAD` for the binding checkpoint created immediately before this planner visit. Use that `git rev-parse HEAD` value as `source_baseline` in every output object. Do not copy the baseline JSON's `pre_planner_head`: that is the predecessor captured before the trusted checkpoint commit and the guard will reject it.
- Existing `.delivery/execution-state.json`, `.delivery/current-worker-packet.json`, `.delivery/latest-worker-result.json`, `.delivery/latest-review.json`, `.delivery/wip-before.json`, and `.delivery/wip-after.json` when present. Read `.delivery/history.jsonl` only for targeted investigation/resume, not as routine growing input.
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
- For `ready`, supply a `current_worker_packet` object for the **first unchecked** todo line. Use a fresh `packet_id`, `implementation` or `revision` attempt, one bounded `outcome`, scope and exclusions, relevant references with their necessary facts, constraints, focused validation, completion evidence, and matching candidate origins. Include latest review/worker summaries when relevant. For a scenario-led packet set `scenario_focus` to the approved feature path, exact scenario name, a specific predicted **current** failure, and `predicted_after`: the specific *next* failure you expect after one worker change, or `green`. Use `null` only for an explicit technical/recovery task with no appropriate agreed scenario. Both predictions are persisted before deterministic stages run the scenario, not invented after seeing their outputs.
- For `human_blocked` or `all_done`, return `current_worker_packet: null`. If no unchecked tasks remain, `execution_state.pending_obligations` is empty. The guard still checks that `all_done` cannot discard prior pending work.

Fabro schema-validation errors should be repaired in your final response; do not bypass the deterministic writer by writing files directly.

## Scenario-first loop

Choose one *agreed* scenario for valuable, observable feedback, not simply the easiest one. Do not invent a business rule or edit a locked feature. The command stage will remove its scenario-level `@todo`, mark exactly that scenario `@wip`, and run it. A selected feature must be named by the approved plan's `## Allowed acceptance feature changes` section. The current focused runner supports domain/application scenarios, not `@journey` browser scenarios; block for a decision instead of substituting a different boundary. Keep the intentionally red scenario **out of** the packet's successful `focused_validation` list; the trusted before/after stages own that run, while the list contains supporting checks expected to pass. A previously accepted task or unreviewed checkpoint is not reset merely to fabricate a first red run.

**Call your shot:** before each test, write a concrete diagnostic substring you expect (for example a missing step or a particular unmet assertion), based on the current code and latest observed failure. Predict the next post-worker failure or `green` **before dispatch**, too. Never run the scenario before recording the applicable prediction. The command stage records it first, runs the selected scenario, and either dispatches the worker on a matching red result or sends an unexpected failure/green result back to you. Read the recorded observation; if it differs, investigate why, update your understanding and make a new prediction before running again. Do not keep guessing, weaken the scenario, or manufacture a failure. On a green observation the stage removes `@wip`; ensure all obligations are still accounted for. A red observation after a worker is review evidence, not a green quality gate. If it differs from `predicted_after`, independent review must not accept the task; diagnose the surprise from the saved output before planning another change. Plan the next single meaningful change from that observation, keep the same active scenario until green, and only then choose another agreed scenario. Split remaining pending work to make one small reviewed step at a time while preserving checked lines, candidate provenance and coverage lineage. If the only relevant scenario is already green or none covers the current technical work, explain the gap in `planner_note` and use focused technical proof without pretending it is scenario-driven.

## Packet quality bar

Make the packet bounded and fresh. Summarize the necessary facts and cite relevant file paths/symbols rather than asking the worker to reconstruct prior history. Include focused validation and completion evidence to return. For an ordinary implementation or revision packet, `focused_validation` must not include `dev check`, `dev check --quick`, `dev ci`, or another unscoped full-suite command: the deterministic `dev_check` node owns the iteration-wide gate and has its own 30-minute timeout. Include a full-suite command only when the selected todo line is itself the explicit final-validation task. Exclude broad run logs, repeated prior summaries, old setup output, and unrelated task history.

When preparing a revision, keep the same pending obligation/task identity and include the latest review gaps. The deterministic workflow still enforces the existing bounded revision worker visit limit; do not reset it by inventing a different task for the same rejected work.

Finish by emitting only the structured JSON response. Do not emit routing JSON; the deterministic writer and guard read the validated response and artifacts.
