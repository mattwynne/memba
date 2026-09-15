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

### Additional observation: 2026-09-12 — iteration 060 timed out while repeating the full gate inside the manual-browser task

#### Observed facts

Iteration 060, Calm LiveView reconnection feedback, was launched as implementation run `01M2AK7G61EBCXF2SVGK3T0QR7` for plan `docs/iterations/060-calm-liveview-reconnection-feedback/plan.md`.

Evidence inspected for this note:

- Fabro UI: `https://fabro.home.wynne.family/runs/01M2AK7G61EBCXF2SVGK3T0QR7`
- `fabro inspect 01M2AK7G61EBCXF2SVGK3T0QR7 --json`
- `fabro events 01M2AK7G61EBCXF2SVGK3T0QR7 --json`
- `fabro logs 01M2AK7G61EBCXF2SVGK3T0QR7`
- `fabro dump 01M2AK7G61EBCXF2SVGK3T0QR7 --output /tmp/fabro-dump-060`
- `origin/fabro/run/01M2AK7G61EBCXF2SVGK3T0QR7`
- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`

The run started at `2026-09-12T10:40:44Z` and failed at `2026-09-12T13:06:27Z` after about 2h25m. Its final preserved commit is `067e15d7255444b3211d406326500983e5bb3696` on `origin/fabro/run/01M2AK7G61EBCXF2SVGK3T0QR7`.

The terminal message was:

```text
goal gate unsatisfied for node publish_to_main and no retry target
```

That message is downstream of the actual implementation-loop failure. The immediately preceding task failure was:

```text
implement_next_task|transient_infra|handler timed out after 2400000ms
```

The next `task_not_ready` node then failed with:

```text
Iteration implementation failed: task validation requires human input or exceeded retry budget.
```

The run had completed and independently validated tasks 001–008. The ninth `implement_next_task` visit selected task 009:

```text
009 Manually simulate brief, longer client, and server interruptions in a real browser; compare the result with the approved raw HTML prototype at desktop and narrow mobile widths.
```

The failed checkpoint for that same visit contains useful task-009 work:

- `docs/iterations/060-calm-liveview-reconnection-feedback/manual-browser-validation.md`
- the task-009 check-off in `docs/iterations/060-calm-liveview-reconnection-feedback/todo.md`
- a selector-target fix in `web/lib/memba_web/components/layouts.ex`
- matching component-test updates in `web/test/memba_web/components/layouts_test.exs`

At the final checkpoint, 9 of 10 tasks were checked off. Task 010 remained unchecked:

```text
010 Run focused JavaScript/component/CSS tests, then run `dev check`.
```

The workflow therefore had not yet reached its deterministic `dev_check` node or publish path.

#### Timing of the failed node

`implement_next_task@9` started at `2026-09-12T12:26:15.535Z` with `timeout="2400s"` in `workflow.fabro`. It timed out at `2026-09-12T13:06:15.543Z`, almost exactly 40 minutes later.

Inside that single prompt-node budget, the agent:

1. Inspected the plan, todo list, prototype, LiveView code, acceptance lifecycle, and recent checkpoints.
2. Created a temporary Playwright/Chromium harness in ignored `.fabro/tmp/manual_reconnect_check.cjs`.
3. Ran that harness repeatedly. Several attempts exited after roughly 70–89 seconds while the agent debugged the harness/simulation and then a real overlap defect.
4. Reported at `12:51:44Z` that the corrected browser matrix passed at desktop and mobile widths, including brief reconnect suppression, distinct client/server states, automatic dismissal, page retention, pointer transparency, and reduced-motion behaviour.
5. Wrote the durable manual-browser evidence file and checked off task 009.
6. Ran `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs --trace`, which passed 22 tests.
7. Started `PATH="$PWD/bin:$PATH" dev check` at `12:52:29Z`.

The first `dev check` command was itself stopped by the Fabro shell layer after about 602 seconds:

```text
Termination: timed_out
Exit code: none
Duration: 602132ms
```

Its output shows meaningful progress rather than a test failure:

- ExUnit/precommit had run earlier in the command.
- Browser acceptance started its Phoenix lifecycle at `12:54:16Z`.
- All browser scenarios passed: `134 scenarios (134 passed)`, `951 steps (951 passed)`, `7m25.462s`.
- The acceptance `AfterAll` hooks closed the shared browser and stopped the Phoenix browser acceptance lifecycle at `13:01:41Z`.

There is no captured failing assertion or failing scenario in that command output. The remaining unknown is why the shell command did not return a final exit status before Fabro killed it roughly 48 seconds after the acceptance lifecycle had stopped.

After that command-level timeout, the agent tried to work around the apparent 10-minute command ceiling by launching a second full gate in the background:

```sh
nohup bash -c 'PATH="$PWD/bin:$PATH" dev check; status=$?; printf "%s\n" "$status" > /tmp/memba-iteration-060-dev-check.status' > /tmp/memba-iteration-060-dev-check.log 2>&1 &
```

That second `dev check` was still running when the outer prompt node hit its 40-minute deadline. Polling at `13:04:38Z` showed it in ExUnit/precommit output and still `RUNNING`. Polling at `13:05:33Z` showed it in browser acceptance, just starting `features/authentication.feature:52`, and still `RUNNING`. The next poll command was sleeping when Fabro deactivated the agent session at `13:06:15Z` and failed the node. The run then stopped the Docker sandbox at `13:06:27Z`; no status-file completion for the background `dev check` is recorded.

The agent attempted a process check after the first timeout:

```sh
ps -eo pid,ppid,stat,etime,cmd | grep -E 'dev check|cucumber-js|mix test|phx.server' | grep -v grep || true
```

but the sandbox image did not include `ps`, so this produced only:

```text
/bin/bash: line 1: ps: command not found
```

That absence is an observability gap; it is not evidence that no child process was running.

#### What the evidence supports

- The run timed out because `implement_next_task@9` exhausted its fixed 40-minute handler budget before returning success.
- The active work at timeout was validation/revalidation of task 009, not task 010. The final task remained unchecked.
- The first full `dev check` reached the end of the browser acceptance suite with all scenarios passing, then hit Fabro's apparent 10-minute shell-command ceiling before a final command status was captured.
- The second full `dev check` was making progress and was still in browser acceptance when the outer prompt-node timeout fired.
- The final `task_not_ready` and `publish_to_main` messages are secondary classifications. They should not be treated as the established root cause.

#### Hypotheses and unknowns not promoted to findings

- The first `dev check` may have been stuck in process cleanup, npm/Cucumber exit handling, lock release, or Fabro command bookkeeping after acceptance `AfterAll`; the logs do not identify which.
- The second `dev check` might have passed if allowed to finish, or might later have failed; no status file or final output was captured before sandbox stop.
- There is no evidence in this run of the PostgreSQL-connection leak observed in iteration 059 browser-review timeouts. Do not assume the same cause without process/database evidence from this run.
- The missing `ps` and `file` tools slowed diagnosis but are not established as the cause of the timeout.

#### Five Whys

| Why | Established answer | Status |
| --- | --- | --- |
| 1. Why did iteration 060 not reach publication? | The workflow never got past `implement_next_task@9`; Fabro cancelled that prompt node at its 2,400-second timeout before it could return success and proceed to validation/task 010/final `dev_check`. | Fact |
| 2. Why did `implement_next_task@9` not return before 40 minutes? | It spent most of its budget completing and debugging the manual browser validation task, then ran full `dev check`; the first full gate hit the shell-command timeout, and the second full gate was still running when the outer node deadline arrived. | Fact |
| 3. Why was full `dev check` being run inside task 009 when task 010 and the workflow both had final-gate responsibility? | The plan had a separate final validation todo, and the workflow has a `dev_check` node after all todos, but `implement_next_task.md` also tells browser-facing tasks to run full `dev check` during the per-task node. This allowed an expensive duplicate broad gate inside the manual-browser task. | Fact |
| 4. Why did that duplication become a timeout instead of a controlled handoff? | The prompt node has one hard 40-minute budget for research, edits, harness debugging, focused checks, full gates, polling, and final summary. The workflow does not reserve enough time for a long command, fail fast when the remaining node budget is too small, or align the apparent 10-minute shell-command ceiling with the duration of `dev check`. | Fact plus one unknown: the exact source/configurability of the 10-minute command ceiling remains unconfirmed. |
| 5. Why did the terminal report point at validation budget/human input/publish rather than this timing collision? | A prompt-node timeout takes the generic `implement_next_task -> task_not_ready` failure edge, and the run-level goal gate then reports that `publish_to_main` was unsatisfied. There is no timeout-specific branch or handoff artifact that preserves the selected task, last command, command timeout, remaining todos, and recovery branch in the terminal failure. | Root cause |

#### Root-cause confidence

High confidence in the immediate mechanism: the `implement_next_task@9` prompt-node wall clock expired while a second full `dev check` was still running, after a first full `dev check` had already hit the shell-command timeout.

Medium confidence in the deeper cause: the workflow/prompt time-budget contract encouraged or allowed a full `dev check` inside a browser-facing task even though a separate final task and deterministic workflow gate existed. That duplicated an expensive validation boundary inside a node that had already spent much of its budget on legitimate manual-browser validation.

Low confidence in any claim that product code, PostgreSQL leakage, provider outage, or a failing test caused the final timeout. The captured outputs show progress and passing browser scenarios, not a failing assertion or hung database evidence.

#### Recovery and hazard notes

- The useful checkpoint is already pushed: `origin/fabro/run/01M2AK7G61EBCXF2SVGK3T0QR7` at `067e15d7255444b3211d406326500983e5bb3696`.
- That checkpoint includes task 009 checked off and task 010 still unchecked. A recovery should avoid redoing the manual browser matrix unless it intentionally wants to revalidate task 009.
- The original Docker sandbox was stopped by the failed run. Any background `dev check` launched inside it should be treated as not having produced reliable final evidence; use the preserved branch/worktree state, not `/tmp/memba-iteration-060-dev-check.status`, as the recovery source of truth.

#### Recommended preventive interventions

- Make full `dev check` a single deterministic workflow-owned gate after all implementation todos, and remove the prompt instruction that browser-facing per-task nodes should run the full gate. Per-task nodes should provide focused component/JS/CSS/manual-browser evidence that proves their selected todo.
- If a per-task node is allowed to run a broad gate, require a remaining-budget preflight before starting it: do not start a 10-minute-plus command when the prompt node has insufficient wall-clock reserve to capture output, summarize, and return.
- Align Fabro shell-command ceilings with project quality-gate durations, or make the shell layer fail immediately when a command is known to require more time than the supported ceiling.
- Add a timeout-specific `implement_next_task` failure branch that records selected todo, checked/unchecked task state, last command, last command termination, recent output tail, latest checkpoint SHA, and a concrete resume/recovery command.
- Have `dev check` or the workflow emit phase-level status artifacts (`setup`, `precommit`, `acceptance started`, `acceptance completed`, final exit) so a command timeout after a passing acceptance summary is distinguishable from a test failure and from post-suite cleanup/bookkeeping.

## Partial resolution: focused validation in ordinary task nodes

Date: 2026-09-12

Root cause addressed: the browser-facing exception in the implementation prompt allowed full-suite validation inside task 009 after its manual-browser work. That extra gate consumed the remaining prompt-node budget and led to a detached second attempt without a final result. This intervention removes that exception, not the final quality requirement.

Fix applied:

- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`: ordinary tasks use focused checks, including targeted browser scenarios or a browser harness when relevant. Full `dev check`/`dev ci` is not required merely because a task changes UI, routing, or acceptance support. The prompt requires time-budget awareness and forbids detached full-suite retries to evade a command timeout.
- `.fabro/workflows/iteration-implementation/prompts/validate_task.md`: independent validation accepts appropriate focused evidence without reinstating the browser exception. Explicit full-validation tasks still require a successful command exit; a passing scenario summary followed by a timeout is insufficient.
- `.fabro/workflows/README.md`: documents the boundary and the remaining explicit-final-task duplication.
- `.fabro/workflows/iteration-implementation/scripts/test_task_execution_contract.sh`: adds regression checks for focused browser validation, preserved final-task scope, timeout handling, and unchanged final-gate/repair routing.

