# Iteration workflows

Fabro iteration delivery is launched from one user-controlled shell entry point:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md [--wait|--no-wait] [--poll-interval seconds]
```

The helper runs the real workflows directly from the CLI, so approval stays at the user-run command boundary instead of inside worker-created child runs:

1. `plan-validation` validates the plan at `plan_path` with `--auto-approve` only when the plan status is `ready`. A plan already marked `validated` reuses that result and skips validation. NOT READY stops before implementation. READY plans are marked `validated`, which is a holding state that does not occupy the implementation WIP slot.
2. `bin/dev` checks that all earlier-numbered iterations are `merged`, then waits for the implementation WIP slot by polling `origin/main:docs/iterations/README.md` by default. Use `--no-wait` to fail immediately when the slot is occupied, or `--poll-interval seconds` to change the default 60-second interval. Once the predecessor and WIP checks pass, it marks the selected iteration `implementing`, updates `docs/iterations/README.md`, commits and pushes the status metadata, and captures the resulting `origin/main` SHA as the review base.
3. `iteration-implementation` implements the plan at `plan_path`. It drains the iteration todo list, validates each task against Fabro checkpoint evidence, runs `dev ci`, proves plan conformance, squashes the implementation into one `iteration NNN: ...` commit, marks the iteration `merged`, and pushes that commit directly to `main`.
4. `iteration-review` reviews the merged implementation diff from the captured `base_sha` to `HEAD`. It reruns `dev ci`, runs independent reviewer synthesis, applies bounded safe fixes/hardening/verification when possible, records only genuinely judgement-heavy findings in `docs/code-health.md`, pushes any green polish as a separate `review polish: iteration NNN` commit to `main`, and leaves already-merged iteration lifecycle metadata unchanged.

Canonical commands:

```bash
bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md [--wait|--no-wait] [--poll-interval seconds]
bin/dev fabro review <branch> docs/iterations/NNN-topic/plan.md [base_ref_or_base_sha]
bin/dev fabro clean-branches [--force]
```

Plan validation can run ahead of implementation, even while another iteration is active. It uses the standalone validation workflow directly so no implementation WIP slot is checked or reserved:

```bash
bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md
# equivalent to:
fabro run .fabro/workflows/plan-validation/workflow.toml \
  -I plan_path=docs/iterations/NNN-topic/plan.md \
  --auto-approve
```

Starting implementation remains ordered single-piece-flow. `bin/dev fabro deliver` refuses to start iteration N until earlier-numbered iterations are `merged`. It also waits by default while another iteration is `implementing`, `ready-for-review`, `in-review`, `reviewing`, or `finalizing`; with `--no-wait` it refuses immediately instead.

Manual split-phase escape hatches remain available:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md --auto-approve
.fabro/workflows/scripts/iteration_status.py check-predecessors docs/iterations/NNN-topic/plan.md
.fabro/workflows/scripts/iteration_status.py check-clear docs/iterations/NNN-topic/plan.md
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md --auto-approve
bin/dev fabro review <branch> docs/iterations/NNN-topic/plan.md <base-sha>
```

Neither implementation nor review opens a pull request. Their `workflow.toml` files should not contain a `[run.pull_request]` block.

## Managed clone contract

The implementation and review workflows rely on Fabro's managed clone and automatic checkpoints. Do not add explicit per-task commit nodes, set `[run].working_dir`, or disable `[run.clone]`: Fabro needs to infer the local repository, clone the current source branch into `/repos/mattwynne/memba`, link it at `/workspace/memba`, and create a pushed `fabro/run/<run-id>` branch for checkpoints after each node.

Prepare steps should reference files through `/workspace/memba/...` or run from the inferred repository checkout. If preflight reports `Git: unknown` or `No clone source present`, repository detection has been broken; remove any explicit `working_dir` override before running implementation or review work.

## Planner-owned task preparation, acceptance and revision

The implementation task loop is planner-owned:

