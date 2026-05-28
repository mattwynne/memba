# Idea: task contract validation for iteration workflow

Date: 2026-05-28

## Context

The simplified task loop improved ownership by letting the implementor pick, implement, validate locally, and check off one task. However, later runs exposed another reliability issue: the independent `validate_task` stage can still make decisions from stale or summarized context rather than live repository evidence.

Current important observations:

- `validate_task` is a prompt node (`shape=tab`). Fabro docs say prompt nodes never invoke tools.
- Therefore `validate_task` cannot run `git status`, inspect the live diff, read changed files, or verify actual commits.
- In one run, validation diagnosed a stale `commit_task` replay/memoization issue, but the evidence suggests it may have inferred this from old summarized context rather than live state.
- We want a validator to call its shot before implementation, then validate afterwards against its own expected outcome.

Matt’s desired shape:

> Have the same agent call the shot before the task is implemented to predict the outcome, then validate afterwards.

We investigated whether Fabro supports one dynamic `thread_id` per task. It does not appear to support runtime-context templating in `thread_id`. Workflow templates are rendered once before run execution and can reference `goal` and static `inputs`, not runtime context such as the current task number.

## Goal

Make per-task validation evidence-based and less prone to stale context by adding an explicit task contract step before implementation.

The validator should:

1. Inspect the current todo list, plan, ADRs, and repository state before implementation.
2. Select or confirm the next task.
3. Predict expected artifacts, tests, commands, todo changes, and boundaries.
4. Persist this as a task contract.
5. After implementation, validate the live working tree against the contract.

## Recommended design

Use a task contract file rather than relying on dynamic thread IDs.

### Parent loop

```text
sync_task_list
  -> check_task_list
  -> scope_next_task
  -> implement_next_task
  -> pre_validate_snapshot
  -> validate_task
  -> commit_task
  -> post_commit_verify
  -> sync_task_list
```

### `scope_next_task`

Make this an agent node, not a prompt node.

Responsibilities:

- Read `plan.md` and `todo.md`.
- Pick the first unchecked ordinary todo task.
- Read relevant ADRs and project/tool docs.
- Inspect current repo state.
- Write `.fabro/tmp/current-task-contract.md` containing:
  - selected todo line number and exact text;
  - scope boundaries;
  - expected files/modules/config/tests likely to change;
  - expected focused validation commands;
  - todo check-off expectation;
  - ADR constraints;
  - red flags that should cause human input.
- Emit context updates such as:
  - `task_contract_ready=true`
  - `task_contract_path=.fabro/tmp/current-task-contract.md`

### `implement_next_task`

Keep this as the implementor node.

Responsibilities:

- Read `.fabro/tmp/current-task-contract.md` before editing.
- Implement the contracted task only.
- Run focused tests and checks.
- Check off the same todo line named in the contract.
- Do not commit.
- If the contract is wrong or unsafe, stop and report rather than improvising beyond the plan.

### `pre_validate_snapshot`

Add a deterministic command node immediately before validation.

Write `.fabro/tmp/pre-validate-snapshot.md` with live evidence:

- `git rev-parse --short HEAD`
- `git status --short`
- `git diff --stat`
- `git diff -- docs/iterations/.../todo.md`
- `git diff --name-only`
- recent relevant test command output if available or referenced by implementor summary

This gives the validator hard evidence independent of summarized prior context.

### `validate_task`

Make this an agent node with tool access, not `shape=tab`.

Responsibilities:

- Read `.fabro/tmp/current-task-contract.md`.
- Read `.fabro/tmp/pre-validate-snapshot.md`.
- Inspect live repository state directly with tools as needed.
- Compare expected artifacts/tests/todo check-off against actual evidence.
- Route:
  - `VALID` if contract is satisfied;
  - `RETRY` if another clean attempt is safe;
  - `HUMAN_INPUT` if the contract/plan/task is ambiguous, unsafe, repeatedly failing, or blocked.

### `commit_task`

Keep deterministic commit guardrails:

- fail if no staged changes;
- fail if acceptance feature files changed;
- fail if only `todo.md` changed;
- fail if no todo check-off exists;
- fail if more than one ordinary todo was checked off without explicit split/merge rationale;
- avoid non-essential tools that may be missing in the sandbox (`awk`, etc.).

### `post_commit_verify`

Add a deterministic command node after commit.

Verify:

- HEAD changed from pre-commit HEAD;
- the latest commit includes non-`todo.md` artifacts;
- latest commit includes exactly the intended todo check-off;
- no acceptance feature files changed;
- `.fabro/tmp/current-task-contract.md` does not get committed.

## Alternative: child workflow per task

A child workflow can approximate one validator thread per task.

Parent loop:

```text
sync_task_list
  -> check_task_list
  -> one_task_child_workflow
  -> sync_task_list
```

Child workflow:

```text
scope_task      thread_id="validator" fidelity="full"
implement_task
validate_task   thread_id="validator" fidelity="full"
commit_task
```

Because each child workflow invocation has its own execution context and checkpoint state, the static `validator` thread may effectively be per task. This should be tested with a small workflow before migrating the real workflow.

Pros:

- Better per-task isolation.
- Cleaner event stream for one task at a time.
- Closer to Matt’s desired “same agent before and after” model.

Cons:

- Adds another workflow file and orchestration layer.
- Need to confirm how thread/session state behaves across repeated child workflow invocations.
- Context merge semantics may complicate parent loop state.

## Acceptance criteria

- `validate_task` is no longer a prompt-only node; it has tool access.
- A pre-implementation task contract is written for each task.
- The implementor reads and follows the current task contract.
- Validation compares live repo evidence against the task contract.
- Stale summaries alone cannot cause validation to pass or fail.
- Commit guardrails remain deterministic and avoid missing sandbox tools.
- A post-commit verification node confirms the intended commit actually happened.
- Workflow validates with:

```bash
fabro validate .fabro/workflows/iteration-implementation/workflow.toml
```

## Open questions

- Should we first implement the simpler contract-file design in the existing workflow, or prototype the child-workflow-per-task design?
- Can Fabro expose a clean, deterministic way for script nodes to set context updates without an LLM routing node?
- Should task contracts be committed as part of task evidence, or kept in `.fabro/tmp` only? Current preference: keep them uncommitted.
