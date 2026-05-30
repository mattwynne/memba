# Problem: iteration implementation hit reset-task retry cycle limit

Date: 2026-05-30

## Selected iteration

Iteration 005: Browser acceptance harness for member-facing behaviour

Plan path: `docs/iterations/005-browser-acceptance-harness/plan.md`

## Fabro run

Run ID: `01KSVP69ES02ATWQ9S3E9MGJAD`

Web UI: `https://fabro.home.wynne.family/runs/01KSVP69ES02ATWQ9S3E9MGJAD`

Run branch: `origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD`

## Failed stage/status

The run failed after all but the final task had been checked off. The latest run branch shows:

```text
- [x] 001 Use TDD with PhoenixTest as the preferred high-level LiveView test API. Start by writing failing PhoenixTest coverage for the real route flows listed in the acceptance criteria.
- [x] 002 Add browser routes under the existing browser pipeline:
- [x] 003 Add `POST /webhooks/postmark` under an appropriate non-browser pipeline for webhook requests.
- [x] 004 Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:
- [x] 005 Build `MembaWeb.ClubsLive.Index`, `MembaWeb.ClubsLive.Show`, and `MembaWeb.MessagesLive.Show` with simple forms/actions for club creation, person creation, membership, club message sending, and receipt viewing.
- [x] 006 Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.
- [x] 007 Give important forms, controls, rows, and status displays stable IDs and `aria-label`s suitable for Playwright/PhoenixTest.
- [x] 008 Update Playwright/Cucumber step definitions to drive the real LiveView routes for `homepage.feature` and `member_message_deliverability.feature`; delivery/open report steps should make HTTP requests to `POST /webhooks/postmark`.
- [x] 009 Add `@todo-web` tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.
- [x] 010 Configure `acceptance-tests/cucumber.js` so the default browser Cucumber command uses `tags: "not @todo-web"`.
- [x] 011 Verify the Elixir/domain acceptance path used by `dev check` still runs every shared scenario regardless of `@todo-web` tags.
- [ ] 012 Run the browser acceptance suite and `dev check`, fixing any issues.
```

Exact terminal workflow failure text from `fabro logs 01KSVP69ES02ATWQ9S3E9MGJAD`:

```text
Workflow run failed node "reset_task_attempt" visited 3 times (node limit 3); run is stuck in a cycle reason=workflow_error category=deterministic
```

The immediately preceding routing was:

```text
Stage completed node_id="validate_task" stage="Validate Completed Task" ... status="succeeded"
Edge selected from_node="validate_task" to_node="task_gate"
Stage completed node_id="task_gate" stage="Task valid?" ... status="succeeded"
Edge selected from_node="task_gate" to_node="reset_task_attempt" label="Retry from last good checkpoint" reason="condition"
```

## Commands used to inspect

```bash
fabro inspect 01KSVP69ES02ATWQ9S3E9MGJAD --json
fabro logs 01KSVP69ES02ATWQ9S3E9MGJAD
fabro events 01KSVP69ES02ATWQ9S3E9MGJAD --json
git fetch origin fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD
git show origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD:docs/iterations/005-browser-acceptance-harness/todo.md
```

## Observations

- This is a workflow/tooling failure rather than a local implementation edit failure because the run terminated on Fabro's node visit limit for `reset_task_attempt`, not on a clear final implementation artifact, review, publish, or `dev check` failure summary.
- The workflow had enough durable state to checkpoint substantial implementation work to `origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD`.
- The task validation node completed successfully immediately before the task gate routed to another reset.
- The reset loop consumed the global node visit budget and ended the whole workflow before publishing to `main`, writing implementation handoff metadata, or reaching review.
- The failure message does not include the underlying task-validation reason that caused the final reset, so the operator has to inspect logs/events and the run branch manually.

## Safe retry/resume command

The safest resume path is to resume from the failed run branch, preserving checkpointed implementation work:

```bash
git fetch origin fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD
# in an isolated worktree or after coordinating local branch state:
git checkout -B resume/005-browser-acceptance-harness origin/fabro/run/01KSVP69ES02ATWQ9S3E9MGJAD
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/005-browser-acceptance-harness/plan.md
```

Before retrying, inspect the final unchecked task and current run-branch diff so the next run can focus on task 012 rather than redoing completed work.

## Follow-up plans

Split the recovery into focused notes rather than giving one agent a mixed salvage/review/planning task:

1. [Plan: salvage iteration 005 app slice](2026-05-30-salvage-005-app-slice.md)
2. [Plan: review salvaged iteration 005](2026-05-30-review-salvaged-005.md)
3. [Plan: carve out browser Cucumber automation iteration](2026-05-30-plan-browser-cucumber-automation.md)

The consistency/projection synchronization question belongs primarily in the salvage and browser-automation planning work. The failed run appears to have changed Messaging status-report APIs to use strong consistency by default after a test observed `delivered` instead of `opened`; that may be the wrong design default. Prefer test/harness synchronization on recorded events or projected read-model state unless strong consistency is an intentional production API contract.

## Workflow kaizen

1. Split final validation from implementation tasks. `Run browser acceptance suite and dev check` should be a workflow gate, not an ordinary todo item that an agent must mark complete.
2. Make reset budgets per task or much more explicit. A global `reset_task_attempt` visit limit can be exhausted by an earlier task, leaving a later integration task with too little retry budget.
3. When the task gate routes to reset, include the validation decision and retry brief in the terminal failure summary if the run later hits the reset limit.
4. Preserve discarded attempts as inspectable artifacts and print their paths in the final failure output.
5. Add a guardrail to prevent stale failed run branches from being merged wholesale into `main`; require path-scoped salvage when `origin/main..run-branch` includes unrelated workflow/planning changes.