1. `sync_task_list` mechanically bootstraps `todo.md` only when it is absent, then preserves it. It is not authoritative semantic sizing.
2. `delivery_planner` reads the approved plan, current todo, accepted code, latest worker result/replan and latest review evidence, then writes durable artifacts under the iteration's `.delivery/` directory.
3. `guard_delivery_packet` deterministically enforces the planner boundary: the planner may change only `todo.md` and `.delivery/` artifacts, must preserve accepted task records, and must produce a packet tied to the first unchecked todo line. Artifact-only checkpoints do not stale the packet; code/test/plan changes or mismatched task identities fail closed.
4. The worker implements the prepared packet and writes `.delivery/latest-worker-result.json` with `ready_for_review`, `replan`, or `human_blocked`.
5. `route_worker_result` sends ready candidates to the existing independent review, sends `replan` back to the planner without review/check-off, and stops human-blocked work.

A Fabro checkpoint saves candidate work; it does not approve it. The worker leaves the selected task unchecked. The independent reviewer returns one structured verdict: `accept`, `revise`, or `blocked`, identifying the exact packet/todo line and its evidence or remaining gaps. Only `apply_task_verdict` checks off accepted work; replaying acceptance cannot check off the next task. The command also records `.delivery/latest-review.json` so the next planner pass can prepare either the next obligation or a bounded repair packet.

Revision keeps useful candidate code but now returns through the delivery planner before another worker attempt. The same pending obligation should stay identifiable; replanning must not reset acceptance or silently promote rejected candidate work. There is no automatic reset or discarded-attempt archive. `revise_task` retains the former reset node's native `max_visits=3` guard across the entire iteration. Fabro 0.316 stops before executing visit three, allowing two revision-worker passes in total—not a fresh allowance per renamed task. Exhausting it stops the run with work preserved. A new run starts a new budget; inspect repeated failures before restarting rather than using restarts to evade the bound.

Fabro 0.316 supports the custom verdict schema and passes its parsed output to the verdict command through `stdin_source`. The command performs the check-off and emits routing JSON; the reviewer cannot set the workflow outcome through its verdict. Missing, malformed, stale or mismatched planner/worker/review artifacts stop the task loop without advancing the todo. The shared `task_stopped` fallback has no outgoing edge: it fails without reaching normal exit and the unrelated publish goal-gate check. The original failure and review feedback remain in the preceding stage output, durable `.delivery/` artifacts and Fabro metadata.

Task-loop model stages use minimal Fabro preamble fidelity and load explicit `.delivery/` artifacts instead of carrying repeated historical `summary:high` context as their main input. The planner packet should include the relevant facts, source references, constraints and focused validation for one bounded task; it should not ask the worker to reconstruct broad prior run history.

To exercise this boundary, run `bash .fabro/workflows/iteration-implementation/scripts/test_task_execution_contract.sh`. With Fabro installed, also run `python3 .fabro/workflows/iteration-implementation/scripts/test_task_workflow_runtime.py`: it uses an isolated local server and temporary repositories, replacing agents and publication with scripted fixtures. It tests native schema validation, worker replan routing, restart, minimal-fidelity routing and visit limits without contacting the production server or making model calls.

## Delivery contract

Per-task implementation and independent validation use focused evidence, including targeted browser scenarios or a browser harness for browser-facing changes. A UI, routing, or acceptance-support change is not a reason to run the full suite inside an ordinary task node. The deterministic `dev_check` node still runs full `dev ci` after the task loop and again after gate repairs; publication requires that gate to pass.

An existing plan may also explicitly require a final full-validation task. That requirement remains binding: do not check it off without a successful full command exit or silently remove it to avoid duplication. Moving those tasks to workflow-owned completion needs a separate, explicit handoff contract. Fabro's documented agent-shell ceiling is 600 seconds; the implementation prompt node has a 2,400-second total budget. If a required gate cannot fit, preserve the unchecked task and report a recovery blocker rather than launching detached retries or claiming success from a passing test summary alone.