The workflow graph, final `dev ci` gate, independent validation, plan conformance, artifact policy, and publication gate are unchanged. There is no increase to timeouts, removal of tests, or production-code change.

Additional verified evidence: `docs/tools/fabro/public/agents/tools.mdx`, under “Timeouts”, documents `max_command_timeout_ms = 600000` as the agent-shell hard cap even when a command requests longer. The approximately ten-minute limit is therefore documented behaviour, not merely an inferred timestamp pattern. Whether this project's deployed Fabro configuration can override it remains a separate question.

Validation:

- The new prompt-contract checks failed before the prompt changes, naming the missing focused-browser, full-gate, and detached-retry rules; they pass afterwards (22 checks).
- All seven `iteration-implementation/scripts/test_*.sh` suites pass, including routing, final artifact, publication, source checkout, task generation, and acceptance feature guards.
- Full gate command for the staged candidate: `MEMBA_POSTGRES_PORT=15439 ACCEPTANCE_SERVER_NODE=memba_acceptance_server@localhost ./bin/dev check`. Its final exit/result is recorded in the fix commit message; local output is retained at `/tmp/memba-kaizen-060-dev-check.log`. A successful final exit is required before committing the fix.
- Prompt-contract tests prove the instructions and graph guarantees are present; they cannot prove agent adherence. A future delivery run is the operational experiment.

