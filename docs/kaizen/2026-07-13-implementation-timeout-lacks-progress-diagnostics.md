# Problem: implementation timeout left only partial artifacts and weak diagnostics

Date: 2026-07-13

## Context

We launched Fabro delivery for iteration 053 after plan re-validation:

```bash
bin/dev fabro deliver docs/iterations/053-my-settings-email-addresses/plan.md
```

Delivery run:

- Run ID: `01KXD3CB79S308AKWV0WFEV8C4`
- Web UI: `https://fabro.home.wynne.family/runs/01KXD3CB79S308AKWV0WFEV8C4`
- Plan: `docs/iterations/053-my-settings-email-addresses/plan.md`
- Run branch: `origin/fabro/run/01KXD3CB79S308AKWV0WFEV8C4`
- Meta branch: `origin/fabro/meta/01KXD3CB79S308AKWV0WFEV8C4`

Task 001 completed and validated. Fabro then started task 002:

```text
002 Add verification state to the Person email-address read model/projection and database schema, with all existing rows backfilled as verified.
```

## Expected standard

Each `implement_next_task` node should either:

- complete one todo, check it off, and provide enough evidence for validation; or
- fail with a useful, task-specific reason that tells the operator what happened and what safe recovery path to use.

When a node hits its timeout, the workflow should make the abnormality easy to diagnose: selected todo, elapsed phase, last tool/action, changed files, whether any generated artifact is complete or partial, and whether the run should be resumed, retried from checkpoint, or salvaged manually.

## What happened

The task 002 `implement_next_task` agent ran for the full node timeout and then failed:

```text
handler timed out after 2400000ms
```

Fabro then routed to `task_not_ready`, which failed with the generic message:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

Log inspection showed no concrete product-code, migration, test, `dev check`, publish, or plan-conformance failure. The agent performed many reads, greps, and shell commands, then timed out. The only visible partial product artifact on the run branch was an empty generated migration:

```text
web/priv/repo/migrations/20260713073147_add_verification_state_to_membership_person_email_addresses.exs
```

with only:

```elixir
defmodule Memba.Repo.Migrations.AddVerificationStateToMembershipPersonEmailAddresses do
  use Ecto.Migration

  def change do

  end
end
```

The run's final inspect output also included the successful task-001 inspection artifact and generated `todo.md`, but there was no final task-002 assistant summary explaining what remained, why the agent was stuck, or whether the empty migration should be kept, discarded, or completed.

Two `read_file` tool calls during the task-002 attempt were marked `is_error=true`, but they were non-fatal and the agent continued for many more tool calls. Shell calls near the end completed successfully. The observable terminal cause was still the 40-minute implementation-node timeout.

## Impact

The run failed before task 002 validation. Main remained marked `implementing`, occupying the implementation WIP slot, while the useful task-001 work and the partial task-002 artifact lived only on the Fabro run branch.

The operator had to inspect logs and branches manually to distinguish:

- local deliver stream timeout versus remote run failure;
- real product/test failure versus provider/agent timeout;
- useful completed task-001 work versus incomplete task-002 artifact;
- safe resume/retry path versus manual salvage.

This wastes delivery time and makes recovery depend on manual log archaeology rather than explicit workflow evidence.

## What allowed it to happen

- `implement_next_task` has a single 40-minute wall-clock budget for reading, planning, editing, command execution, debugging, final summarizing, and todo check-off.
- The workflow has no deterministic timeout pre-stop hook that captures the active selected todo, current changed files, recent tool activity, last successful command, and partial-artifact warning.
- The terminal `task_not_ready` message collapses implementation timeout, validation/human-input states, and retry-budget exhaustion into one generic failure.
- The run branch preserves the partial diff, but there is no automatically written handoff note explaining which files are safe/unsafe to reuse after a timeout.
- The `fabro progress` summary reports only completed todo count and next todo; it does not say that the last attempt timed out while editing task 002 or list partial files.

## Observations

- This was not the same shape as a failing `dev check`; `dev check` was never reached.
- This was not a plan-validation failure; the plan had just re-validated successfully in run `01KXD2MZKDB0X6XGSYM6WD2GH1`.
- This was not a publish conflict; implementation never reached publication.
- The selected task was narrower than the earlier coarse-todo timeout note, but still timed out without a useful task-level handoff.
- The empty generated migration is especially risky as a partial artifact: if salvaged blindly, it looks like schema work started but contains no actual schema change.

## Why this matters

Implementation timeouts are inevitable, but they should be cheap to diagnose and safe to recover from. Without structured timeout diagnostics and a partial-work handoff, every timeout can become a manual forensic task. That slows delivery, blocks the WIP slot, risks losing valid checkpointed work, and increases the chance that incomplete generated artifacts are accidentally reused.

## Open questions

- Did the task-002 agent get stuck reasoning/planning, waiting on a command, or repeatedly inspecting files without editing?
- Should `implement_next_task` checkpoint or summarize partial progress before long-running commands and before timeout risk windows?
- Should Fabro classify `implement_next_task` timeout separately from validation/human-input failure in `progress`, `inspect`, and terminal messages?
- Should generated migrations or other high-risk partial files be flagged automatically when a task times out before validation?

## Possible prevention ideas

- Add an `implement_next_task` timeout/failure handoff artifact that records selected todo, changed files, recent tool calls, last command, and explicit partial-artifact warnings.
- Split terminal failure messages so `implement_next_task` timeout is reported distinctly from validation requiring human input or retry budget exhaustion.
- Teach `bin/dev fabro progress` to show the last failed node and selected todo, not only completed/remaining todo counts.
- Add a pre-timeout heartbeat/checkpoint convention in the implementation prompt: after creating migrations or other structural artifacts, either complete them promptly or write a visible note before continuing broad inspection.
- Consider a deterministic guard that rejects empty generated migrations at timeout/final-artifact boundaries before they can be mistaken for useful salvage.
