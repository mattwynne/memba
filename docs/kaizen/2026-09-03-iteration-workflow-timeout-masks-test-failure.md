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

#### Root-cause investigation / Five Whys: 2026-09-07 run `01M1X3TD59C6R2FDNJ7ARPKACD`

This investigation used `fabro inspect`, `fabro events --json`, `fabro logs 01M1X3TD59C6R2FDNJ7ARPKACD --tail 300`, the workflow and prompt, and the checkpoint branch/diffs. It corrects an important possible reading of the terminal status: this run did not reach a task-validation retry budget or either node-visit limit.

##### Direct answers

1. **What the outer 40-minute timer was waiting for.** It was waiting for the entire `implement_next_task@19` agent handler to return, not for a particular shell command or test. The node started at `2026-09-07T12:36:04.702654Z`; Fabro raised `handler timed out after 2400000ms` at `13:16:04.712209Z` (40:00.009555 later). Its configured `timeout="2400s"` covers all main-agent reasoning, tools, spawned-agent work, and waits in that handler.
2. **What the agent was doing when it was killed.** The main agent had spawned an independent review of the uncommitted task-019 candidate at `13:09:40` and, from `13:11:52`, was waiting for that subagent (`agent_id 57c1b303`). No completion event for that wait or subagent was recorded before cancellation. The subagent was still reviewing: it launched a focused `mix test` command at `13:14:21`, but that command exited in 1.198 seconds because the PostgreSQL socket `/tmp/devenv/postgres/.s.PGSQL.15432` was absent. That is an environment/setup failure, not a failing test assertion. It then continued source/test inspection; its last recorded action completed at `13:15:42`, after which an LLM request began with no recorded output before the outer timeout. Thus the logs establish an outstanding parent wait and a subagent in review/LLM work; they do **not** establish an exact inner wait, a hung command, or that provider overload caused the timeout. The retryable overloaded-provider messages occurred earlier and requests subsequently completed.
3. **Why there was no usable timeout/recovery handoff.** `implement_next_task` has only a success edge to `pre_validate_snapshot`; every failure, including a system timeout, takes the unconditional edge labelled `Implementation/provider failure` to `task_not_ready`. No timeout-specific node records the selected task, last activity, last command result, unvalidated diff, checkpoint SHA, or resume command. `task_not_ready` then emits the static validation/retry-budget sentence and exits. Fabro did preserve the candidate as failed checkpoint `7861311f1` and pushed `origin/fabro/run/01M1X3TD59C6R2FDNJ7ARPKACD`; the documented manual resume procedure existed in `.fabro/workflows/README.md`. The failure was therefore not loss of recovery material, but failure to make the safe recovery handoff visible at the point of failure.
4. **Deeper systemic cause.** The workflow models a prompt node as either successfully completed or generically failed. A hard wall-clock cancellation of a composite agent handler is treated identically to an implementation/provider failure, while task validation and its evidence run only after a successful return. The delivery contract has no structured partial-progress/timeout artifact or child-work deadline/reserve. That design conflates (a) an incomplete task, (b) a failed validation/retry path, and (c) an externally cancelled handler, so the terminal classification is generated by the generic failure script rather than by the actual timeout event.

##### What happened, factually

- Task 018 was the last validated task. After the task loop selected task 019, its requirement was to authorize the current person through an active group with sufficient conversation access; tasks 020–022 remained unchecked.
- The task-019 handler changed `web/lib/memba/messaging.ex`, `web/lib/memba_web/member_message_detail.ex`, and five focused conversation/detail/delivery test files. The resulting failed checkpoint has 458 additions and 89 deletions. It was created only after the handler was cancelled, so it is unvalidated candidate work, not evidence that task 019 completed.
- Because the handler never returned, `pre_validate_snapshot`, `validate_task`, and `task_gate` were not visited for task 019, and task 019 was not checked off.
- The 19th `implement_next_task` visit was below its `max_visits=30`; the graph's loop nodes were at most 19 visits, below `max_node_visits=80`. The `budget_exhausted` terminal class comes from the deliberately failing `task_not_ready` script. The immediately preceding node failure was `transient_infra`, system actor `timeout`; it was not a visit-limit breach.
- The parent agent had earlier waited for a different task-019 research subagent, which completed successfully at `13:01:35` after 56 turns. The subsequent review subagent and its unfinished wait consumed the final minutes. This shows where the final time went, but does not prove that spawning/reviewing was the underlying reason the task could not finish within 40 minutes.

