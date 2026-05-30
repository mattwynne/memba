# Browser acceptance harness for member-facing behaviour

Date: 2026-05-29
Status: draft

## Goal

Developers and operators can see the currently implemented member-facing domain behaviour in a browser, and the shared acceptance scenarios for that behaviour run through Playwright.

This iteration creates a minimal LiveView substrate for browser acceptance. It is deliberately not the polished product design; design comes in a later iteration.

## Background / Context

Iterations 001–004 implemented the event-sourced foundation, Membership model, Messaging skeleton, and delivery status/read-model behaviour at the domain/application layer. The shared feature files currently describe the behaviour and are exercised by the Elixir/domain Cucumber steps.

The next useful capability is browser-level confidence: the same shared feature scenarios should be able to drive a running Phoenix app with Playwright where the behaviour is meant to be visible in the web UI.

Relevant context:

- ADR 0010: shared feature files with Elixir Cucumber.
- ADR 0013: use PhoenixTest for feature-style web tests.
- Current Playwright/Cucumber harness exists under `acceptance-tests/` and already covers the homepage.
- Phoenix LiveView is the chosen implementation shape for this minimal browser surface.

## Scope

### In scope

- Minimal Phoenix LiveView page(s) and forms for the already-implemented member-facing behaviours:
  - create clubs;
  - create people;
  - add people as club members;
  - send a club message;
  - view who a message is addressed to;
  - view one delivery record per addressed member;
  - view member-facing receipt statuses.
- Clear, unpolished developer controls in the browser to simulate provider status events needed by the member-facing scenarios:
  - delivered;
  - delayed with reason;
  - bounced with reason;
  - spam complaint with reason;
  - opened.
- Keep the existing shared `.feature` files as the acceptance source.
- Update Playwright/Cucumber step definitions so these browser scenarios pass:
  - `homepage.feature`;
  - all scenarios in `member_message_deliverability.feature`.
- Mark operator deliverability scenarios as deferred for the web acceptance harness with `@todo-web` tags.
- Configure the browser Cucumber default command to exclude `@todo-web` scenarios.
- Preserve the Elixir/domain Cucumber run so it continues to run all shared scenarios, including scenarios tagged `@todo-web`.
- Add PhoenixTest-based LiveView tests for the minimal browser surface and its important interactions.

### Out of scope

- Polished visual design or product UX.
- Real authentication, permissions, roles, or navigation design.
- Real email provider integration, webhooks, or tracking pixel endpoint.
- Operator deliverability browser UI.
- Changing the domain model for membership, messaging, or delivery status behaviour.
- Rewriting the acceptance language beyond web-partition tags needed by this iteration.

## Acceptance Criteria

- A developer can start the Phoenix app and use the browser to exercise the member-facing behaviours from the existing acceptance tests.
- `npm test` in `acceptance-tests/` runs the Playwright/Cucumber browser acceptance suite against browser-ready scenarios and excludes `@todo-web` scenarios by default.
- `homepage.feature` passes through the browser acceptance harness.
- Every scenario in `member_message_deliverability.feature` passes through the browser acceptance harness.
- `operator_email_deliverability.feature` remains in the shared acceptance suite, with its scenarios tagged `@todo-web` for browser acceptance.
- The Elixir/domain Cucumber run still runs all shared scenarios, including scenarios tagged `@todo-web`.
- PhoenixTest-based tests cover the new LiveView browser surface and important interactions.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Add minimal LiveView route(s) under the existing browser pipeline for the browser acceptance harness.
2. Build simple LiveView forms/actions for club creation, person creation, membership, club message sending, receipt viewing, and status simulation.
3. Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.
4. Update Playwright/Cucumber step definitions to drive the LiveView UI for `homepage.feature` and `member_message_deliverability.feature`.
5. Add `@todo-web` tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.
6. Configure `acceptance-tests` so the default browser Cucumber command excludes `@todo-web` scenarios.
7. Add PhoenixTest-based LiveView tests for the new browser surface, using PhoenixTest as the preferred high-level web test API.
8. Verify the Elixir/domain Cucumber path still runs every shared scenario regardless of `@todo-web` tags.
9. Run the browser acceptance suite and `dev check`, fixing any issues.

## Open Technical Decisions

None known.

## New Capability

Developers/operators can use a browser to exercise and inspect the member-facing behaviours that are currently only implemented and validated at the domain/application layer. The shared acceptance feature files can now partition browser-ready scenarios from browser-deferred scenarios with `@todo-web` while continuing to validate the full domain behaviour separately.

## Validation Plan

- Run `npm test` from `acceptance-tests/` and confirm it runs browser-ready scenarios only and passes.
- Confirm `@todo-web` excludes operator deliverability scenarios from the browser acceptance run.
- Run the Elixir/domain Cucumber suite and confirm it still runs all shared scenarios, including `@todo-web` scenarios.
- Run PhoenixTest-based LiveView tests for the minimal browser surface.
- Run `dev check` and fix any failures.
- Manual demo: start the Phoenix app, create clubs/people/members, send a club message, inspect addressed recipients/delivery records, simulate each member-facing delivery status, and see the member receipt status update.

## Risks / Follow-ups

- The minimal browser surface may reveal gaps in existing query APIs needed by LiveView. Keep any additions narrowly focused on exposing already-implemented behaviour.
- The developer controls are intentionally temporary substrate; a later design iteration should replace or reshape them into a real product UX.
- Operator deliverability browser UI remains deferred behind `@todo-web` and should be planned as a later slice.
