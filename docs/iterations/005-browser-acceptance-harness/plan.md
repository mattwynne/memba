# App substrate for browser-facing member behaviour

Date: 2026-05-29
Status: merged

## Goal

Recover a small, shippable application slice that exposes the already-implemented member-facing deliverability behaviour through Phoenix routes and a Postmark-shaped webhook endpoint. This slice deliberately stops short of JS Cucumber/Playwright automation.

## Background / Context

Iterations 001–004 implemented the event-sourced foundation, Membership model, Messaging skeleton, and delivery status/read-model behaviour at the domain/application layer. Iteration 005 was originally planned as a full browser acceptance harness. The failed implementation run mixed useful app-side work with broad automation and workflow changes, so this salvaged plan narrows the delivered scope to the Phoenix app substrate only.

Relevant context:

- ADR 0010: shared feature files with Elixir Cucumber.
- ADR 0013: use PhoenixTest for feature-style web tests.
- Phoenix LiveView is the chosen implementation shape for this minimal browser surface.

## Scope

### In scope

- Minimal Phoenix LiveView routes and forms for the already-implemented member-facing behaviours:
  - `/clubs` using `MembaWeb.ClubsLive.Index` to list and create clubs;
  - `/clubs/:club_id` using `MembaWeb.ClubsLive.Show` to show a club, create people, add members, and send a club message;
  - `/messages/:message_id` using `MembaWeb.MessagesLive.Show` to show addressed recipients, delivery records, and member-facing receipt statuses.
- Real application webhook-style endpoint at `POST /webhooks/postmark` for delivery/open events. It maps Postmark-like provider events onto existing Messaging status-reporting commands for delivered, delayed, bounced, spam complaint, and opened reports.
- Thin public context APIs needed by the web layer:
  - `Memba.Membership.create_club/2`, `create_person/2`, `add_member/2`, `list_clubs/0`, and `list_people/0`;
  - `Memba.Messaging.list_messages_for_club/1` and status-reporting APIs.
- PhoenixTest/controller/router tests for the application surface and important interactions.
- Narrow ExUnit support needed by those tests.

### Out of scope

- JS Cucumber step-definition rewrites, Playwright/browser-server lifecycle changes, and browser acceptance package/config changes.
- Tagging or partitioning shared feature files for browser automation.
- Polished visual design or product UX.
- Real authentication, permissions, roles, or navigation design.
- Full email provider integration, outbound Postmark sending, signature/security verification, retry handling, operational hardening, or tracking pixel endpoint.
- Operator deliverability browser UI.
- Broad Fabro workflow, skill, planning, or kaizen changes from the failed run branch.

## Acceptance Criteria

- A developer can start the Phoenix app and use the browser to exercise the member-facing behaviours from the existing domain scenarios: create a club, create people, add active members, send a club message, and inspect addressed recipients and receipt statuses.
- `POST /webhooks/postmark` accepts Postmark-shaped delivered, delayed, bounced, spam complaint, and opened events and dispatches the existing Messaging status commands.
- PhoenixTest-based LiveView tests cover club creation, person creation, membership addition, sending a club message, addressed-recipient visibility, non-member exclusion, one delivery/receipt per addressed member, and receipt status changes after status-reporting functions are invoked.
- Controller tests cover the Postmark event mappings and unsupported-event response.
- Router tests cover the new LiveView routes and webhook route.
- Existing shared feature files and browser automation configuration are unchanged in this salvage slice.
- `dev check` passes.

## Implementation Plan

1. Recover only the useful app-side changes from the failed run branch onto a fresh branch from `origin/main`.
2. Add browser routes under the existing browser pipeline:
   - `live "/clubs", ClubsLive.Index`;
   - `live "/clubs/:club_id", ClubsLive.Show`;
   - `live "/messages/:message_id", MessagesLive.Show`.
3. Add `POST /webhooks/postmark` under the API pipeline.
4. Add thin public context APIs rather than dispatching Commanded commands directly from LiveViews/controllers.
5. Build `MembaWeb.ClubsLive.Index`, `MembaWeb.ClubsLive.Show`, and `MembaWeb.MessagesLive.Show` with simple forms/actions for club creation, person creation, membership, club message sending, and receipt viewing.
6. Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.
7. Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for PhoenixTest and future browser automation.
8. Keep consistency options explicit at web/test call sites that immediately re-read projections; do not make strong consistency the default public Messaging status-reporting API contract.
9. Run `dev check` and fix any issues.

## Deferred Browser Automation

The original iteration goal included updating Playwright/Cucumber step definitions and configuring browser Cucumber tag partitioning. That work is intentionally deferred. This salvage branch leaves the shared feature files and JS acceptance harness untouched so the app substrate can be reviewed and merged independently.

## Validation Plan

- Run focused ExUnit/PhoenixTest coverage for the new context, LiveView, controller, and router tests as needed while repairing the slice.
- Run `dev check` and fix any failures.
- Manual demo: start the Phoenix app, create clubs/people/members, send a club message, inspect addressed recipients/delivery records, POST Postmark-style delivered/delayed/bounced/spam/opened events, and see the member receipt status update after refreshing the message route.

## Risks / Follow-ups

- The minimal browser surface is intentionally plain. Visual design and interaction polish remain future work.
- The Postmark webhook shape may need adjustment during a later provider integration iteration when signature verification, retries, and exact production payload details are added.
- Browser Cucumber/Playwright automation remains deferred and should be planned as a separate slice after this substrate is merged.
