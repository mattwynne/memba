# Problem: iteration workflow timeout masks the actionable test failure

Date: 2026-09-03

## Context

We launched iteration 056, Group audience foundation, through:

```sh
bin/dev fabro deliver docs/iterations/056-group-audience-foundation/plan.md
```

The original implementation run was `01M1JZX34A6PX42CN82N900CBZ`.

The run checkpointed and independently validated tasks 001–016. While working on task 017, which integrates existing message and compose behaviour with the new Everyone group, browser acceptance setup began failing. The run was eventually recovered by rewinding to the task-016 checkpoint and starting run `01M1M50HVVDTCG26DHB81Y00MV`.

Relevant delivery machinery:

- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`

## Expected standard

When an implementation task exposes a failing required quality gate, the workflow should preserve completed work, make the first actionable failure obvious, and distinguish a product/test diagnosis from a workflow time-budget failure. An operator should not need to reconstruct that distinction from raw Fabro events and logs before choosing a safe recovery path.

The implementation prompt should support a fast, focused diagnosis loop before repeating an expensive full gate. The workflow's final quality gate remains the delivery-quality gate.

## What happened

The new strong system-group membership path caused acceptance setup's `ensureMember` command to fail with:

```text
{:error, :consistency_timeout}
```

The underlying warning was:

```text
Consistency timeout waiting for aggregate "clb_..." at version 5
```

This was a real application integration failure, not a model or provider outage. However, the agent ran full `PATH="$PWD/bin:$PATH" dev check` twice while investigating the browser-facing task. Each command was stopped after about 10 minutes, including one for which the agent requested a 20-minute tool timeout. The browser suite spent much of that time repeatedly waiting about five seconds for acceptance setup to fail.

The `implement_next_task` node has a 40-minute timeout. It expired while the agent was still receiving model responses and making tool calls. The workflow then routed the timeout through:

```text
Implement Next Task -> Fail: Task Needs Human Input
```

The terminal text said only:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

The exact acceptance failure, the two shell-command timeouts, and the fact that the model remained healthy were available only after manual inspection of `fabro inspect`, `fabro events`, and `fabro logs`.

## Impact

Severity: delivery-blocking workflow friction with quality risk.

Sixteen validated task checkpoints were preserved, but task 017 consumed its full stage budget without producing a clear task-level failure report. The generic terminal status initially suggested an infrastructure or model problem. Manual log archaeology was needed to identify the actual application consistency failure and to recover safely from the last validated checkpoint.

Repeated broad gates also consumed time that could have been spent on a minimal reproduction and a focused fix.

## What allowed it to happen

The project-local iteration workflow combines several failure modes:

- `implement_next_task` has a fixed 40-minute timeout in `workflow.fabro`.
- The implementation prompt directs browser-facing tasks to run full `dev check`, even though the workflow will run a final quality gate before publication.
- A timeout in the implementation prompt node follows the same graph edge as an implementation/provider failure and terminates at `task_not_ready`; the terminal node does not surface the last failing command or its meaningful error.
- The Fabro agent shell layer enforced an apparent 10-minute command ceiling despite longer requested tool timeouts. The project workflow neither knows that ceiling nor budgets a full browser `dev check` around it.

The first failure was therefore obscured by a later timeout classification.

## Observations

- `fabro logs 01M1JZX34A6PX42CN82N900CBZ` shows continuous successful GPT-5.5 responses through the final stage; there were no model-provider, authentication, rate-limit, or connection failures.
- The two long commands were both full `dev check` runs. They terminated after roughly 602 seconds with `Termination: timed_out`.
- The acceptance failure occurred while setting up club membership, before the scenario-specific behaviour ran.
- The existing prompt already asks agents to prefer focused validation, but its browser-facing exception encourages a costly full gate within every relevant task.
- The recovery mechanism preserved the task-016 checkpoint. `fabro rewind` created a new recovery run rather than mutating the failed run in place; this was not obvious from the delivery helper's recovery output.

## Why this matters

A workflow that reports a product integration failure as generic infrastructure/human-input friction slows recovery and weakens confidence in the required quality gate. It also risks teaching agents and operators to rerun broad checks instead of first isolating the failing boundary.

Long, cross-context iterations will encounter integration failures. The delivery system should make such work observable and resumable without treating an exhausted task budget as a human product decision.

## Open questions

- Is the approximately 10-minute tool ceiling a Fabro platform limit, an environment setting, or an agent-tool policy that the project can configure?
- Should a browser-facing task run full `dev check` itself, or should it use targeted acceptance evidence and leave the full gate to the workflow's final validation stage?
- Can a prompt-node timeout be routed to a distinct recovery node that captures the selected task, last command, and last command output before declaring the run terminal?
- Can `bin/dev fabro deliver` report the supported rewind/fork recovery path when an implementation run fails after durable checkpoints?

## Possible prevention ideas

- Add a task-timeout recovery branch that records the selected task and the last failed command/error, rather than routing directly to generic human input.
- Align workflow stage and agent-shell command time budgets, or fail fast when a requested command timeout exceeds the supported ceiling.
- Amend the implementation prompt so a failed full gate triggers a minimal reproduction and focused diagnosis before another full gate; reserve repeated full `dev check` for final validation or after the targeted failure is fixed.
- Document the rewind/fork recovery flow alongside the existing run inspection commands.

### Additional observation: 2026-09-05 — iteration 057 final acceptance task timed out

Implementation run `01M1QDT82FG7AJ9YQ93QMFE5KN` completed and independently validated tasks 001–017. Task 018 added domain/browser support for the Admin email scenarios, but its `implement_next_task` node reached the same 2,400-second hard timeout before it could finish debugging, check off the task, or run the final quality gate.

The run branch preserved 128 checkpoints at `origin/fabro/run/01M1QDT82FG7AJ9YQ93QMFE5KN`. Domain acceptance was green at 104 tests. Browser acceptance initially reported three identical outer Cucumber step timeouts and one step-definition failure; because Cucumber and Playwright both used 30-second limits, the outer timeout initially hid Playwright's more actionable error.

Re-running one scenario with a longer outer step budget exposed the real first failure: the Admin setup helper and the ordinary message setup helper had separate slug-normalisation functions. One used the fixture slug `kmc`; the other used `kootenay-mountaineering-club`. The Admin helper therefore created a second same-named club, overwrote scenario state, and later tried to change its slug to the already-used `kmc`. The UI correctly disabled `Save club`, and Playwright waited until its 30-second timeout. A separate reply assertion had a three-capture regular expression but only two JavaScript function arguments.

Recovery and prevention:

- Recovered the preserved run branch into `/tmp/memba-057-finish` rather than restarting 18 tasks.
- Moved the canonical fixture slug rule into shared `member_message.js` support and made both ordinary-member and Admin setup use it, preventing duplicate same-named clubs with different slugs.
- Added a fast Node regression asserting the canonical KMC and Nelson fixture slugs.
- Corrected the reply step-definition arity.
- Re-ran the four `@iteration-057` browser scenarios successfully before the full gate.
- Independent review found that a forged non-Admin reply was blocked but returned a raw authorization error, leaving the inbound email without a terminal audit outcome. The reply path now records and returns the normal rejected-inbound result; its regression proves no message, delivery, acceptance, or follow is created.
- Final `dev check` passed with 1,129 tests, 0 failures, and 122 browser scenarios / 877 steps passing.

The remaining systemic timeout/diagnostic questions in this note still apply. This recovery demonstrates a useful immediate operating standard: when an outer Cucumber timeout hides a wrapped Playwright helper error, rerun one named scenario with `ACCEPTANCE_STEP_TIMEOUT_MS` longer than Playwright's inner action timeout before changing application code.

### Additional observation: 2026-09-07 — iteration 058 failed after 18 durable task checkpoints

#### Observed facts

Iteration 100, generic group-scoped club home, was deliberately renumbered to iteration 058 after validated iterations 098 and 099 were deferred. Plan-validation run `01M1X3NCJGF4KCJRZ379V4V1A9` succeeded and `main` recorded iteration 058 as `validated` in `770955989`.

The implementation launcher was run from `main` as:

```sh
./bin/dev fabro deliver docs/iterations/058-generic-group-scoped-club-home/plan.md
```

It accepted the predecessor and clear-WIP checks, reserved the slot in `ebdc63b08`, and started implementation run `01M1X3TD59C6R2FDNJ7ARPKACD` with that exact source SHA. The launcher later reported `Failed ... 494m43s $176.23`; `3483e1dac` then restored iteration 058 to `validated` on `main`.

`fabro inspect 01M1X3TD59C6R2FDNJ7ARPKACD --no-upgrade-check` records:

- final `failure_class=budget_exhausted` and signature `task_not_ready|budget_exhausted|... task validation requires human input or exceeded retry budget`;
- a final `implement_next_task` failure of `handler timed out after 2400000ms`, categorized there as `transient_infra` with system actor `timeout`;
- 18 successful visits each to `pre_validate_snapshot`, `validate_task`, and `task_gate`, followed by the 19th `implement_next_task` visit timing out;
- `implement_next_task` configured with `timeout=2400s` and `max_visits=30`, while the graph has `max_node_visits=80`.

The inspected visit counts are below both configured visit limits (`implement_next_task=19`, graph-loop nodes at most 19). This run did **not** report Fabro's explicit `node "..." visited ...; run is stuck in a cycle` failure. The observed terminal event was the 40-minute prompt-node timeout; `budget_exhausted` is the terminal failure classification after `task_not_ready`, not evidence by itself that either configured visit ceiling was reached.

Task 018 was durably checkpointed in `e8002dbb9`, independently validated, and marked complete. It added only `docs/iterations/058-generic-group-scoped-club-home/conversation-access-review.md` and the task-018 check-off. The validation evidence records 25 focused tests with zero failures and a passing `git diff --check`. The next failed checkpoint, `7861311f1`, contains unvalidated changes for the subsequent access-control work; the terminal run commit is `0c78bd91` on `origin/fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD`. That branch is 136 commits ahead of `main` and preserves the completed and partial checkpoint work.

#### What the delivery machinery exposed

The task-draining loop re-enters `sync_task_list`, `todo_readable`, `all_tasks_done`, `implement_next_task`, pre-validation, and validation for every task. The workflow has fixed per-node time and visit ceilings, but no preflight or intermediate delivery boundary that compares the remaining task list with those limits or creates a handoff when an iteration is approaching them.

The terminal `task_not_ready` script still emits only:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

That message does not name the timed-out node, the current task, the preserved run branch, the checkpoint SHA, or a resume command. This is true even though `.fabro/workflows/README.md` already documents a manual resume procedure. The gap is therefore failure-time handoff and discoverability, not the complete absence of recovery documentation.

#### Safe evidence and recovery reference

The following commands are evidence-gathering or documented recovery preparation; they were not used to resume or change this iteration during this investigation:

```sh
fabro inspect 01M1X3TD59C6R2FDNJ7ARPKACD --no-upgrade-check
git fetch origin fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD
git log --oneline main..origin/fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD
git diff --stat main...origin/fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD
git show --stat e8002dbb9 7861311f1
```

The documented recovery path in `.fabro/workflows/README.md` is:

```sh
git switch -c resume/01M1X3TD59C6R2FDNJ7ARPKACD --track origin/fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD
fabro run .fabro/workflows/iteration-implementation/workflow.toml \
  -I plan_path=docs/iterations/058-generic-group-scoped-club-home/plan.md \
  --auto-approve
```

That starts a new run from the checkpoint branch and must be a deliberate operator decision after inspecting the unvalidated final checkpoint; it is not a safe automatic retry from the terminal message.

#### Hypotheses and follow-up questions

- The 22-task iteration was long enough for the fixed 40-minute task budget and per-run loop limits to become an operational delivery constraint, even though the recorded terminal trigger was a timeout rather than a visit-limit breach.
- `budget_exhausted` may be an overly broad terminal classification in this path. Its relationship to node timeouts, run cost, and the configured visit ceilings needs confirmation from Fabro's failure-class semantics and events before it is treated as a capacity-limit diagnosis.
- A delivery launcher that restores lifecycle status after failure should also surface the run ID, branch, last durable task/checkpoint, failed node, and the existing documented resume command. Otherwise useful checkpointed work still requires manual archaeology.
- The workflow may need an explicit capacity/handoff policy for long task lists: for example, a preflight warning, a bounded task batch, or a timeout artifact that makes the next safe action obvious. These are prevention ideas, not conclusions from this single run.
