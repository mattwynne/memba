# Problem: implementation todo generator created tasks from prerequisites and scope guards

Date: 2026-09-04

## Context

Iteration 057 delivery run `01M1Q18PZF0AQFK28FKWBVDVG0` generated `docs/iterations/057-admin-group-email-conversations/todo.md` from the validated plan, then attempted the generated tasks one at a time.

The first implementation-plan item says to verify iteration 056 before starting and not recreate its foundation. These are a prerequisite and a scope boundary, not implementation work.

## Expected standard

`.fabro/workflows/iteration-implementation/scripts/sync_task_list.py` should generate independently implementable tasks. It already describes its filter as dropping explicit non-implementation constraints. The task validator should continue rejecting checkbox-only changes because implementation tasks need concrete evidence.

## What happened

The generator only recognised tasks beginning `No changes to ...` as non-implementation constraints. It emitted these two tasks:

```text
001 Verify iteration 056's ... foundation ... before starting this plan.
002 Do not recreate that foundation in 057.
```

For task 001, the implementation agent changed `web/config/test.exs` from two to four scheduler-based test-pool connections while checking the prerequisite checkbox. This unrelated configuration change gave the validator a non-todo artifact to accept.

For task 002, the agent correctly made no product change and checked only `todo.md`. The validator correctly rejected that todo-only checkpoint. A clean retry repeated the same approach, exhausted the retry budget, and ended the run with:

```text
goal gate unsatisfied for node publish_to_main and no retry target
```

The delivery helper restored iteration 057 from `implementing` to `validated`. No iteration 057 product implementation reached `main`; the failed evidence remains on `origin/fabro/run/01M1Q18PZF0AQFK28FKWBVDVG0`.

## Impact

The run spent about 20 minutes and model budget without beginning implementation. Worse, the first fake task encouraged and accepted an unrelated configuration change solely to manufacture a durable artifact.

## What allowed it to happen

The plan-to-todo filter matched only one wording for a negative constraint. Sentence splitting exposed semantically equivalent `Verify ... before starting ...` and `Do not ...` clauses as ordinary implementation tasks. The implementation prompt and validator then had contradictory contracts for those generated tasks: check off the first task, but do not accept todo-only work.

## Resolution

Date: 2026-09-04

Root cause: `.fabro/workflows/iteration-implementation/scripts/sync_task_list.py` classified tasks by a single literal prefix rather than distinguishing prerequisite checks and negative scope constraints from implementable work.

Fix applied:

- `.fabro/workflows/iteration-implementation/scripts/sync_task_list.py`: omit explicit `Do not ...` scope guards and `Verify ... before starting/implementing ...` prerequisites, alongside the existing `No changes to ...` filter.
- `.fabro/workflows/iteration-implementation/scripts/test_sync_task_list.sh`: reproduce the iteration 057 wording and prove only the real implementation task is generated.

The omitted clauses remain binding in `plan.md` and are checked by predecessor/WIP gates, final `dev check`, and plan conformance. The task validator remains strict; it is not weakened to accept checkbox-only implementation checkpoints.

Validation:

- The new regression failed before the generator change because all three prerequisite/constraint lines appeared in `todo.md`.
- `bash .fabro/workflows/iteration-implementation/scripts/test_sync_task_list.sh` — passed after the fix.
- Generating a fresh todo from the iteration 057 plan now starts with the email-slug implementation and contains no standalone `Verify ...`, `Do not recreate ...`, or `Do not add ...` tasks.
- `bash .fabro/workflows/iteration-implementation/scripts/test_workflow_routing.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_final_artifact_gate.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` — passed.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml --no-upgrade-check` — passed with the existing expected warning about the positive publish goal gate having no generic retry target.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev check` — passed: 1,089 tests, 0 failures; 118 acceptance scenarios, 833 steps. Unsetting the inherited flag was necessary because this Pi session was started inside another checkout's devenv; without it, worktree commands reused that checkout's Mix/build paths and produced invalid stale-source failures. This is the already-observed stale-environment class documented in `docs/kaizen/2026-06-23-fabro-focused-tests-stale-pghost.md`, not a failure of this change.

Remaining follow-up:

- Relaunch iteration 057 from its restored `validated` state and verify the first task performs real product work.
