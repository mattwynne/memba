# Deliveries overview for operator deliverability

Date: 2026-05-29
Status: ready

## Goal

Operators can visit a deliveries overview and see detailed delivery records across messages, so they can diagnose email delivery problems without starting from a single message.

## Background / Context

Iterations 001–004 implemented the domain/application behaviour for member message deliverability, including the operator deliverability read model. Iteration 005 creates the minimal browser substrate for member-facing behaviour and deliberately defers operator deliverability browser coverage behind `@todo-web` tags.

The current operator deliverability language and query shape are message-scoped. Product direction for the operator surface is broader: a `/deliveries` route that lists deliveries across all messages and can later grow filtering, slicing, pagination, and infinite scrolling.

Relevant context:

- ADR 0004: one Message aggregate owns per-recipient delivery state.
- ADR 0006: members see simplified receipt statuses; operators see detailed status and reason text.
- ADR 0009: Commanded/Ecto projections include operator deliverability queries.
- Iteration 005: browser acceptance harness and Postmark-shaped webhook endpoint for status events.

## Scope

### In scope

- Update `operator_email_deliverability.feature` so its model is an operator deliveries overview across messages, not a message-scoped operator view.
- Remove `@todo-web` deferral from the operator scenarios when the browser acceptance path supports them.
- Add a browser route at `/deliveries` using a LiveView such as `MembaWeb.DeliveriesLive.Index`.
- Show a read-only table of operator delivery records across all messages.
- Include enough columns for diagnosis: message subject/title, recipient name, recipient email/address, channel, detailed status, and reason.
- Change the public Messaging operator-deliverability query shape toward the deliveries-overview model rather than adding an unrelated bolt-on API. The API should be options-shaped so later pagination/filtering can fit without another conceptual rename.
- Implement only the unfiltered deliveries overview needed in this slice.
- Update Playwright/Cucumber step definitions so `operator_email_deliverability.feature` passes through the browser acceptance harness by using `/deliveries`.
- Add PhoenixTest-based LiveView tests for the deliveries page/table, including deliveries from more than one message and reason preservation.

### Out of scope

- Filtering, search, sorting controls, pagination, infinite scroll, saved views, or export.
- Person-centric delivery history across messages.
- Authentication, authorization, admin roles, or permissions.
- Visual/product polish beyond a usable diagnostic table with stable accessible labels/IDs.
- Real outbound Postmark sending, webhook signature/security verification, retries, suppression-list handling, or other provider hardening.
- Changing the delivery state machine or existing member-facing receipt vocabulary.

## Acceptance Criteria

- `/deliveries` exists and shows delivery rows from more than one message in one operator overview.
- Each row includes message subject/title, recipient name, recipient email/address, channel, detailed status, and reason where present.
- Delayed, bounced, and spam complaint rows preserve the provider/channel reason text.
- Opened deliveries are visible as `opened` after a delivered email is opened.
- Delivered/opened rows do not show stale problem reasons.
- `operator_email_deliverability.feature` uses deliveries-overview language and passes through the browser acceptance harness without `@todo-web` deferral.
- `homepage.feature` and `member_message_deliverability.feature` continue to pass through the browser acceptance harness.
- The Elixir/domain acceptance path used by `dev check` still runs the shared scenarios.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Update the operator feature language around the rule "Operators monitor detailed delivery records across messages", keeping scenarios BRIEF and focused on cross-message visibility, reason preservation, and opened status.
2. Write failing PhoenixTest coverage for `/deliveries`, including records from more than one message and problem reason text.
3. Reshape the public Messaging operator-deliverability query toward a deliveries-overview API, for example an options-shaped list function. Preserve any existing message-scoped needs through options or a compatibility wrapper only if still required by current code.
4. Add the `/deliveries` LiveView route under the browser pipeline.
5. Build the deliveries LiveView as a simple read-only table with stable accessible labels or IDs for browser acceptance.
6. Update browser Cucumber step definitions for `operator_email_deliverability.feature` so operator assertions inspect `/deliveries`.
7. Remove `@todo-web` tags from operator scenarios once they are browser-backed.
8. Verify browser Cucumber still defaults to excluding `@todo-web`, while now including the operator scenarios because they are no longer tagged.
9. Run the browser acceptance suite and `dev check`, fixing any issues.

## Open Technical Decisions

None known. The intended technical shape is:

- `/deliveries` is the operator overview route for delivery records across messages.
- The query API is deliveries-overview oriented and options-shaped for later filtering/pagination.
- This iteration may return an unpaginated list if that is the smallest working slice, but should order deterministically, preferably newest or most recently updated first.
- Pagination/infinite scroll is explicitly deferred, not half-implemented.

## New Capability

Operators can inspect a single browser page showing detailed delivery records across messages, including problem reasons, instead of relying only on domain-level tests or message-scoped read models.

## Validation Plan

- Run `npm test` from `acceptance-tests/` and confirm operator deliverability scenarios now run and pass through the browser acceptance harness.
- Run PhoenixTest-based LiveView tests for the deliveries page/table.
- Run the Elixir/domain acceptance path used by `dev check` and confirm it still runs the shared scenarios.
- Run `dev check` and fix any failures.
- Manual demo: start the Phoenix app, create a club with members, send at least two messages, POST Postmark-style delayed/bounced/spam/opened events, visit `/deliveries`, and see all delivery records in one table with statuses and reason text.

## Risks / Follow-ups

- The unfiltered table is intentionally minimal; filtering, search, pagination, infinite scroll, and exports should be planned as later slices once the overview shape proves useful.
- The existing projection may not contain message title/subject in the most convenient form for an all-deliveries view; keep any projection/query changes narrow and backward-compatible with existing domain behaviour.
- Authentication and operator permissions remain deferred and must be addressed before exposing this surface in a real multi-user setting.
