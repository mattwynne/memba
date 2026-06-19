## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/038-email-delivery-handoff-boundary/plan.md`.

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify whether `attempt_count` increments on every provider call or only failed provider calls. The current criteria require incrementing on errors, but “attempt count” usually means all attempts.
2. Clarify how operators/developers dispatch `pending` deliveries if a PubSub nudge is missed. The risks section mentions an internal retry/dispatch API, while the acceptance criteria focus mainly on retrying `failed` deliveries.
3. Consider adding one explicit test expectation for concurrent or repeated dispatcher nudges not causing two dispatcher processes to claim the same `pending` delivery.
4. Consider stating whether stale `dispatching` deliveries are deliberately left as a follow-up, since crashes between claim and completion can strand records.

## Smallest viable iteration

The smallest useful slice is essentially the one already described:

- `send_club_message/2` records message/delivery work and returns success without synchronous provider delivery.
- `EmailDeliveryCreated` creates `pending` delivery records.
- A supervised dispatcher claims `pending` deliveries, calls the provider, and records `sent` or `failed`.
- Provider failures are per-recipient and retryable through an internal/manual API.
- Existing browser-composed and accepted inbound club-message flows use the same async dispatch boundary.
- Focused tests prove the new boundary and lifecycle.

Automatic retries, startup/periodic sweeps, staff retry UI, event renaming, and broader application-service refactors are correctly left out.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. Tests showing `Memba.Messaging.send_club_message/2` no longer invokes the provider synchronously and still returns success after command acceptance.
2. Projection tests showing new `EmailDelivery` records start as `pending`.
3. Dispatcher tests showing:
   - `pending` → `dispatching` before provider call.
   - provider success results in `sent`.
   - provider failure results in `failed`, persisted diagnostic detail, and incremented attempt count.
   - one recipient failure does not block other recipient deliveries.
4. Retry tests showing failed deliveries can be retried without new message streams or duplicate `EmailDeliveryCreated` events.
5. Inbound club-message acceptance tests showing accepted inbound messages use the same pending-delivery/dispatcher path.
6. Replay/projector tests or provider fake assertions proving aggregate/projector replay does not call external providers.
7. UI/presentation checks confirming member-facing views do not expose raw infrastructure failure details while staff/operator diagnostics may show exact status/error.
8. `dev check` passing before completion.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}