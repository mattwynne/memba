# Plan: stop the blind validator from hallucinating a persistence failure and resetting good work

Date: 2026-05-28

## Why (what we learned from run 01KSR32M07JDCC70YKK86XJF2V)

We have now run `iteration-implementation` twice against a long task list and it
got stuck at **task 4** both times. This plan exists because we finally pulled
the durable event log for run `01KSR32M07JDCC70YKK86XJF2V`
(`fabro events 01KSR32M07JDCC70YKK86XJF2V --json`) and found the real cause. It
is not a wiring bug, not a commit-guardrail bug, and not a sandbox/filesystem
bug. It is the exact failure mode predicted in
`docs/kaizen/2026-05-28-task-contract-validation-workflow.md`, which was never
implemented.

### What the run actually did

The checkpoint `completed_nodes` trace is unambiguous:

```
task 1: implement_next_task -> validate_task(VALID)      -> commit_task   ✅
task 2: implement_next_task -> validate_task(VALID)      -> commit_task   ✅
task 3: implement_next_task -> validate_task(VALID)      -> commit_task   ✅
          (HEAD = f34c467 "Add mix aliases / test helpers so EventStore + projection")
task 4: implement_next_task -> validate_task(RETRY)      -> reset_task_attempt
        implement_next_task -> validate_task(HUMAN_INPUT)-> task_not_ready -> run.failed
```

`run.failed` reason: `goal gate unsatisfied for node task_not_ready and no
retry target`, category `budget_exhausted`.

So the task-draining loop, the per-task commits, the resume gate, the commit
guardrails, and the reset/retry machinery all worked. Tasks 1–3 produced clean
durable commits. The run died because `validate_task` rejected a **correct**
task-4 implementation twice.

### The root cause: a tool-less validator misreads the normal flow

`validate_task` is still a prompt node (`workflow.fabro` `validate_task`:
`shape="tab" kind="prompt"`). Per our own Fabro discovery notes, prompt nodes
cannot invoke tools, so it cannot run `git status`, `git diff`, or read changed
files. It decides from summarized pipeline context only.

The per-task contract is: `implement_next_task` writes files and checks off the
todo line **in the working tree but does not commit**; `validate_task` is meant
to judge the **uncommitted working tree**; then the deterministic `commit_task`
node commits. The validator does not understand this ordering. On task 4 it
reasoned (verbatim from the run):

- RETRY verdict: *"the `sync_task_list` output that ran after the `commit_task`
  stage still shows task 004 as unchecked… commit `f34c467`… is task 003's
  commit, not task 004's… the commit stage is replaying a cached/stale commit."*
- HUMAN_INPUT verdict: *"every single `commit_task` stage produces the identical
  commit hash `f34c467`… agent file writes not persisting to host filesystem…
  The issue is in the Fabro agent-to-filesystem bridge, not in the
  implementation logic."*

Both conclusions are false. HEAD being task 3's commit (`f34c467`) and task 4's
work being uncommitted in the working tree is the **designed, correct state** at
validation time. The implementor actually completed task 4 correctly on every
attempt — it created `web/lib/memba/membership/app.ex`,
`web/lib/memba/membership/router.ex`, the supervised app wiring in
`web/lib/memba/application.ex`, `web/test/memba/membership/app_test.exs`, checked
off todo line 004, and reported `dev check` green (14 tests, 0 failures).

The blind validator mistook normal "previous commit at HEAD + new work
uncommitted" for "writes aren't persisting / stale commit replay."

### Why this is self-amplifying

A false RETRY routes to `reset_task_attempt`, which runs
`git reset --hard HEAD && git clean -fd …`. That **destroys the correct,
untracked task-4 work**. The redo re-creates the same correct work, the
validator sees the same pattern (plus the reset evidence) and escalates to
HUMAN_INPUT, which exits via `task_not_ready`. So: a blind validator that
emits one wrong RETRY is guaranteed to burn the retry budget straight to a
human-input failure, and the destructive reset means the run cannot accidentally
recover. Task 4 is simply the first task where the validator's confusion
crystallised; nothing about task 4 is special.

