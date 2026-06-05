# Plan: Continue acceptance fast-feedback improvements without sharding

Date: 2026-06-05

## Context

The browser acceptance suite has been reduced from roughly 1m47–1m51 to roughly 55 seconds locally through setup batching, shared browser reuse, committed read-model change waits, projection barriers, and direct Given setup for message creation.

Sharding remains a possible future wall-clock optimization, but it carries more harness complexity and global-state isolation work. Before taking that on, there are smaller serial-suite improvements that preserve the current one-app, one-scenario-at-a-time model.

## Expected standard

Acceptance tests should use the browser for behaviour under test, not for incidental data setup. Given/setup steps may cheat through Elixir/application APIs when they are arranging preconditions.

Tests should synchronize on application facts where possible:

- committed read-model changes for positive projection waits;
- projection barriers for read-your-writes and absence checks;
- direct application/test-support state for setup and delivery facts.

Swoosh/dev mailbox remains useful as a local email viewer, but it should not be the main synchronization primitive for acceptance tests when a deterministic application signal or query would be clearer.

## Current state

Completed improvements include:

- Given setup for clubs, people, members, slugs, person email addresses, and smoke-test fixtures uses Elixir RPC helpers.
- Given message setup uses `Memba.Messaging.send_club_message/2` through Elixir RPC instead of staff-browser UI.
- Staff/member harness sign-in for non-auth scenarios creates sign-in tokens directly through Elixir RPC and visits the callback.
- Postmark delivery-status waits subscribe to committed read-model changes before posting webhooks.
- Selected negative assertions use `Memba.ProjectionBarrier` instead of fixed timeout waits.

The full acceptance suite passed after these changes:

```text
34 scenarios (34 passed)
215 steps (215 passed)
0m55.267s total
0m48.061s executing steps
```

## Follow-up plan

### 1. Replace callback-token auth with direct session setup for non-auth scenarios

Current non-auth harnesses still create a sign-in token and visit `/auth/sign-in/:token`. This avoids mailbox polling, but it still exercises callback routing, token consumption, redirects, and staff onboarding checks.

Plan:

- Add a dev/test-only way to create an authenticated browser context or session cookie directly.
- Keep `features/authentication.feature` on the real magic-link flow.
- Use direct session setup only in non-auth setup helpers such as member/staff harness sign-in and `Given Pat is signed in as Memba staff`.
- Prefer an Elixir/server-command helper if Playwright can set the resulting cookie cleanly; otherwise add a very small dev/test support route whose only job is to set the session using `MembaWeb.IdentityAuth.log_in_identity/2`.
- Validate that member and staff LiveViews receive the same session shape as production login.

Expected benefit:

- Remove remaining sign-in-token callback overhead from non-auth scenarios.
- Reduce auth-related incidental failures in tests that are not about auth.

### 2. Replace mailbox polling with deterministic delivery facts

Positive and negative mailbox assertions still inspect Swoosh/dev mailbox state. Some of these waits are slow because they poll for email arrival or absence.

Plan:

- Keep Swoosh as the local developer mailbox/viewer.
- Add an acceptance-friendly delivery record or query path for local/fake provider deliveries.
- Prefer querying application/provider delivery facts through Elixir RPC over scraping `/dev/mailbox`.
- For positive assertions, wait for a deterministic delivery fact rather than polling the mailbox UI/API.
- For negative assertions, use projection barriers or delivery-provider completion facts before checking absence once.
- Preserve enough assertion detail to prove recipient, subject, body, sender, and provider metadata when those are behaviourally relevant.

Expected benefit:

- Reduce 1-second mailbox waits.
- Separate “email was handed to provider” from “developer mailbox rendered the email”.
- Make email assertions easier to diagnose.

### 3. Use read-model changes for LiveView updates

ADR 21 added a committed read-model changes bus, and acceptance tests now use it for webhook-driven projection waits. Product LiveViews do not yet use it broadly.

Plan:

- Start with delivery-status surfaces called out by `docs/problems/2026-06-01-delivery-status-not-live.md`.
- Subscribe relevant LiveViews to `Memba.ReadModelChanges.topic()` on mount when connected.
- Filter by projector and affected IDs, then refresh only the relevant assigns/streams.
- Keep refresh code read-model-driven; do not expose raw internal event bus data as a product API.
- Add LiveView tests for updating delivery status without manual page reload where practical.

Expected benefit:

- Users see delivery-status changes live.
- The same committed-projection boundary serves tests and product UI.

