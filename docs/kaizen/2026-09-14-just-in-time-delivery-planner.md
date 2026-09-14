# Just-in-time delivery planner

Status: implemented in isolated branch `kaizen/delivery-planner`; deterministic and native runtime validation passed. Operational effectiveness is pending a later authorized real delivery run.

## Decision

Replace worker-owned task discovery and decomposition with a capable delivery planner. Prepare one bounded task just before implementation, using current code rather than a batch of stale handoffs.

Matt approved this flow:

**Delivery planner → worker → existing implementation review → delivery planner.**

A worker that discovers missing preparation or excessive scope returns early to the planner with evidence. It does not silently enlarge the assignment or keep working toward timeout.

Use Sol for the initial delivery planner. Matt explicitly rejected an additional readiness reviewer or readiness-review loop: the capable planner is responsible for the quality of its handoff. Keep the existing independent implementation review and final validation/publication gates.

## Why

The [iteration-062 investigation](2026-09-03-iteration-workflow-timeout-masks-test-failure.md) found that the worker owned semantic task decomposition, dependency discovery, implementation and focused validation. Mechanical workflow history repeated prior outputs rather than providing curated task context. Task 024 reached about 160,000 input tokens before its first edit.

The [bounded preparation exercise](experiments/062-task-024/README.md) demonstrated a concrete alternative: a roughly 7 KB task-specific packet naming the outcome, relevant code, fixture/context shapes, genuine integration gaps and validation. That exercise was reviewed but not implemented; it does not prove a time/token budget or prescribe one scenario per task.

Prediction: externally prepared, narrower work reduces broad rediscovery and encourages useful early returns instead of late timeout. Workflow tests can prove routing and artifact contracts; actual delivery runs must establish effectiveness.

## Responsibilities

### Delivery planner

Read the approved iteration plan, current execution state, relevant accepted code, latest worker notes and review result. Inspect relevant changes rather than trusting notes as ground truth. Distinguish accepted work from preserved but unaccepted candidate checkpoints.

The planner may split, combine or reorder pending implementation work and add technical prerequisites needed to satisfy the approved scope. Maintain an explicit mapping from outstanding scope to pending work, including coverage at every required acceptance layer. Preserve accepted task records. Record why a pending task was replaced and where its obligations went.

Select one next task and produce its implementation-ready handoff. Replanning changes the route, not the destination:

- Do not edit the approved `plan.md`, application code, tests, feature scenarios or acceptance criteria.
- Do not remove obligations, weaken assertions, invent permission to edit features, or mark implementation work accepted.
- If a specification appears wrong or needs a business decision, return a human-actionable stop rather than change it.
- Existing plan-authorized step-definition work and narrowly permitted runner-debt tag changes may be assigned to a worker. Permissions come from the original approved plan, never from the planner.
- Explicit full-validation tasks remain obligations. This change does not silently transfer their completion to another gate or declare them unnecessary.

Planning output is limited to execution-plan/coverage state and handoff artifacts. Use a deterministic file-change guard to enforce this boundary; this is not another model review or readiness loop. Preserve evidence on violation; do not silently reset files.

### Worker

Implement the identified handoff, perform its focused validation and return concise notes. The worker no longer selects or splits tasks, rewrites the todo list, or commissions preparation/review subagents. Keep the existing single-owner rule; do not introduce new tool-capability enforcement in this change.

The normal completion record contains:

- task identity and attempt/baseline references;
- changed paths and what changed;
- commands, exit statuses and relevant validation evidence;
- useful discoveries, reusable helpers and non-obvious constraints;
- unresolved facts and candidate work still needing validation.

Notes are evidence for the planner, not instructions that pass unchanged to the next worker. On missing preparation, excessive scope or a prerequisite outside the task, return a structured replan request with the specific blocker, partial work, completed checks and remaining validation. Preserve candidate work and leave the task unchecked. A business/acceptance-contract decision must stop for Matt rather than repeatedly replan.