### What is and is not already in the workflow

Confirmed present and working (do not redo): task-draining loop, simplified
single-owner task loop, commit guardrails, `reset_task_attempt` retry,
`resume_gate`, todo preservation, and the extracted `iteration-review` workflow.

Confirmed **missing** (the gap that caused this): everything from
`2026-05-28-task-contract-validation-workflow.md`. The current
`workflow.fabro` has no `scope_next_task`, no `pre_validate_snapshot`, and no
`post_commit_verify`, and `validate_task` is still a tool-less prompt node.

## Goal

Make per-task validation decide from live repository evidence so it can never
again hallucinate a persistence/replay failure from summarized context, and make
a single wrong validator verdict non-destructive. After this change, a correct
task-4 implementation must validate, commit, and the loop must continue.

## Principles

- A validator must judge live state, not a summary of prior nodes.
- The expected validation-time state (previous task's commit at HEAD, current
  task's work uncommitted in the working tree) must be stated explicitly so it
  is never read as a fault.
- A single wrong RETRY must not destroy correct work.
- Prefer making the validator unable to be wrong (give it tools/evidence) over
  asking it to "try harder."

## Proposed work

Land the relevant parts of the task-contract-validation kaizen, prioritised by
what actually unblocks the run. Items 1–4 are required; 5 is optional polish.

### 1. Add `pre_validate_snapshot` (deterministic live evidence)

Add a script node between `implement_next_task` and `validate_task` that writes
`.fabro/tmp/pre-validate-snapshot.md` containing:

- `git rev-parse --short HEAD` and `git log -1 --format='%h %s'`
- `git status --short`
- `git diff --stat` (working tree)
- working-tree diff of the iteration `todo.md`
- `git diff --name-only` plus untracked files (`git status --porcelain`)

Our Fabro Phase-0 findings confirm script nodes can share `.fabro/tmp` files
within a run, so this evidence is available to the next node.

Edge change: `implement_next_task -> pre_validate_snapshot -> validate_task`.

### 2. Make `validate_task` evidence-based

Make `validate_task` an agent node with tool access (drop `shape="tab"` /
`kind="prompt"`) so it can run `git status`, `git diff`, and read changed files
directly. If we keep it as a prompt node for cost reasons, then the
`pre_validate_snapshot.md` contents must be injected into its prompt — but the
agent-with-tools option is strongly preferred because it makes the
"files aren't persisting" hallucination impossible against a real `git status`.

### 3. Fix the validator's mental model in `prompts/validate_task.md`

Regardless of node type, state explicitly:

- `implement_next_task` does **not** commit. The deterministic `commit_task`
  node commits **after** validation.
- Therefore, at validation time it is **correct and expected** that:
  - HEAD is the **previous** task's commit;
  - the current task's new/changed files and the `todo.md` check-off are
    **uncommitted** in the working tree (often as untracked files).
- Validate the **working tree**, not `git log`. Identify the completed task from
  the working-tree `todo.md` diff, not the last commit's diff.
- A previous task's commit at HEAD is never, by itself, evidence of a stale
  replay, memoization, or filesystem-bridge failure. Do not infer infrastructure
  faults without concrete live evidence (e.g. `git status` showing the expected
  files genuinely absent).

### 4. Make a wrong RETRY non-destructive

`reset_task_attempt` currently `git clean -fd`s away untracked work. Before it
resets, snapshot the discarded work (e.g. `git stash create` or copy changed +
untracked paths into `.fabro/tmp/discarded-attempt-<n>/`) and print what was
discarded, so a mistaken RETRY is recoverable and observable. Items 1–3 should
remove almost all false RETRYs; this is defence in depth for the residual case.

### 5. (Optional) `scope_next_task` and `post_commit_verify`

If we want the full contract design from
`2026-05-28-task-contract-validation-workflow.md`:

- `scope_next_task` (agent node) writes `.fabro/tmp/current-task-contract.md`
  before implementation — the validator "calls its shot," then checks against it.
- `post_commit_verify` (script node) after `commit_task` asserts HEAD advanced,
  the new commit contains non-`todo.md` artifacts, and exactly the intended
  check-off landed.

These improve isolation but are not required to unblock task 4.

## Acceptance criteria

- `validate_task` decides from live repository evidence (tool access, or injected
  `pre_validate_snapshot.md`), not summarized prior-node context alone.
- `pre_validate_snapshot` writes live HEAD, status, working-tree diff, and the
  `todo.md` working-tree diff before validation.
- `prompts/validate_task.md` states that the implementor does not commit, that
  the previous task's commit at HEAD with uncommitted current-task work is the
  expected state, and that validation targets the working tree.
- A false RETRY no longer permanently destroys correct work
  (snapshot-before-reset or equivalent).
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml`
  passes.
- `PATH="$PWD/bin:$PATH" dev check` passes locally after harness edits.

## Manual rehearsal / regression

Reproduce the exact run-4 condition and prove it now passes:

1. Run `iteration-implementation` against
   `docs/iterations/001-event-sourced-foundation/plan.md` (the plan from the
   failing run).
2. Confirm tasks 1–3 commit as before.
3. Confirm task 4 (`Add Memba.Membership.App and Memba.Membership.Router`)
   validates **VALID**, commits, and the loop advances to task 5 — i.e. the
   validator no longer reports a "stale commit replay" or "filesystem bridge"
   blocker when HEAD is the previous task's commit and the work is uncommitted.
4. Optionally inject a genuinely bad task-4 attempt (e.g. checked off with no
   implementation artifact) and confirm the now-evidence-based validator still
   correctly returns RETRY/HUMAN_INPUT for the right reason.

## Risks / follow-ups

- An agent `validate_task` costs more than a prompt node. Mitigate with a cheaper
  reasoning model and the precomputed snapshot so it rarely needs many tool
  calls.
- The validator could still be over-strict in other ways; the snapshot + the
  explicit "working tree, not git log" instruction is the durable guard. Add
  `scope_next_task` (item 5) if drift persists.
- If a future change reintroduces a tool-less reviewer anywhere in the per-task
  loop, the same class of hallucination can return. Treat "any node that judges
  repository state must be able to read repository state" as a standing rule.

## Implementation notes (2026-05-28)

Items 1–4 landed in `.fabro/workflows/iteration-implementation/`:

- Added `pre_validate_snapshot` script node that writes
  `.fabro/tmp/pre-validate-snapshot.md` with live HEAD, `git status --short`,
  `git diff --stat`, the working-tree `todo.md` diff, `git diff --name-only`,
  and untracked files, plus the explicit validation-time contract text.
- `validate_task` is now an agent node with tool access (`shape="tab"` removed).
- `prompts/validate_task.md` instructs the validator to decide from live state,
  validate the working tree (not `git log`), treat a previous task's commit at
  HEAD with uncommitted current work as expected, and never infer
  infrastructure faults without live evidence.
- `reset_task_attempt` now snapshots the discarded attempt (status, working-tree
  and staged diffs, and copies of modified/untracked files) under
  `.fabro/tmp/discarded-attempts/` and excludes `.fabro/tmp/` from `git clean`,
  so a wrong RETRY is recoverable.
- Edges rewired to `implement_next_task -> pre_validate_snapshot -> validate_task`.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` passes
  (only the pre-existing goal-gate retry warnings remain).

Item 5 (`scope_next_task` / `post_commit_verify`) was deferred as optional; the
items above are what unblock the task-4 stall. The remaining proof is the manual
rehearsal: re-run against `001-event-sourced-foundation/plan.md` and confirm
task 4 now validates and the loop advances.
