# Problem: Validate-only wrapper cannot start its validation child unattended

Date: 2026-05-30

## Context

We tried to validate `docs/iterations/007-deliveries-overview/plan.md` using the documented wrapper command:

```bash
bin/dev iteration-validate-plan docs/iterations/007-deliveries-overview/plan.md
```

This invokes `.fabro/workflows/iteration-deliver/workflow.toml` with `mode=validate_only`.

Parent run:

- Run ID: `01KSXTEYJN86JZ6TQR8SJZNV1M`
- URL: `https://fabro.home.wynne.family/runs/01KSXTEYJN86JZ6TQR8SJZNV1M`

The parent created a plan-validation child:

- Child run ID: `01KSXTH7E1EP68177R7FRJ5VJG`
- URL: `https://fabro.home.wynne.family/runs/01KSXTH7E1EP68177R7FRJ5VJG`

## What happened

The child run was created with `auto_approve: true` and had `execution.approval = auto`, but it still entered `pending` with `approval_required`.

The parent prompt says that if a child enters `pending` with `approval_required`, the parent should approve it with `fabro_run_interact`. The parent attempted this, but Fabro rejected worker approval with:

> Run approval must be performed by a user

The parent then cancelled the pending child and reported `validation:failed`. No implementation WIP slot was checked or reserved.

We then ran the child workflow directly from the user-controlled CLI:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml \
  -I plan_path=docs/iterations/007-deliveries-overview/plan.md \
  --auto-approve
```

Direct child run:

- Run ID: `01KSXTMQ6KF46NYW9V0E06GNXC`
- URL: `https://fabro.home.wynne.family/runs/01KSXTMQ6KF46NYW9V0E06GNXC`
- Outcome: succeeded
- Published commit: `c68ae9f Mark iteration plan validated`

## Observations

- The validate-only wrapper path failed before validation could start, even though the direct plan-validation workflow succeeded.
- The child run's inspected spec showed `execution.approval = auto`, yet the event stream recorded `run.pending` with `reason = approval_required`.
- The parent workflow prompt asks the agent to approve pending children, but Fabro currently rejects worker approval for this action.
- The documented `bin/dev iteration-validate-plan` command therefore has a brittle extra orchestration layer for a task that can run directly.
- The workaround was safe because validate-only does not reserve implementation WIP or start implementation/review.

## Why this matters

Validation-ahead should be cheap and reliable. If the documented validate-only wrapper can fail due to child-run approval mechanics, future plan validation may require manual archaeology, duplicate runs, and ad hoc operator workarounds before implementation can begin.

The same child-run approval path may also affect full `iteration-start`, where failures would be more costly because the parent also reserves WIP and coordinates implementation/review.

## Open questions

- Why did a child with `execution.approval = auto` still enter `approval_required` when started by a worker parent?
- Should `bin/dev iteration-validate-plan` bypass `iteration-deliver` and call `.fabro/workflows/plan-validation/workflow.toml --auto-approve` directly?
- Does `iteration-start` need a different user-controlled approval strategy for implementation and review children?