### 4. Apply projection barriers to remaining projection-backed negative assertions

Some absence assertions still use Playwright timeouts. Not all of them are projection-backed, but the ones that are should use projection barriers.

Plan:

- Audit acceptance steps for `not.toContainText`, `toHaveCount(0)`, “should not see”, and “should not receive”.
- Classify each as:
  - projection/read-model absence;
  - mailbox/provider absence;
  - pure browser/UI absence;
  - auth/session absence.
- Add `Memba.ProjectionBarrier` waits before projection/read-model absence assertions.
- Use delivery facts or provider completion for mailbox/provider absence assertions.
- Leave pure browser/UI absence assertions on short Playwright checks where no server-side barrier applies.

Expected benefit:

- Remove avoidable fixed waits.
- Make absence checks deterministic and faster.

## Out of scope

- Acceptance sharding or Cucumber `--parallel` work.
- Broad scenario-scoped data isolation for same-app parallelism.
- Replacing Swoosh as the developer mailbox.

## Validation approach

For each increment:

```sh
cd acceptance-tests && npm run test:config
cd acceptance-tests && npm test
```

For code/config/app-behaviour changes, finish with:

```sh
dev check
```

Track total and executing acceptance time after each change so improvements are measured rather than assumed.

## Resolution

Date: 2026-06-05

Root cause: Non-auth acceptance helpers still used sign-in-token callback routing as their shortcut. That removed mailbox polling, but still exercised auth-token creation, callback consumption, redirects, and staff onboarding paths in scenarios that were not about authentication. The earlier direct-token shortcut also broke one interrupted-journey scenario when used where the real auth redirect behaviour was the behaviour under test.

Fix applied:

- `web/lib/memba_web/router.ex`: added a dev/test-only session pipeline and `POST /dev/test-support/sign-in` route. The route has session access but stays outside the production router surface.
- `web/lib/memba_web/controllers/dev_test_support_controller.ex`: added `sign_in/2`, which stores the requested signed-in identity in the browser session through `MembaWeb.IdentityAuth.log_in_identity/2`.
- `web/test/memba_web/controllers/dev_test_support_controller_test.exs`: added coverage proving the direct sign-in route normalizes and stores the session identity.
- `acceptance-tests/features/support/authentication.js`: changed non-auth direct sign-in helper to call the dev/test session route and navigate to a requested return path.
- `acceptance-tests/features/support/member_harness.js`: changed staff/member harness sign-in to use the direct session route instead of creating and consuming sign-in tokens.
- `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js`: kept the real magic-link flow when the browser is already on `/auth`, preserving the interrupted-private-URL sign-in behaviour under test, while using direct session setup for ordinary non-auth sign-in setup.
- `acceptance-tests/features/support/server_commands.js`: removed the no-longer-used sign-in-token server command helper.

Validation:

- `cd web && mix test test/memba_web/controllers/dev_test_support_controller_test.exs` — passed, 3 tests.
- `cd acceptance-tests && npm run test:config` — passed, 48 tests.
- `cd acceptance-tests && ACCEPTANCE_LOG_PROGRESS=1 npx cucumber-js features/member_club_subdomains.feature --name 'Alice signs in after opening a private club message URL|Alice opens Kootenay|Alice composes'` — passed, 3 scenarios.
- `dev check` — passed, 514 ExUnit tests and 34 browser acceptance scenarios. Browser acceptance completed in about 0m48.0 total, with about 0m41.4 executing steps.

Remaining follow-up:

- Replace mailbox polling with deterministic delivery facts.
- Use read-model changes for LiveView delivery-status updates.

### Follow-up progress: projection-backed negative assertions

Date: 2026-06-05

Audit result:

- Member/staff addressed-recipient absence assertions already wait for `Memba.Messaging.Projectors.MemberEmailDelivery` or `Memba.Messaging.Projectors.EmailDelivery` before checking absence.
- Club-subdomain and auth/session absence assertions are browser/session checks rather than projection-backed checks.
- Person email-address delivery absence had the right `Memba.Messaging.Projectors.EmailDelivery` barrier, but the Promise was not awaited.

Fix applied:

- `acceptance-tests/features/step_definitions/person_email_address_steps.js`: awaited the existing projection barrier before checking that no club-message email was delivered to the removed address.

Remaining follow-up:

- Replace mailbox polling with deterministic delivery facts.
- Use read-model changes for LiveView delivery-status updates.