### Existing implementation review

Review the actual candidate against its assigned scope, the approved plan and acceptance contract, including earlier candidate attempts. Only deterministic application of an independent acceptance verdict may check off a task.

Acceptance sends the outcome to the planner to choose the next task. A repairable revision also goes through the planner so the repair worker receives a fresh, bounded packet for the same pending obligation. Preserve the current bounded revision policy. A replan must not reset that budget or make previously rejected work accepted by renaming its task.

## Artifacts and context contract

Use small, durable, checkpointed repository artifacts. Do not put the only copy under `.fabro/tmp`: `workflow.toml` excludes that directory from checkpoints, and preflight clears it. Keep artifacts local to the relevant iteration and use explicit schemas/task identities where deterministic code consumes them.

The implementation should provide:

1. An execution-state/coverage record, retaining accepted tasks and pending obligations. Existing `todo.md` remains compatible with final artifact and plan-conformance checks.
2. One current worker packet: task identity, source/candidate baseline, outcome, scope exclusions, relevant file/symbol references with the necessary facts summarized, constraints, focused validation and completion evidence.
3. A latest completion/replan record and latest review evidence, tied to the task and attempt. Retain enough durable history for safe resume without concatenating it into every model input.

Exact filenames and schema details are implementation choices, but identities, provenance and resume behavior must be explicit and tested. Account for Fabro's automatic metadata/checkpoint commits: a harmless artifact-only checkpoint must not make a packet spuriously stale, while changed code or task identity must not silently reuse an obsolete packet.

The planner must distinguish accepted code from all unaccepted candidate changes. In particular, accepting a new prerequisite must not accidentally promote an earlier task's partial changes into accepted evidence. Preserve task-specific provenance; if safe attribution/replanning is impossible, keep the original pending obligation or stop rather than discard or implicitly accept work.

Use the documented minimal Fabro context fidelity for task-loop agents and load the current artifacts explicitly. Do not retain `summary:high` history accumulation as the worker's main input, substitute a growing chain of summaries, or ask the worker to reconstruct the handoff by reading all prior logs and ADRs. Include the relevant binding ADR/reference guidance in preparation; normal project instructions still apply.

The planner itself starts from concise durable state and targeted code inspection rather than an ever-growing conversation. No numerical context limit or compaction policy is selected here. Do not change Fabro internals, raise context/time limits, or introduce automatic hard-timeout retries.

## Concrete implementation map

The current workflow files were inspected before this proposal:

- `.fabro/workflows/iteration-implementation/workflow.fabro`: `sync_task_list` is currently a command, then `all_tasks_done` chooses `implement_next_task` or `dev_check`. Accepted verdicts return to sync; revisions go directly to `revise_task`. Add the planner and explicit worker-result routing, and route task outcomes through preparation while preserving final gates and failure fallbacks. Keep task/revision visit limits effective.
- `scripts/sync_task_list.py`: currently seeds tasks with character/sentence heuristics and otherwise preserves the todo. It is not a semantic planner. Retire its authoritative role in the active loop or reduce it to compatible bootstrap support; an oversized initial plan item must not prevent the planner from decomposing it. Do not merely activate the old prompt while leaving workers responsible for sizing.
- `prompts/implement_next_task.md`: currently orders plan/history discovery and permits worker splitting/reordering. Replace those responsibilities with the selected packet and explicit ready/replan/human-blocked completion contract. Retain focused validation, no manual check-off, automatic checkpointing and acceptance-lock rules.
- New planner prompt/schema and artifact/routing helpers: implement the responsibilities and durable state above. Use `gpt-5.6-sol`, already the workflow's default, with high reasoning effort; avoid adding a low-capability planner or a readiness-review model call.
- `prompts/validate_task.md`, `schemas/task-verdict.json` and `scripts/apply_task_verdict.py`: adapt identity/evidence/routing as needed without weakening independent acceptance, exact-task check-off, replay safety or fail-closed invalid verdict handling. Review the whole relevant candidate, not merely the newest metadata checkpoint.
- `.fabro/workflows/README.md`: document the actual planner/worker/review ownership, artifacts and resume behavior. Remove conflicting descriptions; do not claim effective prevention from contract tests alone.
- Existing `scripts/test_task_execution_contract.sh`, `test_task_workflow_runtime.py` and verdict/sync tests: extend real runtime and state-transition coverage, not just prompt substring assertions.

