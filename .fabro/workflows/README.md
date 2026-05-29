# Iteration workflows

Fabro iteration work is split into two trunk-based workflows:

1. `iteration-implementation` implements the plan at `plan_path`. It drains the iteration todo list, validates each task against Fabro checkpoint evidence, runs `dev ci`, proves plan conformance, squashes the implementation into one `iteration NNN: ...` commit, and pushes that commit directly to `main`.
2. `iteration-review` reviews the merged implementation diff from `base_sha` to `HEAD`. It reruns `dev ci`, runs independent reviewer synthesis, applies bounded polish when safe, records judgement-worthy findings in `docs/code-health.md`, and pushes any green polish as a separate `review polish: iteration NNN` commit to `main`.

Typical commands:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
bin/dev iteration-review main docs/iterations/NNN-topic/plan.md
# Optional, when the reviewed branch is not a single squashed iteration commit:
bin/dev iteration-review main docs/iterations/NNN-topic/plan.md <base-sha>
```

Neither workflow opens a pull request. Neither `workflow.toml` should contain a `[run.pull_request]` block.

## Managed clone contract

The iteration workflows rely on Fabro's managed clone and automatic checkpoints. Do not add explicit per-task commit nodes, set `[run].working_dir`, or disable `[run.clone]`: Fabro needs to infer the local repository, clone the current source branch into `/repos/mattwynne/memba`, link it at `/workspace/memba`, and create a pushed `fabro/run/<run-id>` branch for checkpoints after each node.

Prepare steps should reference files through `/workspace/memba/...` or run from the inferred repository checkout. If preflight reports `Git: unknown` or `No clone source present`, repository detection has been broken; remove any explicit `working_dir` override before running implementation work.

## Delivery contract

Implementation publishes with a deterministic script after `dev ci` and plan conformance pass. The script rebases on `origin/main`, refuses locked `.feature` changes, squashes Fabro checkpoint commits into one `iteration NNN: <title>` commit, writes deterministic run metadata trailers, and pushes `HEAD:main`.

Review is post-merge and non-blocking. It must never push red: changes flow back through `dev ci`, and the publish script only runs after that green check. If there are no review changes, the publish step exits successfully without touching `main`. If there are bounded safe changes, they are squashed into one `review polish: iteration NNN` commit and pushed to `main`. Human-judgement findings belong in `docs/code-health.md`, not in a PR or blocking gate.

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
