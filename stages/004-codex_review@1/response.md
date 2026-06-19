## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Core handoff architecture is still undecided.**  
   The plan explicitly leaves open whether the boundary is only an extracted synchronous collaborator or a persisted outbox/handoff table. That choice affects implementation shape, tests, retry semantics, observability, and stop condition.

2. **Retry/idempotency mechanism is unresolved.**  
   The acceptance criteria require duplicate/retry safety, but the plan does not decide whether safety comes from provider idempotency keys, local persisted handoff state, or another mechanism. This is a blocking technical decision because it is central to the iteration’s stated goal.

3. **The `send_club_message/2` result contract is not concrete enough.**  
   The plan says the function should not conflate domain dispatch with provider handoff and suggests a result “such as” `{:ok, summary}` or `{:error, {:handoff_failed, summary}}`, but it does not define the exact contract callers should rely on. Since this may affect LiveViews, controllers, inbound acceptance, and tests, the plan needs the intended shape before implementation.

4. **Observable handoff failure state is not specified.**  
   The plan requires provider handoff failures to be observable and testable, but leaves open whether that means an existing read model, a new internal operational read model, a handoff table, or structured return-only state. The implementation cannot be reliably validated without knowing where the durable/observable state lives, if any.

## Non-blocking improvements

1. Clarify the exact handoff summary fields expected in tests, for example attempted delivery IDs, succeeded delivery IDs, failed delivery IDs, and failure reasons.

2. Name the most likely test files or test modules to update once the current code is inspected.

3. Add one sentence explaining whether provider handoff failures should be user-visible in this iteration. The scope implies no UI change, but making that explicit would help prevent accidental product changes.

4. Clarify whether “provider failure before any recipient is accepted” and “provider failure after at least one recipient has been accepted” refer to provider API acceptance, adapter return values, or local handoff state transitions.

## Smallest viable iteration

The smallest useful slice is:

- Extract a named `Memba.Messaging` email handoff collaborator.
- Define a concrete `send_club_message/2` return contract that always exposes the committed message identity when the domain command succeeds.
- Add minimal per-delivery handoff tracking or provider idempotency-key usage sufficient to prevent duplicate sends for already-successful deliveries.
- Keep handoff synchronous for now; do not introduce a full background job system.
- Add focused ExUnit coverage for full success, total provider failure, partial provider failure, retry/duplicate safety, and inbound accepted club-message handoff.

## Required plan edits

1. Decide whether this iteration will implement:
   - synchronous collaborator only with provider-level idempotency, or
   - synchronous collaborator plus minimal persisted local handoff state, or
   - a tiny persisted outbox/handoff table.

2. Define the exact `Memba.Messaging.send_club_message/2` result contract after this change, including:
   - successful domain dispatch and successful handoff,
   - successful domain dispatch and failed/partial handoff,
   - failed domain dispatch before commit.

3. Define the retry/idempotency rule in concrete terms, including what uniquely identifies one recipient delivery handoff, likely `email_delivery_id`.

4. Define where handoff state/failure is observable:
   - structured return only,
   - existing read model,
   - new internal read model/table,
   - or another named mechanism.

5. Update acceptance criteria to match those decisions with concrete expected state changes and return values.

## Validation plan

Success should be proven by:

1. Targeted automated tests showing `send_club_message/2` no longer reports the committed message-domain send as failed merely because provider handoff failed afterward.

2. Tests proving the named handoff collaborator handles:
   - all-recipient success,
   - provider failure before any accepted recipient,
   - provider failure after at least one accepted recipient,
   - retry/duplicate safety for an already-created delivery.

3. Tests proving inbound accepted club messages use the same outbound handoff boundary.

4. Verification that event/projector replay does not call provider code.

5. Verification that existing successful browser-composed and inbound-composed message flows still create message and delivery read models and still invoke the configured provider.

6. `dev check` passing after implementation.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":4,"codex_review_blocking_gaps":"Core handoff architecture undecided; Retry/idempotency mechanism unresolved; send_club_message/2 result contract not concrete; Observable handoff failure state not specified","codex_review_required_edits":"Choose synchronous collaborator vs persisted handoff/outbox design; Define exact send_club_message/2 result contract; Define retry/idempotency rule keyed by delivery; Define where handoff state/failure is observable; Update acceptance criteria with concrete state changes and return values"}}