Remaining follow-up — this note is not fully resolved:

- Existing plans may explicitly require a final full-validation task (iteration 060 task 010 did). That obligation is preserved, not silently deleted or checked off. Moving it into the deterministic gate needs an explicit ownership/completion handoff; this fix does not yet eliminate that duplication or its command-timeout risk.
- Investigate suite runtime separately: browser acceptance took 7m25s in the failed run, before adding setup and ExUnit costs. Profile setup, per-scenario work, and teardown rather than assuming all that time is unavoidable or cutting coverage.
- The post-teardown timer mechanism is now covered by the red/green regression below. Remaining runtime work concerns active suite cost and resource pressure, not that cleared timer.
- Add a timeout-specific deterministic handoff/terminal diagnostic if subsequent runs still require log archaeology. The prompt now asks for useful evidence when it can stop deliberately, but a hard cancellation can still prevent that response.

### Further runtime evidence: post-teardown wait

The same run provides successful standalone browser commands for comparison. `/tmp/fabro-dump-060/events.jsonl` records:

| Event sequence | Stage | Command duration | AfterAll stopped | Command returned | Residual wait |
| --- | --- | --- | --- | --- | --- |
| 1549 | `implement_next_task@5` | 507.579s | 11:24:40.110Z | 11:25:40.329Z | 60.219s |
| 1897 | `implement_next_task@6` | 508.358s | 11:50:13.035Z | 11:51:13.174Z | 60.139s |
| 2288 | `implement_next_task@7` | 508.256s | 12:16:10.235Z | 12:17:10.384Z | 60.149s |
| 3273 | `implement_next_task@9` | 602.132s (timeout) | 13:01:41.564Z | 13:02:31.714Z (killed) | 50.150s |

`bin/dev` runs setup, precommit, then acceptance, with no subsequent typecheck or contract-test phase to explain the residual wait. In event 3273 ExUnit reports 98.7s, while browser setup/scenario/teardown activity accounts for about 445s. There is useful work to profile within that active browser time, but the repeated post-teardown minute is a more specific first target than broadly rewriting slow scenarios.

Code inspection found `startManagedProcess().stop()` in `acceptance-tests/features/support/lifecycle.js` races process exit against the configured shutdown timeout (60 seconds by default). When process exit wins, the losing timer is not cancelled. A referenced Node timer can keep the caller alive even though the shutdown promise has resolved. This is a concrete resource-lifetime defect and a strong explanation of the repeated minute; it should be proved with a regression before calling the original full gate recovered.

### Local validation anomaly while applying this fix

The first local full gate, on workflow-only changes, exited 2 after 731s: ExUnit took 602.8s and reported 1,210 tests with one failure in `system_groups_replay_parity_test.exs:43` (Club projection checkpoint 24 versus required 33). Logs contain SQL sandbox connection-queue timeouts. Browser acceptance did not run. Evidence: `/tmp/memba-kaizen-060-dev-check.log` before the final retry (preserved as `/tmp/memba-kaizen-060-dev-check-first.log`).

