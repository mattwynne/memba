# Problem: task validator requested a retry, but the workflow terminated

Date: 2026-09-13

## Context

Matt asked for iterations 061–067 to run through Fabro overnight. Iteration 061, [Discover club groups](../iterations/061-discover-club-groups/plan.md), stopped during `validate_task@9` in implementation run [01M2CTJGX0AY2HQJWXMNQTM102](https://fabro.home.wynne.family/runs/01M2CTJGX0AY2HQJWXMNQTM102).

The observation is not that the proposed application had a bug. It is that actionable implementation feedback ended the workflow instead of returning it to the goal of implementing the approved behaviour.

## Expected standard

The [task-validation prompt](../../.fabro/workflows/iteration-implementation/prompts/validate_task.md) says to request a retry when a rejected task remains clear and safe to attempt. Human input is reserved for ambiguity, unsafe work, repeated non-transient failure, or a decision/tooling blocker.

The [workflow graph](../../.fabro/workflows/iteration-implementation/workflow.fabro) has a retry route through `task_gate` and `reset_task_attempt`. Rejected work must not pass validation or reach publication, but rejection alone should not abandon a repairable iteration. Retries should remain bounded and preserve previously validated work.

## What happened

The implementor checked off task 009, which covers permission changes in already-open LiveViews. The independent validator found incomplete coverage: the dashboard and compose submission reauthorized, but open conversation, delivery-detail and compose displays could retain restricted content or metadata after access loss.

The validator explicitly requested another attempt. Its recorded response included:

- `decision: RETRY`
- `preferred_next_label: retry`
- `context_updates: {task_valid: false, task_retry_available: true}`
- `outcome: failed`
- `suggested_next_ids: [implement_next_task]`

At `2026-09-13T09:14:13Z` (02:14 PDT), Fabro recorded `validate_task` as failed with `will_retry=false`. The next edge was `validate_task -> task_not_ready`, labelled `Validation/provider failure`. The event retained the preferred label `retry`, but selected the unconditional failure edge. The task never reached `task_gate`, where `task_retry_available` could select the retry route.

The terminal node then said:

> Iteration implementation failed: task validation requires human input or exceeded retry budget.

The final workflow error was:

> goal gate unsatisfied for node publish_to_main and no retry target

Neither message explains that the validator had requested a retry. These events establish a routing failure; they do not establish an exhausted retry budget or a need for a business decision.

## Impact

Iteration 061 was not published, and sequential delivery of 062–067 did not start. By the morning update, all remaining plans were validated but none of the seven iterations had been delivered. The publication gate protected main; there is no evidence here of a production incident.

Recovery required inspecting logs, finding the durable run branch, reopening the rejected task, and launching another guarded implementation run. The failed checkpoint still had task 009 checked off, so simply continuing with the next unchecked task could have skipped the rejected work.

## What allowed it to happen

**Confirmed mechanism:** only `outcome=succeeded` reaches `task_gate`. The validator combined an ordinary negative task verdict with a failed node outcome. That bypassed the retry decision, despite `task_retry_available=true`.

**Suspected system weakness:** the boundary between “validation successfully found incomplete work” and “the validation machinery could not execute” is not enforced consistently across the prompt, structured response and graph. A recoverable product finding can therefore take the same terminal path as a provider failure. The generic human-input/budget message further obscures that mismatch.

## Observations and evidence

- The validator provided concrete missing behaviours and requested `RETRY`, not `HUMAN_INPUT`.
- The actual run graph contains the success-only edge to `task_gate` and the unconditional failure edge described above.
- Local evidence: `.fabro/tmp/overnight-061-067-20260913-000001/`, especially `events-061-failed-tail.txt`, `logs-061-failed-500.txt`, `inspect-061-implementation-recovery.json` and `status.md`.
- The failed run branch preserved checkpoint work at `233d181845f00de689737d6041419f4de748dd96`. Recovery reopened task 009 in `f1ab7c4101f66ab27db7e3953d9eb5818631ad4a` and launched run `01M2DRQG6MC40SWT7ZFK58QT5W`. This is a workaround, not a workflow fix.
- Related but distinct observations: [reset-cycle exhaustion](2026-05-30-iteration-implementation-reset-cycle-limit.md) reached the retry loop; [task-list misclassification](2026-06-18-implementation-task-list-check-routes-unchecked-tasks-to-human-failure.md) stopped before implementation. This run bypassed retry after a substantive validator finding.

## Why this matters

Independent validation should guide further work toward the iteration goal. If its useful negative verdict becomes terminal failure, unattended delivery depends on an external operator interpreting evidence and reconstructing the intended continuation.

## Open questions

- Which prompt/schema/runtime contract allowed `RETRY` and `outcome=failed` to coexist without a safe, explicit interpretation?
- Does the existing retry/reset path correctly reopen tasks already stored in Fabro checkpoints, rather than resetting to an equally incomplete checked-off HEAD?
- What evidence should justify escalation instead of another attempt, and how should that reason survive into the terminal report?

## Possible prevention ideas

- Distinguish a completed validation verdict from validator execution failure at the routing boundary; test a recoverable negative verdict end to end.
- Make retry state include the rejected task and checkpoint, so continuation cannot silently skip it.
- Report the original verdict and actual stop reason while retaining bounded retries and all publication gates.
