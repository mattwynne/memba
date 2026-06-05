# Problem: Acceptance tests flake while waiting for projected member rows

Date: 2026-06-04

## Context

While wiring local real inbound email testing through ngrok and Resend, we ran the normal quality gate after changing dev orchestration, Resend inbound handling, and local setup docs.

Relevant commands included:

```sh
./bin/dev check
./bin/dev acceptance
```

The same acceptance suite was also rerun after stopping the local dev server and after unsetting provider/tunnel environment variables.

## Expected standard

`./bin/dev check` is the required local quality gate for code, config, dependency, migration, acceptance-test, or app-behaviour changes. It should give a reliable signal: if application behaviour is correct, the acceptance suite should pass without repeated manual reruns or interpretation.

Acceptance setup steps that create clubs, people, and memberships should wait for the application and projections in a way that is deterministic enough for normal local validation.

## What happened

The ExUnit portion passed, but the browser acceptance suite repeatedly failed on setup steps that wait for newly-created projected member rows in the staff UI.

Observed failures included scenarios unrelated to the Resend inbound change, for example:

- `features/authentication.feature:116` — `Club member signs out from a club page`
- `features/member_club_subdomains.feature:68` — `Robin does not see the smoke-test club on the Memba homepage`
- `features/member_message_deliverability.feature:25` — `Alice sees different statuses for different members`
- `features/person_email_addresses.feature:18` — `Alice receives a club message at her primary email address`

The repeated failure shape was:

```text
Projection timing timeout: timed out waiting for projected browser UI: new member row for Alice in Kootenay Mountaineering Club.
Last assertion error: expect(locator).toHaveCount(expected) failed

Locator:  locator('[data-testid="member-row"][data-member-name="Alice"]')
Expected: 1
Received: 0
Timeout:  10000ms
```

Similar failures occurred for `Pat` and `Smoke Tester` rows.

A targeted rerun passed:

```sh
cd acceptance-tests && npm test -- --name 'Alice sends a club message'
```

A later full acceptance rerun also passed:

```sh
./bin/dev acceptance
# 34 scenarios (34 passed)
```

## Impact

The flake consumed debugging time during an integration workflow that already involved several moving parts: devenv/process-compose, ngrok, Resend webhooks, real email delivery, local secrets, and Phoenix code reloading.

It blurred the quality signal from `dev check`. A failure in an unrelated acceptance setup step made it harder to know whether the current code change had broken product behaviour, whether local environment leakage was involved, or whether the acceptance harness had merely missed a projection update.

## What allowed it to happen

The acceptance harness appears to depend on observing staff UI rows within a fixed 10-second projection wait. When projections, LiveView navigation, browser reloads, or test setup timing are slow, the failure appears as a product-level scenario failure rather than a clearly diagnosed harness/projection synchronization problem.

The system weakness is a brittle validation boundary: the acceptance setup path does not make projection lag impossible, obvious, or easy to distinguish from a real application failure. The standard `dev check` gate therefore has a flaky feedback mode.

## Observations

- The failures were in scenario setup steps, before the scenario-specific behaviour under test ran.
- The failed scenarios varied across reruns, but the failure shape stayed the same: waiting for projected member rows in the browser UI.
- The Phoenix server logs attached by Cucumber mostly showed repeated LiveView cross-session navigation warnings and auth callback warnings; they did not point directly to the missing projection row cause.
- Rerunning the same or full acceptance suite could pass without a product-code change.
- Some runs were made while local provider/tunnel environment variables were present, but the same failure shape also appeared after explicitly unsetting those variables for acceptance, suggesting the flake is not solely caused by Resend/ngrok configuration leakage.

## Why this matters

A flaky required gate trains us to rerun rather than trust failures. That risks hiding real regressions, slowing delivery, and making future integration work harder to debug. The bigger and more cross-system the change, the more important it is for the acceptance gate to provide a stable, well-localized signal.

## Open questions

- Are the membership/projector processes actually lagging, or is the browser on a stale/stuck staff page after navigation?
- Does the 10-second wait in `acceptance-tests/features/support/member_message.js` need better synchronization with Commanded projections or LiveView reloads?
- Are acceptance reset/setup endpoints returning before projectors have fully restarted and caught up?
- Did recent local dev process-manager changes make this more likely, or is this an older intermittent flake that happened to surface during this workflow?

## Possible prevention ideas

