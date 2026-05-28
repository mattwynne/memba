# Idea: make iteration-implementation resumable across runs

Date: 2026-05-28

## Context

When an `iteration-implementation` run fails part-way through a long task
list, the next run effectively starts over. The plan for
`001-member-message-deliverability` has 18 implementation tasks; in practice
runs have failed around tasks 4–6, and re-running has felt like burning
tokens redoing tasks 1–3.

The pieces needed to resume are mostly already in place:

- `commit_task` produces one durable git commit per completed task, including
  a `todo.md` check-off line for that task.
- `sync_task_list` already prefers an existing `todo.md` over regenerating it
  from the plan (`if [ ! -f \"$TODO_PATH\" ]; then ... else echo \"Using existing $TODO_PATH\"; fi`).
- `reset_task_attempt` resets only failed in-progress attempts to `HEAD`, not
  back to some workflow base.

So in principle, a second run starts from the last successful task commit and
finds the matching `todo.md` already checked off through that point. What we
need to verify and harden is that nothing else in the workflow silently
discards that progress, and that `implement_next_task` reliably picks the
first genuinely unchecked task rather than redoing one that is already done.

## Goal

Make a second run of `iteration-implementation` against the same plan resume
from the last successful task commit with zero redundant implementation work,
and make this property explicit and testable rather than incidental.

## Observed / suspected gaps

These are the places to check and, where needed, fix:

1. **Workflow startup state.** Confirm there is no implicit `git reset` /
   `git clean` between runs. `reset_task_attempt` is reachable only from
   `task_gate` on a failed validation, but we should make sure no preflight or
   harness behaviour wipes the worktree at run start.
2. **`sync_task_list` regeneration semantics.** The script regenerates
   `todo.md` only when the file is missing. If a prior run left a `todo.md`
   with manual edits (splits, reorderings) and check-offs, those must be
   preserved. We should document this contract explicitly in the node's
   description and prompt.
3. **`implement_next_task` task selection.** The implementor reads `todo.md`
   and picks the first unchecked task. If a previous run partially implemented
   a task without committing (e.g. crash between `validate_task` and
   `commit_task`), the working tree may contain uncommitted changes for an
   unchecked task. The implementor must either continue that work or reset it
   deterministically — silent overwrite or duplicate implementation is the
   failure mode to avoid.
4. **Stale `.fabro/tmp/*` artifacts.** Snapshot files from the previous run
   (`plan-repair-before.patch`, etc.) may exist. They should not influence the
   new run; the snapshot nodes already overwrite them, but we should confirm.
5. **Fabro thread / memoization.** A new invocation should not reuse cached
   outputs from a failed prior run for nodes whose inputs include live
   repository state. If Fabro memoizes prompt-node outputs by thread/inputs,
   we may need to either bump a run id or document how to start a clean
   thread while reusing the on-disk state.

## Proposed work

### 1. Add an explicit "resume gate" at start

Add a small node after `preflight_sandbox` (or fold into `sync_task_list`)
that:

- Prints the current HEAD short SHA and subject.
- Prints the count of checked vs unchecked items in `todo.md`.
- Prints any uncommitted changes (`git status --short`).
- Fails fast if uncommitted changes exist and the implementor would have to
  choose between adopting or discarding them. The failure message should tell
  the operator to either commit, stash, or `git reset --hard HEAD` before
  resuming.

This makes the resume contract observable in logs and prevents silent
overwrite.

### 2. Tighten `sync_task_list`'s contract

Update the node description and prompt/script comment to state:

- `todo.md` is the source of truth for execution state once it exists.
- It is regenerated from `plan.md` only when absent.
- Existing check-offs, splits, and reorderings are preserved across runs.

No behaviour change is required if the script already does this; the goal is
to make it explicit and protected against future edits.

### 3. Make `implement_next_task` resume-aware

Adjust the implementor prompt so it explicitly:

- Reads `todo.md` and identifies the first unchecked item.
- Inspects `git log` for prior task commits referencing earlier items, to
  build context about what already exists.
- Inspects `git status` and refuses to silently overwrite uncommitted changes
  for an unchecked task; instead, either continue that task to completion and
  commit, or stop for human input.

### 4. Cover with a manual rehearsal

Document a manual rehearsal in the kaizen entry:

1. Run the workflow against `001-member-message-deliverability` with a forced
   failure injected after task 3 (e.g. by hand-editing a file so `dev check`
   fails inside `implement_next_task`).
2. Confirm 3 task commits exist and `todo.md` shows tasks 1–3 checked.
3. Re-run the workflow.
4. Confirm the new run starts at task 4 with no re-implementation of 1–3 and
   no extra commits for them.

### 5. Decide on Fabro thread strategy

Document, in the workflow's prompt directory, the recommended Fabro
invocation for resuming a partially completed iteration (new thread vs reused
thread). If Fabro memoization causes nodes to skip when they should rerun,
this is the place to capture the workaround.

## Acceptance criteria

- A documented resume contract exists for `iteration-implementation`.
- `sync_task_list` is explicitly safe to re-enter against an existing
  `todo.md` and never overwrites check-offs.
- `implement_next_task` selects the first genuinely unchecked task and does
  not redo committed work.
- A manual rehearsal demonstrates that a re-run after a mid-iteration failure
  performs no redundant task implementation.
- Operator guidance covers what to do with leftover uncommitted changes from
  a prior failed run.

## Non-goals

- Persisting LLM thread state across runs.
- Automatic detection and rollback of a partially-implemented uncommitted
  task. The conservative behaviour is to require a clean tree at resume time
  and tell the operator how to get there.
- Resuming across plan edits — if `plan.md` changes between runs in a way
  that invalidates earlier task commits, that is out of scope here and
  belongs to a separate plan-change-handling kaizen.

## Risks / follow-ups

- Fabro may treat each run as independent in ways that interact badly with
  on-disk state (e.g. caching). If so, this kaizen surfaces the gap and the
  fix may need to land in Fabro itself.
- Once resume works reliably, the temptation to make plans bigger increases.
  The "shrink iteration plans" kaizen should land alongside this one so we
  don't compensate for plan ambition by leaning on resumability.
