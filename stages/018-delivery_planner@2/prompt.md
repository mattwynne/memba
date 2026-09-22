Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01M33YR130B147ZZVAN2ANYC7E


Prepare the next bounded implementation handoff for `docs/iterations/064-leave-and-remove-group-members/plan.md`.

Use your file-reading tools. Do not edit application code, tests, feature files, ADRs, or the approved `plan.md`. You may edit only this iteration's `todo.md` and files under the iteration's `.delivery/` directory.

## Required inputs to read

- `docs/iterations/064-leave-and-remove-group-members/plan.md` in full.
- The sibling `todo.md`.
- The durable planner baseline at `.delivery/_guard/planner-guard-baseline.json` in the same iteration directory, plus `git rev-parse HEAD` for the binding checkpoint created immediately before this planner visit. Use that `git rev-parse HEAD` value as `source_baseline` in every planner artifact. Do not copy the baseline JSON's `pre_planner_head`: that is the predecessor captured before the trusted checkpoint commit and the guard will reject it.
- Existing `.delivery/execution-state.json`, `.delivery/current-worker-packet.json`, `.delivery/latest-worker-result.json`, and `.delivery/latest-review.json` when present. Read `.delivery/history.jsonl` only for targeted investigation/resume, not as routine growing input.
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
   - `plan_path`, `todo_path`, `source_baseline` set to the binding checkpoint (`git rev-parse HEAD` at planner start, matching the guard's trusted before-planner checkpoint).
   - `accepted_tasks`: all checked lines from `todo.md`; do not add or remove checked lines.
   - `pending_obligations`: objects with `task_id`, `todo_line`, `origin`, `status`, `coverage`, `replaces`, and `candidate_origins`.
   - `candidate_origins`: cumulative unaccepted candidate origins from prior worker replans/revisions that remain unresolved.
   - `coverage_map`: explicit mapping from approved scope/acceptance layers to `pending_task_ids` and `accepted_task_lines`; every pending task id and accepted task line must be referenced. Each `coverage_map` item must use the exact key `scope` for its non-empty scope/acceptance-layer description. Do not use aliases such as `scope_or_acceptance_layer`, `acceptance_layer`, or `description`; the deterministic guard rejects them.
   - `planner_note`: concise rationale for any split/combine/reorder and latest review/replan handling.

   Minimal shape (include real values rather than these placeholders):

   ```json
   {
     "schema_version": 1,
     "plan_path": "docs/iterations/NNN-topic/plan.md",
     "todo_path": "docs/iterations/NNN-topic/todo.md",
     "source_baseline": "<binding checkpoint sha>",
     "accepted_tasks": [],
     "pending_obligations": [
       {
         "task_id": "001",
         "todo_line": "- [ ] 001 ...",
         "origin": "plan.md ...",
         "status": "prepared",
         "coverage": ["..."],
         "replaces": [],
         "candidate_origins": []
       }
     ],
     "candidate_origins": [],
     "coverage_map": [
       {"scope": "approved scope or acceptance layer", "pending_task_ids": ["001"], "accepted_task_lines": []}
     ],
     "planner_note": "..."
   }
   ```

2. `.delivery/planner-result.json`
   - `schema_version`, `plan_path`, `todo_path`, `source_baseline`.
   - `decision`: `ready`, `all_done`, or `human_blocked`.
   - `actionable_reason` for `human_blocked`; leave any stale worker packet irrelevant.

3. `.delivery/current-worker-packet.json` when work remains and `planner-result.json` is `ready`
   - `packet_id`: stable unique id for this preparation, e.g. task id plus source baseline short SHA and attempt number.
   - `task_id`, `todo_line`: exactly the first unchecked todo line after your planning changes.
   - `attempt`: `implementation` for normal/new work, `revision` when responding to a revise verdict for the same pending obligation.
   - `plan_path`, `todo_path`, `source_baseline` equal to the same binding checkpoint used in `planner-result.json` and `execution-state.json`.
   - `outcome`: one bounded outcome.
   - `scope`, `scope_exclusions`, `references`, `constraints`, `focused_validation`, `completion_evidence_required`.
   - `candidate_origins` for this selected obligation.
   - `latest_review` and `latest_worker_result` summaries when relevant.

If no unchecked tasks remain, update `execution-state.json` with empty `pending_obligations`; no worker packet is required.

## Packet quality bar

Make the packet bounded and fresh. Summarize the necessary facts and cite relevant file paths/symbols rather than asking the worker to reconstruct prior history. Include focused validation and completion evidence to return. For an ordinary implementation or revision packet, `focused_validation` must not include `dev check`, `dev check --quick`, `dev ci`, or another unscoped full-suite command: the deterministic `dev_check` node owns the iteration-wide gate and has its own 30-minute timeout. Include a full-suite command only when the selected todo line is itself the explicit final-validation task. Exclude broad run logs, repeated prior summaries, old setup output, and unrelated task history.

When preparing a revision, keep the same pending obligation/task identity and include the latest review gaps. The deterministic workflow still enforces the existing bounded revision worker visit limit; do not reset it by inventing a different task for the same rejected work.

Finish with a concise summary of the packet you wrote. Do not emit routing JSON; the next deterministic guard reads the artifacts.