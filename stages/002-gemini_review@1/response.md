## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/038-email-delivery-handoff-boundary/plan.md`. The plan is ready for implementation and is already marked `Status: validated`.

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify exact `attempt_count` semantics:
   - Should it increment when a delivery is claimed/attempted, regardless of success or failure?
   - Or only when provider dispatch fails?
   - The current criteria imply failure/retry increments, but a uniform “increments once per provider attempt” rule may be clearer.

2. Clarify concurrency expectations for the dispatcher:
   - The plan says claiming should avoid two dispatcher invocations claiming the same pending delivery concurrently.
   - It could optionally name the preferred mechanism, such as an atomic `UPDATE ... WHERE status = 'pending'`, transaction, lock, or equivalent Ecto pattern.

3. Consider explicitly naming where the internal/manual retry API should live, for example `Memba.Messaging.retry_email_delivery/1` or similar. The plan requires the capability but leaves the exact interface to implementation judgment, which is acceptable.

4. Consider adding a validation expectation for missed PubSub nudges:
   - The plan explicitly excludes automatic sweeping/startup sweeping.
   - It may still be useful to test or document that manual dispatch/retry can recover pending/failed deliveries when the PubSub nudge is missed.

## Smallest viable iteration

The smallest useful slice is the plan as written, with no further reduction recommended:

- Change `EmailDeliveryCreated` projection from initial `sent` to `pending`.
- Remove synchronous provider dispatch from `Memba.Messaging.send_club_message/2`.
- Add a supervised dispatcher that claims `pending` deliveries, calls the provider, and records `sent` or `failed`.
- Add manual retry for failed deliveries.
- Adapt inbound accepted club-message delivery to the same async path.
- Add focused tests proving command acceptance is separated from provider availability.

Removing any of these would either leave the existing misleading state model in place or fail to prove the new async handoff boundary.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. Targeted tests showing `send_club_message/2` accepts and records message/delivery work without synchronously calling the provider.
2. Projection tests showing newly created `EmailDelivery` records start as `pending`.
3. Dispatcher tests showing:
   - `pending` deliveries are claimed as `dispatching`;
   - provider acceptance moves delivery to `sent`;
   - provider error moves delivery to `failed`;
   - attempt count and latest provider error/detail are persisted;
   - one recipient failure does not block other recipients.
4. Manual retry tests showing failed deliveries can be retried without creating duplicate message streams or duplicate `EmailDeliveryCreated` events.
5. Inbound club-message tests showing accepted inbound messages use the same async dispatch path.
6. Replay/projector-path tests or fakes proving external provider calls do not happen during aggregate/projector replay.
7. UI/presentation checks confirming member-facing views do not expose raw infrastructure failure detail while staff/operator diagnostics can show exact status/error.
8. `dev check` passes before completion.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}