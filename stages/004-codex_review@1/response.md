## Decision: READY

## Confidence: High

The plan is complete enough for implementation. I read the full plan file directly from `docs/iterations/038-email-delivery-handoff-boundary/plan.md`.

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the exact concurrency mechanism for claiming deliveries, e.g. atomic `UPDATE ... WHERE status = 'pending'` or equivalent Ecto transaction/query pattern, to avoid double dispatch.
2. Clarify whether `attempt_count` increments when a delivery is claimed or only when the provider returns an error. The criteria currently require incrementing on failure/retry, which is adequate, but an explicit convention would reduce implementation ambiguity.
3. Consider naming the likely migration/schema files once implementation begins, though the current module/file guidance is sufficient for readiness.
4. Add a brief note that missed PubSub nudges are intentionally acceptable in this slice because automatic sweeping/startup recovery is out of scope.

## Smallest viable iteration

The smallest useful slice is exactly the technical handoff boundary described:

- Change new `EmailDelivery` records to start as `pending`.
- Remove inline provider delivery from `Memba.Messaging.send_club_message/2`.
- Add a supervised dispatcher that claims pending deliveries, calls the provider, and records `sent` or `failed`.
- Add manual/internal retry for failed deliveries.
- Cover browser-composed and inbound accepted club messages with tests.

Anything smaller would either leave the model dishonest (`sent` before provider dispatch) or leave no operational way to move pending work forward.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. Targeted automated tests showing `send_club_message/2` accepts/records messages without synchronous provider calls.
2. Projection tests confirming `EmailDeliveryCreated` creates `pending` deliveries.
3. Dispatcher tests confirming:
   - `pending` is claimed as `dispatching`;
   - provider success becomes `sent`;
   - provider failure becomes `failed` with attempt count and latest error/detail;
   - one recipient failure does not block other recipients.
4. Manual/internal retry tests confirming retry does not create duplicate message streams or duplicate `EmailDeliveryCreated` events.
5. Inbound club-message tests confirming accepted inbound messages use the same async dispatch path.
6. Replay/projector-path tests or test seams confirming providers are not called during replay/projection.
7. `dev check` passing before completion.
8. Optional local manual verification with the fake provider for success and failure flows.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}