No changes are requested to product behavior, shared feature semantics, other running iterations, launch/publication authorization, WIP ownership, provider recovery policy, final `dev ci`, plan-conformance review, artifact guards or publication gates. Do not start or modify a live Fabro delivery run to test this change.

## Required validation

Use focused deterministic tests and the installed Fabro runtime harness first. Cover:

- Initial preparation, existing todo/resume and latest code/notes/review inputs.
- Split/combine/reorder with preserved accepted tasks and explicit remaining coverage; planner cannot change the acceptance contract or implementation files.
- Ready candidate → existing independent review → exact-task check-off only on acceptance.
- Worker replan → planner, with no review/check-off of incomplete work and no lost candidate evidence.
- Revision → freshly prepared repair, with the original bounded revision protection still effective.
- Malformed/missing/stale/mismatched artifacts and ambiguous candidates fail closed; harmless checkpoint metadata changes do not cause false staleness.
- Human-required ambiguity and actual node execution failure remain stops, not unbounded retry/replan routes.
- Repeated task-loop visits do not inject concatenated prior summaries into the next worker. Test the rendered/runtime input boundary where practical, not only the word `truncate` in the graph.
- All existing final gates remain reachable only through their preserved prerequisites; final validation tasks cannot disappear through replanning.

Then run full `dev check` for this workflow/config change on the exact committed state, or with the final diff staged as required by project guidance. Use isolated local database/server settings; do not compete with a live recovery's resources. Capture exit status and exact tree/commit. If an unrelated failure occurs, investigate it and report it accurately rather than weakening tests or claiming a pass.

Commit scoped implementation and documentation changes. Do not push, merge, start delivery or remove Fabro runs. Update the original kaizen note with changes and actual validation; leave operational effectiveness pending until a subsequent authorized delivery demonstrates task completion, useful early replan and bounded context in practice.

## Implementation status — 2026-09-14

Implemented in the isolated delivery-planner worktree/branch. The workflow now prepares each task through a delivery planner, stores durable `.delivery/` execution state, worker packet, worker result and review artifacts beside the iteration plan, validates packet provenance deterministically, routes worker replan requests back to the planner without review/check-off, and returns accepted/revision verdicts to the planner before selecting the next worker packet. Task-loop model nodes use minimal Fabro fidelity and explicit artifact loading. Existing independent review, exact-task check-off, bounded revision worker visits, final `dev ci`, plan conformance, final artifact and publication gates were preserved.

Validation performed for this branch:

- `bash .fabro/workflows/iteration-implementation/scripts/test_task_execution_contract.sh` — passed, including delivery-planner artifact contract and verdict helper tests.
- `bash .fabro/workflows/iteration-implementation/scripts/test_sync_task_list.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_workflow_routing.sh` — passed.
- All iteration-implementation shell helper tests under `.fabro/workflows/iteration-implementation/scripts/test_*.sh` — passed.
- All iteration-implementation Python tests under `.fabro/workflows/iteration-implementation/scripts/test_*.py` — passed, including the native Fabro runtime fixture with mock/scripted nodes and no model calls.
- Final full gate on the final staged diff: `env -u DEVENV_RUNTIME MEMBA_POSTGRES_PORT=15461 ACCEPTANCE_SERVER_NODE=memba_delivery_planner@localhost ./bin/dev check` — passed with 1292 tests / 0 failures and 145 acceptance scenarios / 1052 steps passing.

Operational effectiveness remains pending: no live delivery run was started or modified for this implementation.
