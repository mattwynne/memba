## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Core technical decisions remain unresolved.**  
   The plan explicitly leaves open whether the boundary is a synchronous collaborator or a persisted outbox/handoff table, whether provider idempotency is sufficient, and where handoff failure state should live. These choices directly determine implementation shape, migrations, tests, retry semantics, and operational observability.

2. **The `send_club_message/2` result contract is not concrete enough.**  
   Acceptance criteria require a “clear result contract,” but the plan does not define the exact success, partial-failure, and total-failure return shapes. This makes it hard to objectively prove that callers can distinguish committed domain state from provider handoff failure.

3. **Retry/idempotency semantics are underspecified.**  
   The plan requires duplicate/retry safety, but does not define what local state or provider idempotency key is authoritative, when a delivery is considered already handed off, or how retries behave after partial recipient success.

## Non-blocking improvements

1. Name the likely test files or test modules to update once the boundary choice is resolved.
2. Clarify whether existing user-facing flash/copy should remain exactly unchanged when handoff fails after commit, or whether internal-only logging/state is sufficient.
3. Add a concise state transition sketch for handoff attempts if a persisted model is chosen.
4. Clarify whether provider failure observability means logs, return values, persisted state, telemetry, admin-facing state, or some combination.

## Smallest viable iteration

The smallest useful slice is:

- Extract provider delivery into a named `Memba.Messaging.EmailDeliveryHandoff` boundary.
- Define a concrete handoff result contract that always preserves the committed `message_id` / delivery IDs.
- Add local idempotency/retry protection per `email_delivery_id`, either via an explicit persisted handoff state or a documented decision that provider-level idempotency is sufficient and already available.
- Cover success, total failure, partial failure, retry/duplicate safety, and inbound acceptance through ExUnit tests.
- Keep user-facing message and delivery-status behaviour unchanged.

## Required plan edits

1. Resolve the boundary design: choose either a synchronous structured-result collaborator or a minimal persisted outbox/handoff table.
2. Define the exact `send_club_message/2` return contract for:
   - full success,
   - provider failure before any recipient is accepted,
   - provider failure after one or more recipients are accepted.
3. Define the exact handoff summary shape, including delivery IDs attempted, succeeded, failed, and skipped/already-handed-off if applicable.
4. Specify the idempotency mechanism:
   - provider idempotency key,
   - local persisted state,
   - or both.
5. Specify where handoff failure/retry state is observable.
6. Update acceptance criteria so “observable,” “retryable,” and “duplicate/retry safety” are objectively testable against the chosen design.

## Validation plan

To prove the iteration succeeded after the plan is revised and implemented:

1. Run focused ExUnit tests for `Memba.Messaging.send_club_message/2` and the new handoff boundary.
2. Verify successful sends still create message and email-delivery read models and invoke the configured provider.
3. Simulate provider failure before any recipient succeeds and verify:
   - the committed message state is not reported as a failed domain send,
   - handoff failure is returned or recorded according to the chosen contract.
4. Simulate provider failure after partial success and verify:
   - successful delivery IDs are distinguishable from failed ones,
   - earlier accepted recipients are not ambiguous.
5. Retry an already-created delivery and verify no second message stream or duplicate `EmailDeliveryCreated` event is produced, and no duplicate provider send occurs according to the chosen idempotency mechanism.
6. Verify inbound club-message acceptance uses the same outbound handoff boundary.
7. Confirm replay/projector paths do not call external providers.
8. Run `dev check`.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Core technical decisions remain unresolved; send_club_message/2 result contract is not concrete; retry/idempotency semantics are underspecified","gemini_review_required_edits":"Choose boundary design; define exact send_club_message/2 and handoff result contracts; specify idempotency mechanism and observable failure/retry state; make retry and observability acceptance criteria objectively testable"}}