The named test passed unchanged with the same seed (`348183`) in 3.9s using `MEMBA_POSTGRES_PORT=15439 ./bin/dev test test/memba/membership/system_groups_replay_parity_test.exs --seed 348183 --trace`; output is in `/tmp/memba-kaizen-060-replay-test.log`. A subsequent host snapshot showed load averages 41.20 / 60.96 / 53.77. That supports investigating resource pressure but does not establish the cause of the test failure. No test assertion, timeout, or application code was weakened to make it pass.

### Confirmed code-path fix: managed-process shutdown timer

Focused lifecycle regression now proves the post-teardown timer mechanism. `acceptance-tests/features/support/lifecycle.js` exports `startManagedProcess` for direct process tests. `acceptance-tests/test/lifecycle.test.js` starts a real managed Node subprocess, waits for its readiness log, calls `stop()` with the production 60s shutdown timeout, and wraps the parent script in a 5s external timeout. Before the fix, the child exited and `stop()` resolved (`managed stopped` was printed), but the parent Node process stayed alive until the losing 60s timer; the regression failed after 5s. After the fix, the same test exits in under a second.

The implementation keeps the existing shutdown semantics: send SIGTERM, wait the configured shutdown timeout, escalate to SIGKILL only if the timeout wins, then await actual exit. The only ownership change is to store the shutdown timer and `clearTimeout` it in a `finally` around the `Promise.race`, matching the existing `runCommand` timeout-cleanup pattern. A companion real-process test verifies a SIGTERM-ignoring child is still SIGKILLed after the configured wait.

Validation evidence:

- Red before code fix: `node --test test/lifecycle.test.js` failed `managed process stop clears graceful shutdown timeout after the child exits` after 5,000ms while stdout already contained `managed stopped`; 8/9 lifecycle tests passed.
- Green after code fix: `node --test test/lifecycle.test.js` passed 9/9.
- Broader fast Node config suite: `npm run test:config` passed 61/61.

The next full gate exited 1 after 1,165s. ExUnit passed all 1,210 tests (194.5s); browser acceptance passed 133/134 scenarios (948 passed steps, one failed, two skipped). The failure was the last-Admin removal UI scenario expecting `#flash-error`, not shutdown. Evidence is preserved in `/tmp/memba-kaizen-060-dev-check-second.log` and `.status`.

Even on that failed run, the lifecycle fix's integration effect was visible: `AfterAll` stopped at `19:19:35.113Z`, the log finished at `19:19:35.215Z`, and the wrapper wrote its final exit status at `19:19:36.406Z`. The formerly consistent 60-second post-teardown wait was absent. This does not make the failing suite green or prove that the suite now fits Fabro's ten-minute agent-shell ceiling.

### Supporting acceptance-helper repair: wait before Remove

The failed browser scenario was `Pat cannot remove Robin while Robin is the only Admin` (`club_membership_administration.feature:56`). The Remove click returned but `#flash-error` was absent. `removeMemberAsStaff` in `acceptance-tests/features/support/membership_administration.js` waited only for the visible server-rendered `#club-show` before clicking a `phx-click` button. Visibility does not establish that LiveView's client connection is ready.

A focused Node regression in `acceptance-tests/test/membership_administration.test.js` models the page as initially disconnected and rejects a click before the connection wait. It failed before the change, then passed after the helper began calling the existing `waitForLiveViewConnected` before Remove. This proves the missing synchronization in the helper; the original run did not capture connection state, so it is not proof of that run's precise socket timing.

The named browser scenario then passed (one scenario, seven steps) with the same database/node settings. No application code, Gherkin, business assertion, or timeout was changed. This bounded helper repair follows the existing LiveView-readiness convention rather than rerunning a known unsynchronized click or extending assertion timeouts.

### Additional observation: 2026-09-14 — iteration 062 stopped after 23 of 25 tasks

#### Context and workflow step

Iteration 062, Create custom groups (`docs/iterations/062-create-custom-groups/plan.md`), was progressing through implementation toward acceptance testing and publication. Matt supplied this status when requesting the note:

> 062: progressed through 23 of 25 tasks, including the difficult email-access fixes. The latest run then hit a 40-minute timeout. Two acceptance-testing tasks remain; it is not merged.

This is reported run evidence, not an independent inspection of its logs. The run ID, active node/task, and checkpoint were not supplied. The remaining tasks do not establish which task was active when the timeout fired.

#### Expected standard

The workflow should complete acceptance testing and the required quality gates before merging. If a time budget prevents completion, it should preserve completed and pending work separately and provide a clear, safe recovery handoff rather than leave a nearly finished iteration stopped without an obvious next step.

The current standard in `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md` requires focused per-task checks, awareness of the 600-second command and 2,400-second node budgets, and blocker/recovery evidence when validation cannot finish. Explicit final-validation tasks still require successful validation; progress counts are not a substitute.

#### Actual abnormality and impact

The latest run stopped at a reported 40-minute timeout after progress through 23 of 25 tasks, including the difficult email-access fixes. Two acceptance-testing tasks remain and the iteration is not merged. Delivery is blocked pending recovery and completion of acceptance testing. There is no evidence here that completed work was lost, that the 23 tasks were independently accepted, or that a product assertion failed.

This repeats the late-delivery timeout symptom recorded above. It does not establish that the earlier full-suite duplication, child-agent waits, or teardown defect caused this run's failure.

#### What allowed it to happen — suspected system weakness

The suspected weakness is the boundary between bounded task execution and recovery: useful progress can still end in a hard stop before acceptance work finishes, while a prompt-level instruction to report a blocker cannot guarantee a handoff after cancellation.

