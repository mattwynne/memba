# Browser Cucumber automation for member-facing acceptance

Date: 2026-05-30
Status: implementing

## Goal

The shared member-facing acceptance scenarios run reliably through the Playwright/Cucumber browser harness against the real Phoenix routes and Postmark-style webhook endpoint, without changing the domain-level acceptance path.

## Background / Context

Iteration 005 plans the minimal browser substrate for member-facing behaviour: `/clubs`, `/clubs/:club_id`, `/messages/:message_id`, and `POST /webhooks/postmark`. A kaizen note on 2026-05-30 identified that the browser Cucumber automation work should be planned as its own focused iteration instead of being buried inside the app-surface slice.

The shared `.feature` files remain the acceptance source. The Elixir/domain Cucumber path proves the application behaviour directly, while the Playwright/Cucumber path proves that browser-visible flows can exercise the same member-facing behaviour through the running Phoenix app.

Iteration 007 separately plans the operator deliveries overview. This iteration does not implement the operator browser slice; it preserves the `@todo-web` partition so operator scenarios can remain domain-tested until their browser surface is implemented.

Prerequisite: the iteration 005 browser routes and webhook endpoint are available on `main` or on a stable implementation branch before this automation slice starts.

## Scope

### In scope

- Keep the shared feature files as the source of acceptance truth.
- Configure the browser Cucumber default command to exclude `@todo-web` scenarios.
- Preserve the Elixir/domain acceptance path so it remains unfiltered by `@todo-web` and continues to run all shared scenarios.
- Implement or complete Playwright/Cucumber JavaScript step definitions for:
  - `homepage.feature`;
  - every scenario in `member_message_deliverability.feature`.
- Drive the real Phoenix routes from the browser steps rather than using temporary test-only UI controls.
- For delivery/open status steps, POST Postmark-style events to `POST /webhooks/postmark` and assert the resulting browser-visible receipt state.
- Make the browser acceptance lifecycle reliable and diagnosable:
  - ensure Postgres is reachable before tests run;
  - run required database setup/migrations for the test environment;
  - start Phoenix for the browser suite;
  - wait for HTTP readiness before launching scenarios;
  - collect Phoenix/browser logs when failures occur;
  - tear down Phoenix, browser, and related processes cleanly.
- Add harness/test-level synchronization for eventually consistent projections, as described under Open Technical Decisions.

### Out of scope

- New product UI, routes, or domain behaviour beyond the already-planned iteration 005 browser substrate.
- Operator deliveries overview automation for `/deliveries`; iteration 007 remains the browser-backed operator slice.
- Real outbound email provider integration, webhook signature verification, retries, or provider hardening.
- Changing the acceptance language except for narrowly needed browser partition tags.
- Changing production read-model consistency semantics unless an explicit technical decision is made during implementation and documented in the code review.

## Acceptance Criteria

- `npm test` from `acceptance-tests/` runs the Playwright/Cucumber browser acceptance suite with a default tag expression equivalent to `not @todo-web`.
- `homepage.feature` passes through Playwright/Cucumber against the running Phoenix app.
- Every scenario in `member_message_deliverability.feature` passes through Playwright/Cucumber against the real routes and `POST /webhooks/postmark`.
- Browser status-change steps wait for the projected receipt/status UI to become observable instead of assuming the webhook response means all projections are already visible.
- `operator_email_deliverability.feature` remains excluded from the default browser run while its scenarios are tagged `@todo-web`.
- The Elixir/domain acceptance path used by `dev check` still runs all shared scenarios, including any tagged `@todo-web`.
- Browser acceptance failures clearly identify whether the failure is from database readiness, Phoenix startup/readiness, webhook submission, LiveView/projection timing, browser interaction, or an assertion mismatch.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Inspect the current `acceptance-tests/` Playwright/Cucumber setup and the shared feature files to identify existing step coverage and gaps.
2. Configure the browser Cucumber default command to exclude `@todo-web`, while leaving the Elixir/domain Cucumber runner unfiltered.
3. Build or refine the browser test lifecycle wrapper so it prepares the test database, starts Phoenix, waits for HTTP readiness, captures useful logs, and tears down reliably.
4. Implement homepage browser steps against the real homepage route.
5. Implement member-message browser steps by driving `/clubs`, `/clubs/:club_id`, and `/messages/:message_id` through accessible labels, roles, and stable identifiers supplied by the existing UI.
6. Implement webhook/status browser steps by sending Postmark-style HTTP requests to `POST /webhooks/postmark`.
7. Add bounded polling/waiting around browser-visible projections after commands and webhook posts. Prefer Playwright assertions such as `expect(...).toHaveText`, `expect.poll`, or equivalent Cucumber helper retries over fixed sleeps.
8. Make diagnostics actionable: separate errors for Phoenix readiness, database setup, webhook HTTP failures, timeout waiting for projected UI state, and final assertion mismatches.
9. Verify that `operator_email_deliverability.feature` is excluded only from the browser run and remains covered by the domain runner.
10. Run `npm test` in `acceptance-tests/` and `dev check`, fixing harness/step issues until both pass.

## Open Technical Decisions

### Synchronization strategy for eventually consistent projections

Use harness/test-level waiting by default. After a browser action or webhook POST, the step should wait for the user-observable projection in the LiveView/UI to reach the expected state with a bounded timeout and clear failure message. The webhook HTTP response should only prove that the event was accepted; it must not be treated as proof that Commanded/Ecto projections and LiveView rendering are complete.

This iteration should not make production status projections strongly consistent just to simplify tests. If implementation discovers a genuine product need for stronger consistency, that must be an intentional production design decision, documented separately, with tests explaining the user-facing guarantee. Otherwise, keep production consistency semantics unchanged and make the browser harness robust against eventual projection timing.

## New Capability

Developers can run the shared member-facing acceptance scenarios through a real browser and a running Phoenix app, with reliable startup/teardown, clear diagnostics, and projection-aware waiting. The browser suite can distinguish web-backed scenarios from domain-only scenarios using `@todo-web` without weakening the domain acceptance coverage.

## Validation Plan

- Run `npm test` from `acceptance-tests/` and confirm it passes with `not @todo-web` as the default browser tag expression.
- Confirm the browser run includes `homepage.feature` and `member_message_deliverability.feature`.
- Confirm `operator_email_deliverability.feature` remains excluded from the browser run while tagged `@todo-web`.
- Run the Elixir/domain acceptance path used by `dev check` and confirm it still runs all shared scenarios regardless of `@todo-web`.
- Run `dev check` and fix any failures.

## Risks / Follow-ups

- This plan depends on the iteration 005 routes and webhook endpoint being present before automation starts; if they are not merged, implementation should stop rather than creating duplicate app surfaces in this slice.
- LiveView and projection timing may reveal race conditions in the harness. Prefer bounded, observable waits with good diagnostics over fixed sleeps.
- Iteration 007 should remove the operator `@todo-web` deferral and add browser automation for `/deliveries` when that operator slice is implemented.
