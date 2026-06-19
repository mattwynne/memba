## Decision: READY

## Confidence: High

## Blocking gaps

1. None.

## Non-blocking improvements

1. Name the internal/manual retry API more explicitly, if known, so implementation and tests can converge faster.
2. Specify the preferred concurrency-safe claim mechanism for `pending` → `dispatching`, such as conditional update by status, transaction, lock, or equivalent.
3. Clarify whether stale `dispatching` records are intentionally excluded from this slice, alongside the existing no-sweeper/no-automatic-retry boundary.
4. List the expected diagnostic field names if the author wants tighter implementation guidance, e.g. `attempt_count`, `latest_provider_error`, `last_dispatch_attempted_at`, `sent_at`, `failed_at`.

## Smallest viable iteration

The smallest useful slice is essentially the plan’s core path:

- Create `EmailDelivery` records as `pending`.
- Remove synchronous provider delivery from `Memba.Messaging.send_club_message/2`.
- Add a supervised dispatcher that claims pending deliveries, calls the provider, and marks each delivery `sent` or `failed`.
- Persist attempt count and latest error.
- Add internal retry for failed deliveries.
- Prove browser-composed and accepted inbound club messages use this same handoff path.

UI polish, exact operator display formatting, and advanced recovery from stale `dispatching` records can remain outside the slice.

## Required plan edits

1. None required.

## Validation plan

Success can be proven with focused automated tests plus `dev check`:

1. `send_club_message/2` accepts and records a message without synchronously calling the email provider.
2. `EmailDeliveryCreated` projects per-recipient records as `pending`.
3. The supervised dispatcher starts, receives read-model-change nudges, claims pending deliveries as `dispatching`, and calls the provider outside aggregate/projector replay.
4. Provider acceptance moves the delivery to `sent`.
5. Provider failure moves only the affected delivery to `failed`, increments attempt count, and stores latest diagnostic detail.
6. Partial recipient failure does not block dispatch for other recipients.
7. Manual/internal retry of a failed delivery does not create duplicate message streams or duplicate `EmailDeliveryCreated` events and can move the record to `sent`.
8. Accepted inbound club-message emails use the same async dispatch path.
9. Existing provider/webhook statuses continue to work after provider acceptance.
10. Member-facing surfaces avoid raw infrastructure failure details while staff/operator diagnostics can expose exact status/error where appropriate.
11. `dev check` passes.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}