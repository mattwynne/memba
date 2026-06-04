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
