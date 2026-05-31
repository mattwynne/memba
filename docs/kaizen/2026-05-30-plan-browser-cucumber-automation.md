# Plan: carve out browser Cucumber automation iteration

Date: 2026-05-30

## Purpose

Turn the deferred Playwright/Cucumber browser automation work into its own implementation-ready iteration, instead of burying it inside iteration 005's app-surface slice.

## Prerequisite

The salvaged iteration 005 app routes and webhook endpoint are available on `main` or on a stable reviewed branch:

- `/clubs`
- `/clubs/:club_id`
- `/messages/:message_id`
- `POST /webhooks/postmark`

## Proposed iteration goal

The shared member-facing acceptance scenarios run reliably through Playwright/Cucumber against the real Phoenix routes and Postmark-style webhook endpoint.

## Scope to plan

1. Keep shared feature files as the acceptance source.
2. Configure the browser Cucumber command to exclude `@todo-web` by default.
3. Keep the Elixir/domain acceptance path unfiltered so `@todo-web` only means “not web-backed yet”.
4. Implement JS step definitions for:
   - `homepage.feature`;
   - `member_message_deliverability.feature`.
5. Make Phoenix/Postgres/browser lifecycle explicit and reliable:
   - ensure DB is ready;
   - run migrations/setup as needed;
   - start Phoenix and wait for HTTP readiness;
   - collect server logs on failure;
   - tear down cleanly.
6. For webhook/status steps, POST to `/webhooks/postmark` and wait for observable projected UI state.
7. Define whether tests synchronize on events, projections, or explicit app-level consistency options.

## Out of scope

- New product UI beyond what salvaged 005 delivered.
- Operator deliveries overview (`/deliveries`) unless it becomes the next explicit browser-backed slice.
- Provider signature verification/retry hardening.

## Acceptance criteria for the new plan

- `homepage.feature` passes through Playwright/Cucumber.
- Every scenario in `member_message_deliverability.feature` passes through Playwright/Cucumber.
- `operator_email_deliverability.feature` remains excluded by `@todo-web` until the operator browser slice is implemented.
- Browser acceptance failures clearly identify startup, DB readiness, webhook, LiveView timing, or assertion failures.
- `dev check` passes.

## Done when

- A new iteration plan exists under `docs/iterations/`.
- The plan is validated by Fabro.
- The plan explicitly documents the synchronization strategy for eventually consistent projections.

## Resolution

Date: 2026-05-31

Root cause: Browser Cucumber automation was too large and entangled to keep inside the iteration 005 salvage slice.

Fix applied:

- `8a1b654`: planned browser Cucumber automation as a separate iteration.
- `e112917`: implemented the browser Cucumber automation work separately from the iteration 005 salvage.

Validation:

- Historical delivery evidence: the separate browser automation implementation commit is present on `main`.

Remaining follow-up:

- None for this planning note.
