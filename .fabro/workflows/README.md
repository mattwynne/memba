# Iteration workflows

Fabro iteration work is split into two workflows:

1. `iteration-implementation` implements the plan at `plan_path`. It drains the iteration todo list, validates and commits each task, runs `dev ci`, and exits after the final artifact gate and summary pass. It does not run plan-conformance, ADR-coherence, or multi-model review gates.
2. `iteration-review` reviews an already-completed implementation for the same `plan_path`. It requires a clean working tree, reruns `dev ci`, then runs plan conformance, ADR coherence, independent reviewer synthesis, and bounded repair loops.

Typical commands:

```bash
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
fabro run .fabro/workflows/iteration-review/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
# Optional, when reviewing a non-main base:
fabro run .fabro/workflows/iteration-review/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md -I base_ref=<base-ref>
```

Run `iteration-review` on demand when the implementation workflow has exited cleanly and you want review/repair without rerunning the task implementation loop. If `base_ref` is omitted, the review workflow compares the implementation against the merge base with `origin/main` or `main`.

## Resuming a failed implementation

Resume with a new `fabro run` using the same `plan_path`. The workflow does not require LLM thread reuse; durable state lives in task commits and the iteration `todo.md`.

Before rerunning, ensure the worktree is clean. The resume gate prints the current HEAD, todo checked/unchecked counts, and `git status --short`; it fails fast if uncommitted changes remain. Commit, stash, or reset/clean leftovers from the failed attempt before resuming.

`sync_task_list` creates `todo.md` only when it is absent. Once present, `todo.md` is execution state: existing check-offs, splits, additions, and ordering are preserved across reruns.
