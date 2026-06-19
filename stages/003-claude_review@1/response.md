Now I'll evaluate the plan against the readiness criteria and provide a comprehensive review.

---

# Iteration 038 Plan Review: Email Delivery Handoff Boundary

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Handoff result contract unresolved**: Acceptance criteria require "`send_club_message/2` has a clear result contract" but the plan leaves the exact result structure (`:ok` vs. `{:ok, message_id}` vs. `{:ok, %{message_id: ..., handoff: ...}}`) unspecified. Step 4 says "adjust so dispatch and handoff results are not conflated" and mentions "caller should know message_id/dispatch result even when handoff fails," but does not commit to the concrete shape. Without this, the implementation could wander between incompatible options.

2. **Handoff boundary architectural pattern unresolved**: Open Technical Decisions leaves the core boundary design choice unresolved (synchronous collaborator vs. persisted outbox/handoff table). This is not a minor detail—it fundamentally affects modules, tests, migrations, and retry semantics. The acceptance criteria require "provider handoff failures are observable and testable" and "safe duplicate/retry," but those constraints differ significantly between a synchronous-only collaborator and a persisted outbox. Without choosing, step 2 "define the smallest explicit handoff contract" cannot be concretely implemented.

3. **Idempotency/duplicate-prevention strategy unresolved**: The plan acknowledges duplicate emails as a risk and lists "duplicate/retry safety" in acceptance criteria, but leaves the implementation strategy open: "if provider adapter lacks idempotency, record enough local state." This is a critical branching point. The plan should state whether Memba will rely on provider-level idempotency keys (and which providers support them), add a local sent-attempt table, or use another mechanism. Without this decision, step 6 cannot be implemented deterministically.

4. **Handoff-failure representation unresolved**: Open Technical Decisions asks "whether handoff failure should update an existing read model or a new internal operational read model" and notes the desire to avoid "overloading recipient delivery status." The acceptance criteria require "provider handoff failures are observable and testable" but do not specify how. Should failures surface in the `email_deliveries` projection, a new `email_handoff_attempts` table, an in-memory result only, or elsewhere? This decision affects migration planning, query contracts, and observability.

5. **Partial-recipient-failure semantics undefined**: Acceptance criteria require "provider failure for one recipient cannot cause silent ambiguity about earlier recipients" and tests for "provider failure after at least one recipient has been accepted," but the plan does not specify what should happen in this case. Should the system:
   - Return partial success with per-recipient status?
   - Retry only failed recipients?
   - Fail the entire handoff and retry all recipients later?
   - Surface partial success in a new data structure?
   
   Without this decision, the "structured handoff result" in step 2 cannot be concretely designed.

## Non-Blocking Improvements

1. **Inbound acceptance integration could be more specific**: Step 7 says "route inbound accepted club messages through the same handoff contract" but does not name the caller module/function (likely in `Memba.Messaging.InboundEmail` or similar). Adding a line like "adjust `Memba.Messaging.InboundEmail.accept_club_message/2` or similar caller" would make the plan more concrete without changing scope.

2. **Migration planning omitted**: If the chosen boundary design includes a persisted outbox/handoff table (one of the open options), a migration will be required. The implementation plan could note "if persisted boundary chosen, create migration for handoff state table" in step 5 or as a conditional substep.

3. **Provider-specific idempotency key support could be researched ahead**: The plan mentions "whether provider adapters already expose enough idempotency key support" but does not propose a pre-implementation research task. Adding a step 0 or 1.5 to "check Postmark/Resend adapter and API docs for idempotency key support" would reduce mid-implementation uncertainty.

## Smallest Viable Iteration

The current scope is already focused and appropriate. The smallest viable slice within this plan would be:

**Email handoff boundary with synchronous-only, single-transaction retry semantics**:
- Extract a `Memba.Messaging.EmailDeliveryHandoff` module that accepts message/delivery data and calls the provider synchronously.
- Return `{:ok, message_id, handoff_results}` from `send_club_message/2` where `handoff_results` is a list of `{delivery_id, :sent | {:failed, reason}}`.
- Do not add a persisted outbox table; rely on caller retry or accept that mid-send failures are reported but not automatically retried.
- Use provider-level idempotency keys if available; otherwise, document that duplicate handoff calls may send duplicate emails (deferring duplicate prevention to a later iteration with persisted state).

However, this smaller slice may not satisfy the acceptance criterion "retrying handoff does not create duplicate EmailDeliveryCreated events" if retries are invoked by replaying the entire `send_club_message/2` call. The plan should clarify whether "retry" means command replay (which would replay events) or handoff-only retry (which requires persisted handoff state or idempotent provider keys).

## Required Plan Edits

1. **Resolve handoff result contract**: In the Implementation Plan or a new "Design Decisions" section, specify the exact return shape for `send_club_message/2`. Example: `{:ok, %{message_id: String.t(), handoff: [%{delivery_id: String.t(), status: :sent | {:failed, reason}}]}}` or similar. State what callers should do with handoff failures.

2. **Choose handoff boundary pattern**: Decide between synchronous collaborator vs. persisted outbox/handoff table and document the choice. If persisted, add migration planning to the implementation steps. If synchronous-only, clarify retry semantics (caller retries entire command vs. no automatic retry).

3. **Specify idempotency/duplicate-prevention mechanism**: State whether Memba will use provider idempotency keys (and confirm which providers support them), add a local handoff-attempt table, or defer duplicate prevention to a future iteration. Add this decision to the plan and remove the corresponding open question.

4. **Define handoff-failure representation**: State whether handoff failures will be recorded in a new table, surfaced only in the command result, or reflected in the existing `email_deliveries` projection with a new status/field. Remove the corresponding open question.

5. **Specify partial-recipient-failure behavior**: Clarify what happens when the provider accepts some recipients but rejects others. Should the handoff return per-recipient results? Should it fail entirely? Should it retry only failed recipients? Add this to the Acceptance Criteria or Implementation Plan.

6. **Clarify retry semantics vs. event replay**: In Acceptance Criteria or Implementation Plan, distinguish "retrying handoff" (re-attempting provider call for an existing delivery) from "retrying send_club_message" (replaying the domain command). State which kind of retry must not duplicate `EmailDeliveryCreated` events.

## Validation Plan

The existing validation plan is reasonable but should be augmented based on the resolved decisions:

- Run targeted tests for all acceptance criteria (already stated).
- Run `dev check` (already stated).
- Manually confirm message and delivery views populate (already stated).
- **Add**: Manually or through tests confirm partial-recipient-failure behavior matches the documented design.
- **Add**: If persisted handoff state is chosen, manually inspect the handoff table after a simulated failure to confirm retry can be triggered safely.
- **Add**: If provider idempotency keys are used, confirm keys are stable across retries and match the delivery ID or another stable identifier.

---

## Summary

The iteration has a clear technical goal and appropriate scope. The problem is well-motivated, and the acceptance criteria are comprehensive. However, **four critical design decisions remain unresolved** (result contract, boundary pattern, idempotency strategy, handoff-failure representation, partial-recipient behavior), leaving the implementation plan underspecified. Resolving these decisions and editing the plan accordingly will make it ready for implementation.

Once the blocking gaps are resolved, the plan will be concrete, bounded, and ready for deterministic implementation.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":5,"claude_review_blocking_gaps":"Handoff result contract unresolved; Handoff boundary pattern unresolved (sync vs. persisted outbox); Idempotency/duplicate-prevention strategy unresolved; Handoff-failure representation unresolved; Partial-recipient-failure semantics undefined","claude_review_required_edits":"Specify send_club_message/2 result contract; Choose sync collaborator vs. persisted outbox pattern; Decide idempotency mechanism (provider keys vs. local state); Define handoff-failure representation (new table vs. command result only); Specify partial-recipient-failure behavior; Clarify retry semantics vs. event replay"}}
```