Implementation publishes with a deterministic script after `dev ci` and plan conformance pass. The script rebases on `origin/main`, refuses `.feature` changes unless the plan explicitly permits them in a `## Allowed acceptance feature changes` section, marks the plan and iteration index `merged`, squashes Fabro checkpoint commits into one `iteration NNN: <title>` commit, writes deterministic run metadata trailers, and pushes `HEAD:main`. Publish/finalization scripts use the scoped Fabro git identity helper in `.fabro/workflows/scripts/git_identity.sh`; do not persistently change repo-local `user.name` or `user.email` inside a Fabro sandbox. If the final rebase conflicts, the script preserves the attempted commit on a `fabro/rescue/...-publish-conflict` branch and the workflow may route to an agent-assisted conflict-resolution node. Any resolved conflict is treated as a new candidate artifact and goes back through `dev ci`, plan conformance, final artifact checks, and publish before it can reach `main`.

Acceptance feature files are locked by default. When an iteration genuinely needs to change shared `.feature` files, the plan must include:

```markdown
## Allowed acceptance feature changes

- `acceptance-tests/features/example.feature`: tag-only change to add `@todo-web`; covered by the Elixir/domain acceptance path in `dev check`.
```

Each bullet must name the exact `.feature` path and the allowed kind of change. If the bullet says `tag-only`, the publish guard rejects any non-tag Gherkin line changes in that file.

Review is post-merge and non-blocking. It must never push red: changes flow back through `dev ci`, and the publish script only runs after that green check. If there are no review changes, the publish step exits successfully without touching `main`. If there are bounded safe changes, including low-risk hardening or tests that prove existing intended behaviour, they are squashed into one `review polish: iteration NNN` commit and pushed to `main`. Human-judgement findings belong in `docs/code-health.md`, not in a PR or blocking gate.

After review publish/no-op succeeds, the review workflow verifies the iteration is marked `merged` in the plan, implementation record when present, and `docs/iterations/README.md`; when implementation already published the merged metadata, this is a no-op. If review fails, the implementation remains merged and the review run can be retried with the printed `bin/dev fabro review ...` command after resolving the failure.

When `bin/dev fabro review` must review `origin/main` while local `main` is checked out, it creates a temporary pushed branch under `review/tmp/` so Fabro can clone a real branch without detaching `main`. These branches are safe to delete only after their foreground review run has finished and their tip is already contained in `origin/main`. Use `bin/dev fabro clean-branches` to dry-run safe cleanup, then `bin/dev fabro clean-branches --force` to delete the listed temporary local and remote branches. The cleanup command also recognises older `review/main-YYYYMMDDHHMMSS` temporary branches.

## Resuming a failed implementation

Resume from the failed run's pushed Fabro run branch, using a new `fabro run` with the same `plan_path`:

```bash
git fetch origin fabro/run/<failed-run-id>
git switch -c resume/<failed-run-id> --track origin/fabro/run/<failed-run-id>
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md --auto-approve
```

The new Fabro run uses the checked-out branch as its source branch, so it sees durable Fabro checkpoint commits and the iteration `todo.md` from the failed run while using the latest local workflow definition.

Before rerunning, ensure the worktree is clean. The resume gate prints the current HEAD, todo checked/unchecked counts, and `git status --short`; it fails fast if uncommitted changes remain. Commit, stash, or reset/clean leftovers from the failed attempt before resuming.

`sync_task_list` creates `todo.md` only when it is absent. Once present, `todo.md` is execution state: existing check-offs, splits, additions, and ordering are preserved across reruns. New runs leave unaccepted candidates unchecked, so restart continues that work rather than skipping it.

For runs created before acceptance-owned check-off, inspect the last review first. The old implementor checked off tasks before review; reopen any rejected or unreviewed task before starting this workflow from that checkpoint. Do not assume that an old checked box proves acceptance.