Local inspection at `7b7ee1b85` confirms that `implement_next_task` still has a 2,400-second timeout. Its failure edge now leads to `task_stopped`, whose static message asks the operator to inspect the preceding stage and latest verdict; it does not itself produce a timeout-specific task/checkpoint handoff. The earlier `task_not_ready` wording in this note is historical, not the current graph. The failed run's workflow revision and actual terminal output remain unverified.

The observation warrants checking whether acceptance work fits the execution budget and whether stopping preserves enough evidence to resume safely. It does not justify concluding that 25 tasks exceeded a run limit or that the timeout should simply be raised.

#### Relationship to the recent failure-handling fix

The [2026-09-13 task-verdict fix](2026-09-13-task-retry-verdict-terminates-iteration.md#resolution) separates a completed review requesting revision from failure to execute a node. Its strict `accept / revise / blocked` verdict and deterministic application step keep repairable candidates pending, route them through bounded in-place revision, and check off only accepted tasks. Execution failures still stop deliberately; automatic timeout recovery was not part of that fix.

The earlier focused-validation and single-owner changes in this note reduce avoidable work inside the deadline. They do not guarantee completion or a handoff after hard cancellation. Iteration 062 therefore adds evidence of the remaining timeout symptom, not proof that the new revision routing regressed. Confirm the run's workflow revision and failing node before attributing it to either mechanism; old run branches may retain the earlier workflow and check-off rules.

#### Open questions

- Which run, workflow revision, node, and selected task timed out, and what command or activity consumed the budget?
- Which checkpoint preserves the 23 tasks, what independent acceptance evidence exists, and what partial work remains for the two unchecked tasks?
- Did the run provide a usable recovery handoff, and did it follow the current focused-validation and budget rules?

#### Possible prevention ideas

- Make timeout handoff deterministic: record the active task, last command/result, accepted versus pending work, checkpoint, and supported recovery path even when the agent cannot return a summary.
- Check acceptance-task scope and expected command duration against the available budget before execution; preserve all required tests and final quality gates.

## Iteration 062 investigation and partial resolution: focused browser selection

Date: 2026-09-14

### Verified run and failure boundary

The reported run is `01M2F8XHWAHNSG7M6S0MXC3WA5`. Its source was recovery checkpoint `b44cc1c2b1e3d5c3a9271c8d37302f6a42bbb4e8`; the implementation workflow directory at that commit is identical to the task-verdict fix in `ced78e9ca`. This was not an old-workflow rollout failure.

The run accepted tasks 019–023 through `validate_task` and `apply_task_verdict`. Task 024 remained pending. Its sixth `implement_next_task` visit began at 07:54:07.823 UTC and failed at 08:34:07.956 with `handler timed out after 2400000ms`. No task-024 review or acceptance followed. The failure edge went to `task_stopped`, not the old retry-bypassing `task_not_ready` route. There was no node-visit-limit failure.

The failed candidate checkpoint `f8e5a6407b8301632ed7cfb75f5e33cd73412066` preserves eight changed/new acceptance files (1,725 additions), without checking off task 024. Final checkpoint `72c2a652b678ccf59c944bc94cf62724ac0e4c29` preserves 23 checked and two unchecked tasks:

- 024: custom-group conversation scenarios at both domain and browser layers.
- 025: custom-group lifecycle scenarios at both layers, then exact-state `dev check`.

A separate recovery run, `01M2G3K7JZ4VTQFH9W99AVPBRS`, had already been launched by another session. This investigation did not launch, steer, stop, or modify it. The failure status above describes the captured run, not that recovery's eventual outcome.

### Where the time went

- The task combined two acceptance layers. Domain coverage reached 14 tests passing by 08:04:31, about ten minutes into the node.
- Three browser commands supplied `features/custom_group_conversations.feature` and iteration-062 tags, but each ran 30 scenarios rather than the requested file's 13. They took 250.119, 258.027 and 252.652 seconds: about 12m41s total, including both necessary scenario work and unrelated creation scenarios. This is not a measurement of time saved by narrowing them.
- The browser runs exposed real unfinished acceptance plumbing: an unexported helper, undefined message context, and email assertions. This was not an otherwise green task merely awaiting check-off. The agent repaired some issues but did not establish final passing browser evidence.
- After context compaction at 08:12–08:13, the parent spawned browser and domain reviewers at 08:22:52 and 08:22:55, despite its loaded prompt forbidding subagents and duplicate independent review. Compaction preceded the violation; the evidence does not prove it erased or caused disregard of that instruction.
- Parent and children then ran tests against the shared sandbox. Parent commands bypassed the `bin/dev` quality-gate lock through direct `acceptance-test` calls, while children invoked `dev test` and `dev acceptance`. Logs show overlapping command intervals and subsequent database-in-use, connection and server-readiness errors. The exact process holding each failed database operation is not established.
- At 08:29:58.742 the parent called `wait` for reviewer `74fd6fe5`. It never received completion before cancellation about 4m09s later. Both child reviews lacked a completion event before the outer timeout.

No full `dev check` was run by the task-024 parent. The previous full-suite-duplication diagnosis must not be copied onto this run: the demonstrated widening happened inside supposedly focused browser commands.

### Cause analysis: occurrence and escape

| Boundary | Evidence-supported mechanism |
| --- | --- |
| Why did task 024 stop before review? | Its composite implementation handler exhausted its 40-minute budget, with an outstanding child-review wait. |
| Why was focused browser feedback broader than requested? | `acceptance-tests/cucumber.js` configured `paths: ["features/**/*.feature"]`. Installed Cucumber merges configuration paths with CLI paths; a positional filename adds to the suite glob rather than replacing it. Its warning and the 30-scenario output confirm this in the failed run. |
| Why did the selection defect escape tests? | Existing configuration tests asserted that the explicit suite glob was present and enumerated tags. They did not exercise Cucumber's actual configuration/source resolution with a requested file or line. The focused-validation prompt therefore relied on an untested command contract. |
| Why could duplicate review consume the deadline? | Single-owner execution was a prompt rule, not an enforced capability boundary. Fabro still exposed `spawn_agent` and `wait`; native subagents have no default turn limit. No deterministic reserve stopped the parent from waiting across its deadline. |
| Why was recovery still manual? | The new verdict contract safely keeps unaccepted work pending, but deliberately treats execution failure as terminal. `task_stopped` points to earlier logs rather than creating a timeout-specific handoff or bounded continuation. |

The smallest proven tooling defect addressed here is path widening. It contributed waste but is not established as the sole or sufficient cause of the timeout. Extra review, shared-environment interference, and the size of the dual-layer task remain separate contributors or follow-up questions.

### Countermeasure applied

Remove the explicit default `paths` setting and use Cucumber's native no-argument feature discovery. Explicit paths then select only the requested files/lines; ordinary `dev check` still runs the default suite. No feature tags, scenarios, assertions, timeouts, retry bounds, or publication gates change.

Files:

- `acceptance-tests/cucumber.js`: removes the glob that broadened explicit selections.
- `acceptance-tests/test/cucumber_selection.test.js`: exercises the installed Cucumber configuration and source APIs for one file, multiple files, one file/line, and no-argument full-suite equivalence.
- `acceptance-tests/test/cucumber_config.test.js`: removes assertions requiring the faulty raw setting; retains tag and feature-inventory coverage.

Prediction: a file-targeted acceptance invocation will no longer spend time on other features, while no-argument delivery validation retains the same scenario inventory. This is occurrence prevention for selection widening, not automatic recovery or proof that future 40-minute nodes will finish.

### Validation and evidence

- New native Cucumber selection tests before the fix: three focused-selection cases failed; full-suite equivalence passed.
- After the fix: selection and existing configuration tests passed, 14/14.
- Compared actual default source plans before and after the configuration change: identical 145 scenario instances. This is source-selection evidence, not a claim that browser execution passed.
- Existing isolated Fabro runtime regressions passed 7/7 before the change. They establish verdict routing and fail-closed behaviour, not hard-timeout recovery or agent adherence.
- First staged full `dev check`: exit 1 after 1,100 seconds. All 1,292 unit tests passed; browser acceptance had 141/145 passing scenarios. The config suite passed 71/71. Logs: `/tmp/memba-062-dev-check.log` and `/tmp/memba-062-config-suite.log`.
- File/line-targeted rerun selected exactly the four failed scenarios: three passed unchanged, while the Admin-group keyboard-tab failure reproduced. The other failures were two email-address interaction timeouts and `ERR_NETWORK_CHANGED`; their causes are not claimed fixed.
- A baseline with the original Cucumber config also reproduced the tab failure. Passive instrumentation proved that ArrowRight arrived before the tab hook installed its handler. The small supporting readiness repair and its red/green evidence are recorded in [Acceptance inputs raced LiveView root join](2026-09-12-acceptance-inputs-race-liveview-join.md#additional-observation-and-repair-2026-09-14--group-tab-keyboard-input).
- Full `dev check` is required on the final staged candidate before committing. Its final result and final Node suite counts are recorded in the fix commit message; logs are retained separately at `/tmp/memba-062-dev-check-final.log` and `/tmp/memba-062-config-suite-final.log`.

Run evidence is retained in `/tmp/memba-kaizen-062-failed-run/` (`events.jsonl`, `graph.fabro`, stage artifacts and run log). Important event sequences: 3761 (node start), 4129 (domain green), 4166/4197/4239 (broadened browser results), 4244/4254 (child spawns), 4854 (database-in-use failure), 5028 (parent wait), 5113 (timeout), 5123 (terminal fallback). Durable references are `origin/fabro/run/01M2F8XHWAHNSG7M6S0MXC3WA5` and its matching `origin/fabro/meta/` branch, especially `stages/040-implement_next_task@6/`.

### Remaining resolution options — decision pending

1. Enforce single-owner implementation/revision nodes in tool configuration rather than adding another prose reminder. This targets duplicate waits and shared-sandbox concurrency, but available per-node controls in deployed Fabro need verification; its ordinary permission levels always permit subagents.
2. Add a deterministic timeout handoff while retaining terminal failure. This makes preserved candidate work easier to recover safely, but does not make unattended delivery continue.
3. Add bounded timeout continuation for the same pending candidate, with independent acceptance and final gates retained. This could recover productive interrupted work, but can also repeat a stuck approach, spend more, or encounter surviving child/process state. It requires an explicit budget and cleanup policy, not an unconditional retry edge.

Recommendation: retain the narrow selection fix; decide whether the next improvement should prevent forbidden delegation or make hard-timeout recovery explicit before changing execution policy. Review the next file-targeted Fabro invocation for the requested scenario inventory and absence of the path-merge warning. A later real timeout is the effectiveness check for whichever recovery policy is chosen. These follow-ups remain open; the kaizen note is not fully resolved.

### Resolution interview: investigate lost instructions before enforcing delegation policy

Date: 2026-09-14

Matt asked why the implementor sought extra reviewers before agreeing to enforcement: a fence should not substitute for understanding the behaviour. No delegation or timeout-policy change was selected.

The immediate purpose is visible in the child requests: after browser validation still reported five failures, the parent requested concrete browser-helper diagnosis and a separate domain correctness review. Both requests prohibited edits, but neither prohibited running tests. No explanatory message accompanied the spawn calls, so the model's reason for departing from the single-owner rule is not directly recorded.

Source investigation found a concrete instruction-preservation weakness:

- Event 3768 contains one user input of 85,959 UTF-8 bytes: 77,699 bytes of workflow preamble followed by 8,260 bytes of current node instructions, including the no-subagent and no-extra-review rules.
- The run records server and client version `0.316.0-nightly.0`. Source was inspected at release commit `0abf2297c00a90013a93ae01c6c139b7b85b1b1f`; matching version supports correspondence, but the deployed server's exact commit/modification state is not proven.
- At that revision, `lib/components/fabro-agent/src/history.rs`, `compact_from` and `extract_recent_user_messages`, reinsert whole discarded user messages only within an 80,000-byte budget. An oversized message causes the extraction loop to stop. It is excluded wholesale, not truncated from the end.
- Event 4191 records 85 original turns and six preserved recent turns. Under that implementation, the oversized initial request cannot survive verbatim after compaction. The essential node instructions fit comfortably on their own; combining them with historical stage output puts the whole message above the preservation limit.
- `lib/components/fabro-agent/src/compaction.rs` gives the summarizer the original user text without truncation and asks it to retain constraints. But the resulting summary is lossy; only file operations receive an explicit verbatim-copy requirement. The actual summary text is not present in the exported events/checkpoints, so omission or weakening of the no-delegation rules cannot be verified directly.
- The workflow passes the node prompt as ordinary `Message::User` content, not persistent session `user_instructions`. Delegation tools and their encouragement to use independent work/context isolation remain available in subsequent requests. The native OpenAI static system template at this revision does not itself contain explicit pro-delegation guidance; do not attribute Anthropic's delegation instructions to this run.

Updated causal hypothesis: after encountering unresolved failures, the implementor sought available diagnostic help, while compaction had removed its original workflow contract from verbatim history and left constraint preservation to a summary. This explains a mechanism for the departure, not proof of the unseen summary's contents or the model's internal reason.

Updated recommendation: investigate keeping the current node's execution rules separate from bulky historical context and preserving them across compaction before choosing tool prohibition as the main countermeasure. Enforcement could still be a backstop. A regression should cover the actual oversized-preamble/short-node-instruction boundary; merely making this one message smaller or raising the budget would not establish durable instruction preservation. Exact postcompaction context capture would also make future violations diagnosable. Decision remains pending.

### Further investigation: task sizing and context preparation belong outside the worker

Date: 2026-09-14

Matt rejected treating agent compaction as normal operation. The intended standard is a small, defined task with reasonably sized context prepared outside the individual node. Investigation therefore moved upstream; no compaction, delegation-enforcement or timeout-continuation change was selected or implemented.

#### Task formation

Planning established iteration-level scope, not execution-sized tasks. Plan step 6 combined all tagged acceptance scenarios, several targeted test matrices and the final gate. The initial task generator turned that into task 021 (`8f607b51b`).

Implementation nodes then performed semantic decomposition while also doing their own work:

- `91b1b5b9f` split task 021 into targeted tests plus a remaining all-acceptance task.
- `45d661b5a` split that acceptance task into creation/domain (022), creation/browser (023), conversations/both layers (024), and lifecycle/both layers plus final gate (025).
- The validator accepted the current completed slice and preservation of future scope. The recorded rationale did not establish that every newly added future task fitted a bounded node.

The active `scripts/sync_task_list.py` checks text length and punctuation, not execution workload: it splits long prose at sentence boundaries, rejects generated task text over 360 characters, and returns immediately for an existing todo file. The richer `prompts/sync_task_list.md` asks for semantic one-node sizing, but the graph does not invoke it. Implementors own further splitting; reviewers assess smallness after candidate implementation. No dedicated pre-execution semantic sizing check was found.

Task 024's 1,725-line candidate stayed within its assigned acceptance scope. It covered 13 conversation instances across domain and browser infrastructure, including inbound email, recipient delivery, access and follow state. For comparison, successful task 022 added 593 lines for 13 domain creation examples; task 023 added 1,042 lines for 17 browser creation examples. This is evidence of differing dependency/work surfaces, not a rule that scenario or line counts predict duration. The split rationale did not explain why only creation was separated by layer.

#### Incoming context is mechanically rendered, not curated

The workflow uses `summary:high`. At the inspected Fabro release source, this is formatting logic, not an LLM-generated summary: `lib/components/fabro-workflow/src/handler/llm/preamble.rs` renders command scripts, up to 50 trailing output lines, full agent final responses and filtered context.

There is a concrete loop-history mismatch. `lib/foundation/fabro-core/src/state.rs::ExecutionState::record` appends every completed node ID but overwrites that ID's stored outcome. `build_summary_preamble` iterates the historical IDs and looks up the latest outcome each time. The task-024 input confirms the effect: five byte-identical copies of task 023's implementation response, five copies of its review, five copies of its applied verdict, and six copies of the latest todo-sync output. These are repeated latest values, not distinct historical evidence.

Each implementation visit started a fresh API session (`summary:high`, no full-fidelity reuse), yet its incoming message grew with the loop:

| Selected task | Incoming message, UTF-8 bytes | First model-input tokens | Peak recorded model-input tokens | Compactions |
| --- | ---: | ---: | ---: | ---: |
| 019 | 26,951 | 10,888 | 149,872 | 0 |
| 020 | 38,455 | 13,372 | 126,007 | 0 |
| 021 | 46,122 | 15,469 | 148,729 | 0 |
| 022 | 60,152 | 18,671 | 147,111 | 0 |
| 023 | 72,650 | 21,683 | 158,872 | 0 |
| 024 | 85,959 | 24,668 | 217,291 | 1 |

The current implementation prompt was unchanged at 8,260 bytes; the preamble accounted for the incoming growth. Matching source/version and observed duplicate sections support the mechanism; exact deployed source identity remains unverified.

#### Most growth happened inside the node, before editing

Task 024 reached 160,566 recorded input tokens before its first edit, less than five minutes after starting. Seventy-one tool results had emitted about 845 KB, mostly broad source and documentation inspection. By domain tests passing, input context was about 200,000 tokens; browser dry-run completion brought it to about 209,000. Compaction followed the first real browser run at roughly 218,000 estimated tokens.

Logged tool-output bytes are not a direct measure of what the provider retained; the model-input token figures come from recorded response usage. Together they show that trimming incoming history alone would not address the dominant within-node growth. The generic worker prompt requires plan/todo/history/ADR discovery; no task-specific curated dependency packet was identified in the inspected handoff. Whether reusable task-local knowledge already existed elsewhere in the sandbox remains open.

#### Current understanding and unanswered questions

The observed system assigns semantic decomposition, dependency discovery, implementation and validation to the same bounded worker, while delivering mechanically accumulated history as its starting context. Successful nodes also accumulated large contexts. Compaction was where this weakness became visible in task 024, not necessarily where it began.

Before selecting a countermeasure, distinguish necessary domain/acceptance knowledge from avoidable rediscovery: which of task 024's reads were needed, which repeated known facts, and which existing helpers could have made the work smaller? Also establish what evidence should make a task ready for a worker and how the workflow currently communicates that evidence. No safe numerical task/context limit or replacement architecture has been established by this investigation.

Evidence: failed-run events and meta artifacts; task-split commits above; current/run-revision task generation and validation contracts; release-source functions above. Derived measurements are retained at `/tmp/memba-062-context-metrics.json` and `/tmp/memba-062-context-output-categories.json`.

### Bounded preparation exercise: one rule at one layer

Matt agreed to work through one concrete case before choosing a new workflow. The [task-024 preparation exercise](experiments/062-task-024/README.md) and [sample worker handoff](experiments/062-task-024/worker-handoff.md) use the pre-attempt checkpoint `3ec928f3e`.

The packet covers only Board web composition at the domain layer: one existing scenario with its full positive/negative audience assertions. An external coverage ledger retains the other twelve domain scenarios and all thirteen browser scenarios, plus the separate lifecycle/final-gate obligations. This is not a live todo split or a proposal that every scenario must be its own node.

Preparation identified existing fixture, send, access, provider-observation and runner code; it supplied context shapes and highlighted private-helper and wording adaptations. This separates real integration work from the broad subsystem discovery that the original worker performed. No implementation was attempted. A temporary tag-only selection check confirmed that the proposed scope can enable exactly one domain scenario without enabling browser coverage or changing scenario text.

The artifacts are for the next design conversation. They do not prove a worker can finish within a particular token/time budget, and no new workflow architecture has been selected.

### Resolution selected: just-in-time delivery planner

Matt subsequently approved a capable delivery planner that can split, combine and reorder pending implementation work, prepare one bounded handoff against current code, and incorporate worker notes and existing review results. It may change the execution plan, not the approved scope or acceptance contract. Workers return early when missing preparation or excessive scope requires replanning; incomplete work remains unaccepted.

Matt explicitly rejected a separate readiness-review loop. The existing independent implementation review and final gates remain. Use Sol for the initial planner; no new compaction policy, tool-capability fence or hard-timeout retry policy is selected.

The approved [implementation design](2026-09-14-just-in-time-delivery-planner.md) records responsibilities, durable artifacts, code targets and validation requirements. Matt requested that this be written up and dispatched to a Sol implementation subagent. Status: authorized for implementation, not yet validated; operational effectiveness remains to be demonstrated by a later authorized delivery.

### Follow-up implementation: 2026-09-14 — just-in-time delivery planner

Implemented the approved delivery-planner loop on branch `kaizen/delivery-planner` in an isolated worktree. The task loop now routes through a Sol delivery planner before every worker packet, records durable `.delivery/` artifacts beside each iteration plan, and sends worker `ready_for_review`, `replan`, and `human_blocked` outcomes through deterministic routing. Workers no longer choose, split or reorder tasks; semantic sizing belongs to the planner. Existing independent review, deterministic check-off, bounded revision worker visits, final `dev ci`, plan-conformance, final artifact and publish gates remain in place.

Validation added/updated deterministic helper tests and native Fabro runtime fixtures for initial/existing/resumed state, artifact provenance, worker replan without acceptance, revision through planner with the existing visit guard, fail-closed malformed/stale/mismatched artifacts, artifact-only checkpoint tolerance, and minimal task-loop fidelity. Full effectiveness remains pending until a later authorized real delivery run demonstrates useful early replanning and bounded worker context in practice.

### Follow-up correction: 2026-09-14 — deterministic planner guard tightened

Implementation review of the first delivery-planner commit found reproduced invalid success routes in the planner helper: forged task check-off, deletion of pending work, incomplete packets, tampered guard baselines, and implementation routing after a revise verdict. The correction keeps the same approved planner/worker/review architecture but moves guard authority out of planner-writable artifacts, restricts planner writes to declared outputs, validates full state/packet/result schemas, requires pending-obligation lineage and coverage mapping, preserves unaccepted candidate origins through replan/revision/resume, and makes planner human-blocked output explicit. Effectiveness in a real delivery remains pending.
