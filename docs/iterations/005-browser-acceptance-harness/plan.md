# Browser acceptance harness for member-facing behaviour

Date: 2026-05-29
Status: ready

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

- Minimal, real-user-oriented Phoenix LiveView routes and forms for the already-implemented member-facing behaviours. Build the real route substrate now, without spending time on visual polish:
  - `/clubs` using `MembaWeb.ClubsLive.Index` to list and create clubs;
  - `/clubs/:club_id` using `MembaWeb.ClubsLive.Show` to show a club, create/add members, and send a club message;
  - `/messages/:message_id` using `MembaWeb.MessagesLive.Show` to show addressed recipients, one delivery record per recipient, and member-facing receipt statuses.
- Real application webhook-style endpoint at `POST /webhooks/postmark` for delivery/open events. It should anticipate Postmark's event shape enough to minimize later rework, map incoming provider events to the existing Messaging delivery status commands, and support the member-facing scenarios for:
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
- Full email provider integration, outbound Postmark sending, signature/security verification, retry handling, operational hardening, or tracking pixel endpoint.
- Operator deliverability browser UI.
- Changing the domain model for membership, messaging, or delivery status behaviour.
- Rewriting the acceptance language beyond web-partition tags needed by this iteration.

## Acceptance Criteria

- A developer can start the Phoenix app and use the browser to exercise the member-facing behaviours from the existing acceptance tests.
- `npm test` in `acceptance-tests/` runs the Playwright/Cucumber browser acceptance suite with the tag expression `not @todo-web` and passes.
- `homepage.feature` passes through the browser acceptance harness.
- Every scenario in `member_message_deliverability.feature` passes through the browser acceptance harness, including status changes driven by HTTP requests to `POST /webhooks/postmark` rather than browser-visible temporary controls.
- `operator_email_deliverability.feature` remains in the shared acceptance suite, with its scenarios tagged `@todo-web` for browser acceptance.
- The Elixir/domain acceptance path used by `dev check` still runs all shared scenarios, including scenarios tagged `@todo-web`; implementation must verify that the browser-only tag expression does not affect the domain runner.
- PhoenixTest-based LiveView tests are written first and cover all planned web behaviours: club creation, person creation, membership addition, sending a club message, addressed-recipient visibility, non-member exclusion, one delivery/receipt per addressed member, and receipt status changes after webhook/status-reporting functions are invoked.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Use TDD with PhoenixTest as the preferred high-level LiveView test API. Start by writing failing PhoenixTest coverage for the real route flows listed in the acceptance criteria.
2. Add browser routes under the existing browser pipeline:
   - `live "/clubs", ClubsLive.Index`;
   - `live "/clubs/:club_id", ClubsLive.Show`;
   - `live "/messages/:message_id", MessagesLive.Show`.
3. Add `POST /webhooks/postmark` under an appropriate non-browser pipeline for webhook requests.
4. Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:
   - `Memba.Membership.create_club/1`, `create_person/1`, and `add_member/1` for the LiveViews;
   - `Memba.Messaging.report_delivery_delivered/1`, `report_delivery_delayed/1`, `report_delivery_bounced/1`, `report_delivery_spam_complaint/1`, and `report_delivery_opened/1` for the Postmark webhook.
5. Build `MembaWeb.ClubsLive.Index`, `MembaWeb.ClubsLive.Show`, and `MembaWeb.MessagesLive.Show` with simple forms/actions for club creation, person creation, membership, club message sending, and receipt viewing.
6. Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.
7. Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.
8. Update Playwright/Cucumber step definitions to drive the real LiveView routes for `homepage.feature` and `member_message_deliverability.feature`; delivery/open report steps should make HTTP requests to `POST /webhooks/postmark`.
9. Add `@todo-web` tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.
10. Configure `acceptance-tests/cucumber.js` so the default browser Cucumber command uses `tags: "not @todo-web"`.
11. Verify the Elixir/domain acceptance path used by `dev check` still runs every shared scenario regardless of `@todo-web` tags.
12. Run the browser acceptance suite and `dev check`, fixing any issues.

## Open Technical Decisions

None known. The technical shape is:

- separate real LiveView routes, not a single developer harness page;
- thin public context APIs, not direct Commanded dispatch from LiveViews/controllers;
- Postmark-shaped webhook endpoint now, with provider hardening deferred;
- browser Cucumber excludes `@todo-web` with `not @todo-web`, while the domain acceptance path used by `dev check` runs all scenarios.

## New Capability

Developers/operators can use real browser routes to exercise and inspect the member-facing behaviours that are currently only implemented and validated at the domain/application layer. The application also has an initial Postmark-shaped webhook endpoint that turns provider delivery/open events into Messaging status commands. The shared acceptance feature files can partition browser-ready scenarios from browser-deferred scenarios with `@todo-web` while continuing to validate the full domain behaviour separately.

## Validation Plan

- Run `npm test` from `acceptance-tests/` and confirm it uses `not @todo-web`, runs browser-ready scenarios only, and passes.
- Confirm `@todo-web` excludes operator deliverability scenarios from the browser acceptance run.
- Run the Elixir/domain acceptance path used by `dev check` and confirm it still runs all shared scenarios, including `@todo-web` scenarios.
- Run PhoenixTest-based LiveView tests proving all member-facing route flows and receipt-status updates.
- Run `dev check` and fix any failures.
- Manual demo: start the Phoenix app, create clubs/people/members, send a club message, inspect addressed recipients/delivery records, POST Postmark-style delivered/delayed/bounced/spam/opened events, and see the member receipt status update.

## Risks / Follow-ups

- The minimal browser surface may reveal gaps in existing query APIs needed by LiveView. Keep any additions narrowly focused on exposing already-implemented behaviour through public contexts.
- The routes are intended as real product substrate, but visual design and interaction polish are deferred to a later design iteration.
- The Postmark webhook shape may need adjustment during the later provider integration iteration when signature verification, retries, and exact production payload details are added.
- Operator deliverability browser UI remains deferred behind `@todo-web` and should be planned as a later slice.