##### Five Whys

| Why | Established answer | Status |
| --- | --- | --- |
| 1. Why did task 019 have no validation result? | Fabro cancelled `implement_next_task@19` at its 2,400-second handler timeout before the handler returned; validation is reachable only from the success edge. | Fact |
| 2. Why did the run report “task validation requires human input or exceeded retry budget”? | The timeout took the unconditional `implement_next_task -> task_not_ready` edge, and `task_not_ready` prints that static text. | Fact |
| 3. Why did that terminal path not say what actually timed out or how to continue safely? | It has no timeout-specific branch or handoff artifact; it discards the original failure context in favour of a generic script failure. | Fact |
| 4. Why could an incomplete task leave only archaeology rather than a validated/retryable state? | The workflow checkpoints the worktree automatically, but its task protocol is atomic: selection, implementation, focused checks, and check-off must all finish before the success-only validation protocol can run. | Fact |
| 5. Why is a hard cancellation indistinguishable from validation/retry exhaustion? | The workflow lacks an explicit failure taxonomy and recovery contract for timed-out composite agent work (including spawned agents). | Root cause |

##### Hypotheses deliberately not promoted to findings

- The 40-minute budget may be too small for task 019's implementation plus independent review, or the implementation/review approach may have spent time inefficiently. The timestamps show both activities; they do not prove either was unnecessary or sufficient to cause the timeout.
- The two provider-overload retries may have contributed small delays. Successful later responses and the absence of a causal timing chain mean they are not established as the cause.
- The missing PostgreSQL socket prevented one focused test invocation, but that invocation ended quickly and was followed by continued review. It is evidence of a validation-environment problem, not proof that it caused the outer timeout or that the candidate had a product test failure.

The next improvement should be evaluated against this root cause: preserve the existing branch/checkpoint behaviour, but add a timeout-specific handoff that emits the failed node, selected todo item, original timeout/error, last durable checkpoint and diff status, and the documented resume command. It should not relabel a timeout as a validation/retry-budget failure.

#### First recovery experiment: single-owner per-task nodes

Before retrying iteration 058, we selected one smaller intervention aimed at completion probability rather than attempting every prevention idea at once. Run events show that task 019 spawned a research subagent 24 seconds after the node began. The parent started waiting for it at `12:46:00`; it returned at `13:01:35` after 56 turns. The parent then spawned a second, independent review subagent at `13:09:40` and waited from `13:11:52` until the outer timeout at `13:16:04`. Across the task-019 parent session, Fabro recorded 99 tool calls, including two spawns and two waits.

The first research result may have helped the implementation, so this evidence does not prove all delegation is waste. It does establish two avoidable deadline risks:

- child work is unbounded unless the spawning agent supplies `max_turns`;
- the second review duplicated the workflow's mandatory next-stage `validate_task` review and prevented the implementor from returning while time remained.

As the first controlled improvement, `implement_next_task.md` now makes each bounded per-task node a single-owner stage: do not spawn subagents and do not commission an extra independent review. It also tells resumed agents to inspect existing implementation notes, reviews, recovery handoffs, and committed failed candidate checkpoints before repeating broad research. The existing focused-validation requirement, automatic checkpoint, independent `validate_task`, final `dev ci`, plan-conformance gate, and publish gate remain intact.

A focused contract regression checks those invariants. The next resumed delivery run is the experiment: if it completes task 019 without child-agent waits, this intervention helped; if it fails elsewhere, investigate that evidence before adding another safeguard. Missing-PostgreSQL-socket classification and a timeout-specific terminal handoff remain separate candidate improvements, deliberately not bundled into this experiment.
