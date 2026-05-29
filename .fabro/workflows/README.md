# Iteration workflows

Fabro iteration work is split into two workflows:

1. `iteration-implementation` implements the plan at `plan_path`. It drains the iteration todo list, validates each task against Fabro checkpoint evidence, runs `dev ci`, and exits after the final artifact gate and summary pass. It does not run plan-conformance, ADR-coherence, or multi-model review gates.
2. `iteration-review` reviews an already-completed implementation for the same `plan_path`. It requires a clean working tree, reruns `dev ci`, then runs plan conformance, ADR coherence, independent reviewer synthesis, and bounded repair loops.

Typical commands:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
fabro run .fabro/workflows/iteration-review/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
# Optional, when reviewing a non-main base:
fabro run .fabro/workflows/iteration-review/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md -I base_ref=<base-ref>
```

## Managed clone contract

The iteration workflows rely on Fabro's managed clone and automatic checkpoints. Do not add explicit per-task commit nodes, set `[run].working_dir`, or disable `[run.clone]`: Fabro needs to infer the local repository, clone the current source branch into `/repos/mattwynne/memba`, link it at `/workspace/memba`, and create a pushed `fabro/run/<run-id>` branch for checkpoints after each node.

Prepare steps should reference files through `/workspace/memba/...` or run from the inferred repository checkout. If preflight reports `Git: unknown` or `No clone source present`, repository detection has been broken; remove any explicit `working_dir` override before running implementation work.

Run `iteration-review` on demand when the implementation workflow has exited cleanly and you want review/repair without rerunning the task implementation loop. If `base_ref` is omitted, the review workflow compares the implementation against the merge base with `origin/main` or `main`.

## Resuming a failed implementation

Resume from the failed run's pushed Fabro run branch, using a new `fabro run` with the same `plan_path`:

```bash
git fetch origin fabro/run/<failed-run-id>
git switch -c resume/<failed-run-id> --track origin/fabro/run/<failed-run-id>
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
```

The new Fabro run uses the checked-out branch as its source branch, so it sees durable Fabro checkpoint commits and the iteration `todo.md` from the failed run while using the latest local workflow definition.

Before rerunning, ensure the worktree is clean. The resume gate prints the current HEAD, todo checked/unchecked counts, and `git status --short`; it fails fast if uncommitted changes remain. Commit, stash, or reset/clean leftovers from the failed attempt before resuming.

`sync_task_list` creates `todo.md` only when it is absent. Once present, `todo.md` is execution state: existing check-offs, splits, additions, and ordering are preserved across reruns.
