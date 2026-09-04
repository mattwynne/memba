# Problem: implementation workflow final artifact failure could route to publish under Fabro terminal-success semantics

Date: 2026-09-04

## Context

Fabro 0.316 documents that node outcomes and workflow status are separate. A command node whose script exits non-zero has outcome `failed`, but the workflow can still reach `exit` and complete successfully when the graph handles that failed outcome. A `goal_gate=true` node must have last outcome `succeeded` or `partially_succeeded`; `failed` and `skipped` gates fail the workflow at exit.

Matt asked for the plan-validation insight to be applied to `.fabro/workflows/iteration-implementation/workflow.fabro` without changing plan-validation or iteration-review workflows.

## Audit evidence

Files inspected:

- `docs/tools/fabro/public/execution/outcomes.mdx`
- `docs/tools/fabro/public/execution/failures.mdx`
- `docs/tools/fabro/public/workflows/transitions.mdx`
- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `.fabro/workflows/iteration-implementation/workflow.toml`
- `.fabro/workflows/iteration-implementation/scripts/final_artifact_gate.sh`
- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`
- existing iteration-implementation script tests and related kaizen notes

The critical bypass was at finalization:

```dot
final_artifact_gate -> publish_to_main
```

Because this edge was unconditional, a failed `final_artifact_gate` command could still continue to `publish_to_main`. If publish then succeeded, the workflow had no positive success gate requiring that the run's implementation publication path had been reached only through a passing final artifact gate.

The workflow also used `goal_gate=true` on terminal `Fail:` nodes. Under skipped-goal-gate semantics, failure nodes are the wrong place to model positive delivery success. They are skipped on healthy paths and they do not state the real success condition.

## Change applied

- Removed `goal_gate=true` from terminal failure-message nodes in the iteration-implementation graph.
- Added `goal_gate=true` to the positive `publish_to_main` node. An implementation run can now end successfully only if publication to `main` was actually reached and last succeeded.
- Changed `final_artifact_gate` routing so only `outcome=succeeded` reaches `publish_to_main`.
- Added `final_artifact_failed` as the explicit terminal message for final artifact evidence or acceptance feature-change policy failures.
- Added `.fabro/workflows/iteration-implementation/scripts/test_workflow_routing.sh`, which simulates the audited paths and proves:
  - a valid no-unchecked-tasks path can pass through `publish_to_main` and satisfy the positive gate;
  - a failed `final_artifact_gate` does not publish and fails at exit because `publish_to_main` is skipped;
  - a failed publish path reaches exit with the positive publish gate unsatisfied;
  - an early plan-read failure reaches exit with the positive publish gate skipped and therefore unsatisfied.

## Remaining caveats

- `fabro validate` now reports the expected warning that `publish_to_main` is a goal gate without a retry target. This is deliberate: existing graph routes already handle publish conflicts by preserving a rescue branch, collecting conflict evidence, resolving conflicts, and returning through `dev_check`. A generic goal-gate retry target would risk obscuring the explicit recovery loop.
- `final_summary` remains non-gating. If it fails after a successful publish, the implementation artifact has already been delivered; the summary is not the implementation success condition.
- This note covers only the iteration-implementation workflow. Plan-validation and iteration-review were intentionally not changed in this audit.

## Validation

- `bash .fabro/workflows/iteration-implementation/scripts/test_workflow_routing.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_final_artifact_gate.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` — passed.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml --no-upgrade-check` — `Validation: OK` with the expected `publish_to_main` goal-gate retry warning.
- `dot -Tsvg .fabro/workflows/iteration-implementation/workflow.fabro >/tmp/iteration-implementation.svg` — not run locally because `dot` was not installed.
- `dev check` — passed.