- Add clearer diagnostics to the acceptance setup wait: current club page URL, visible member rows, projection table counts, and recent projector subscription state.
- Make reset/setup endpoints return only after projectors are restarted and caught up enough for the next browser assertion.
- Replace fixed projection waits in setup steps with a stronger application-level readiness check or direct support endpoint for setup completion.
- Record acceptance flakes separately from product failures when the failing step is harness setup rather than the scenario behaviour.

## Resolution

Date: 2026-06-05

Root cause: Acceptance setup steps used the staff browser UI as their data factory and then waited for projected rows by polling browser-visible state. That made setup depend on LiveView navigation, browser reload timing, and fixed projection timeouts even though the setup data could be created through application commands with strong consistency.

Fix applied:

- `acceptance-tests/features/support/server_commands.js`: added batched Elixir RPC setup helpers for clubs, people, members, smoke-test data, slugs, and person email addresses. The helpers dispatch through the application contexts with `consistency: :strong` and return projected IDs/state for the Cucumber world.
- `acceptance-tests/features/step_definitions/member_message_steps.js`: changed grouped people/member Given steps to use batched server setup instead of repeated per-person RPC/browser work.
- `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js`: changed slug and smoke-test club Given setup to use Elixir setup methods instead of staff-browser setup.
- `acceptance-tests/features/step_definitions/person_email_address_steps.js`: changed primary/alternate email Given setup to use Elixir setup methods instead of staff-browser setup.
- `acceptance-tests/features/support/member_harness.js`: reused signed-in staff/member harness contexts within a scenario, reducing repeated login/page setup and making repeated assertions less timing-sensitive.
- `acceptance-tests/features/support/member_message.js`: avoided redundant browser page opens for repeated assertions while keeping forced reloads where webhook-driven projection polling still needs a fresh read.
- `web/lib/memba/read_model_changes.ex` and all Ecto projectors: added a general committed read-model change bus, published from `after_update/3`, so future tests and LiveViews can synchronize on committed projection changes rather than browser polling.
- `docs/adr/0021-publish-committed-read-model-changes.md`: recorded the architectural decision to publish committed read-model changes.

Validation:

- `cd acceptance-tests && npm run test:config` — passed.
- `cd acceptance-tests && ACCEPTANCE_LOG_PROGRESS=1 ACCEPTANCE_SLOW_STEP_THRESHOLD_MS=1000 npm test` — passed, 34 scenarios / 215 steps, about 1m01s.
- `dev check` — passed, 511 ExUnit tests and 34 browser acceptance scenarios.

Remaining follow-up:

- Use the read-model change bus from LiveViews to address `docs/problems/2026-06-01-delivery-status-not-live.md`, refreshing delivery-status UI when relevant read models change.

## Follow-up: committed read-model waits and projection barriers

Date: 2026-06-05

Additional synchronization work completed:

- `web/lib/memba_web/controllers/dev_test_support_controller.ex` and `web/lib/memba_web/router.ex`: added a dev/test-only server-sent events stream for committed read-model changes at `/dev/test-support/read-model-changes/events`.
- `acceptance-tests/features/support/member_message.js`: changed Postmark delivery-status steps to subscribe to the read-model change stream before posting the webhook, then wait for both member-facing and Memba-staff-facing delivery projections before asserting browser state.
- `web/lib/memba/projection_barrier.ex`: added a reusable Elixir projection barrier that waits until selected Commanded Ecto projectors have caught up to the current EventStore `$all` checkpoint.
- `acceptance-tests/features/support/server_commands.js`: exposed projection barriers through the existing Elixir RPC/server-command mechanism rather than adding another HTTP endpoint.
- Negative acceptance assertions that depend on messaging projections now wait for a projection barrier before checking absence, replacing timeout-based waits in the addressed-recipient and alternate-email mailbox checks.
- `docs/adr/0022-use-projection-barriers-for-read-your-writes.md`: recorded the projection-barrier decision and vocabulary.

Validation:

- `dev check` — passed, 513 ExUnit tests and 34 browser acceptance scenarios.
- Full browser acceptance in that run completed in about 0m58.9s, with executing steps about 0m51.6s.

Impact:

- Delivery-status webhook waits now synchronize on committed read-model changes rather than browser page polling.
- Negative assertions no longer need to wait for a fixed timeout just to prove absence when the relevant projections have already caught up.
- The projection flake prevention mechanism is now split along standard event-sourced lines: read-model change notifications for positive waits, projection barriers for read-your-writes and absence checks.
