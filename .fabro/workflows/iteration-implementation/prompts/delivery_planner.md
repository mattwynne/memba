Prepare the next bounded implementation handoff for `{{ inputs.plan_path }}`.

Use your file-reading tools. Do not edit application code, tests, feature files, ADRs, or the approved `plan.md`. You may edit only this iteration's `todo.md` and files under the iteration's `.delivery/` directory.

## Required inputs to read

- `{{ inputs.plan_path }}` in full.
- The sibling `todo.md`.
- The durable planner baseline at `.delivery/planner-guard-baseline.json` in the same iteration directory.
- Existing `.delivery/execution-state.json`, `.delivery/current-worker-packet.json`, `.delivery/latest-worker-result.json`, `.delivery/latest-review.json`, and `.delivery/history.jsonl` when present.
- Relevant accepted code and tests in the repository. Inspect files directly; do not trust notes as ground truth.
- ADRs and reference docs explicitly cited by the plan or needed for the selected work.

## Planner responsibilities

Prepare exactly one current worker packet. You own task selection, semantic splitting/reordering, prerequisite insertion, and revision preparation. Workers no longer choose or split tasks.

You may split, combine, or reorder pending todo lines and add technical prerequisites only to satisfy the approved plan. Preserve every checked todo line exactly. Preserve accepted code records. Record where each replaced pending obligation went.

Do not:

- edit the approved `plan.md`;
- edit application code, tests, feature scenarios, acceptance criteria, ADRs, or project docs outside `.delivery/`;
- delete, weaken, or silently defer plan obligations;
- mark tasks accepted or check them off;
- promote unaccepted candidate work to accepted evidence;
- create another readiness review loop.

If the plan/acceptance contract needs a business decision, produce an execution state explaining the human-required ambiguity, leave the todo unchecked, and do not prepare a worker packet.

## Durable artifacts to write

Use JSON with `schema_version: 1`.

1. `.delivery/execution-state.json`
   - `plan_path`, `todo_path`, `source_baseline` from `planner-guard-baseline.json`'s `baseline_head`.
   - `accepted_tasks`: all checked lines from `todo.md`.
   - `pending_obligations`: objects with `task_id`, `todo_line`, `origin`, `status`, `coverage`, and `replaces`.
   - `coverage_map`: explicit mapping from approved scope/acceptance layers to pending task IDs or accepted task lines.
   - `planner_note`: concise rationale for any split/combine/reorder and latest review/replan handling.

2. `.delivery/current-worker-packet.json` when work remains
   - `packet_id`: stable unique id for this preparation, e.g. task id plus source baseline short SHA and attempt number.
   - `task_id`, `todo_line`: exactly the first unchecked todo line after your planning changes.
   - `attempt`: `implementation` for normal/new work, `revision` when responding to a revise verdict for the same pending obligation.
   - `plan_path`, `todo_path`, `source_baseline` equal to `planner-guard-baseline.json`'s `baseline_head`.
   - `outcome`: one bounded outcome.
   - `scope`, `scope_exclusions`, `references`, `constraints`, `focused_validation`, `completion_evidence_required`.
   - `latest_review` and `latest_worker_result` summaries when relevant.

3. Append a compact line to `.delivery/history.jsonl` describing this planner event.

If no unchecked tasks remain, update `execution-state.json` with empty `pending_obligations`; no worker packet is required.

## Packet quality bar

Make the packet bounded and fresh. Summarize the necessary facts and cite relevant file paths/symbols rather than asking the worker to reconstruct prior history. Include focused validation and completion evidence to return. Exclude broad run logs, repeated prior summaries, old setup output, and unrelated task history.

When preparing a revision, keep the same pending obligation/task identity and include the latest review gaps. The deterministic workflow still enforces the existing bounded revision worker visit limit; do not reset it by inventing a different task for the same rejected work.

Finish with a concise summary of the packet you wrote. Do not emit routing JSON; the next deterministic guard reads the artifacts.
