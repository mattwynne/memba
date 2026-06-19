Now I'll review this plan against the five readiness questions and provide a structured assessment.

---

# Iteration 038 Plan Review: Async Email Delivery Dispatch

**Decision**: READY

**Confidence**: High

---

## Blocking Gaps

None.

---

## Non-blocking Improvements

1. **Database schema migration callout**: While implementation step 2 mentions updating the EmailDelivery projection/read model to store dispatch diagnostics, consider explicitly noting whether this requires a migration or schema change before starting work.

2. **Concurrent dispatcher invocation**: Step 6 mentions claiming logic to avoid two dispatcher invocations claiming the same pending delivery concurrently, but doesn't specify the mechanism (optimistic locking, database-level constraint, GenServer serialization). This is resolvable during implementation but could be clearer upfront.

3. **Partial delivery presentation**: Acceptance criteria mention that member-facing views should not expose raw infrastructure failure details, but don't specify what members *should* see when some recipients succeed and others are still pending/failed. This is a minor copy/UX decision that can be resolved during implementation.

---

## Assessment Against Readiness Questions

### 1. Goal Clarity ✓
- **Clear goal**: Make email delivery dispatch explicit, async, observable, and retryable without blocking user-facing commands on provider availability.
- **User/business outcome**: Operators get observable dispatch lifecycle; users get reliable message acceptance even during provider outages.
- **Beneficiary**: Operators (immediate observability/retry), users (indirect reliability).

### 2. Scope Focus ✓
- **Coherent outcome**: One clear architectural slice—moving provider dispatch out of command handlers into async dispatcher.
- **Minimal useful slice**: Yes. Could not be smaller while remaining useful. Specifically excludes automatic retry, UI polish, event renaming, and broader application-service refactoring.
- **Boundaries clear**: Extensive in-scope/out-of-scope lists. Deliberately leaves deprecated `opened` status, staff retry UI, automatic retry scheduling, and event vocabulary migration for later work.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓
- **Concrete and testable**: 18 specific acceptance criteria covering happy paths (pending→dispatching→sent), error paths (failed deliveries with diagnostics), partial failures, manual retry, inbound messages, and test coverage requirements.
- **Edge cases**: Covers provider failure, partial recipient failure, concurrent dispatch prevention, replay safety, manual retry without duplicate events.
- **Iteration type classification**: Explicitly classified as "Technical/engineering" with clear rationale.
- **BDD/Gherkin decision**: "Not applicable" with explicit reasoning—internal architectural slice with no new business rule. States that existing acceptance scenarios should continue to pass and that ExUnit tests will provide coverage.
- **Business decisions resolved**: "None known." No unresolved copy, workflow, or domain policy questions.

### 4. Implementation Plan and Technical Decisions ✓
- **Clear steps**: 14 ordered implementation steps from inspection through testing and `dev check`.
- **Named artifacts**: Mentions specific modules (`Memba.Messaging.send_club_message/2`, `EmailDeliveryDispatcher`, `Memba.Messaging.Projectors.EmailDelivery`), infrastructure (`Memba.ReadModelChanges` PubSub topic), and test seams (fake/Postmark/Resend providers).
- **Changes specified**: Data model (add dispatch diagnostics), API (remove synchronous provider calls), background processing (supervised dispatcher), integration (PubSub subscription).
- **Technical decisions resolved**: "None known." Plan explicitly lists the five previously-open design choices that are now decided.

### 5. Expected Capability and Validation ✓
- **New capability**: Observable async dispatch lifecycle with manual retry; provider outages become failed deliveries instead of misleading command errors.
- **Stop condition**: Clear—when acceptance criteria pass, `dev check` passes, and manual inspection confirms async dispatch flow.
- **Validation plan**: Four-part validation including targeted tests, `dev check`, manual local inspection, and simulated provider failure.

---

## Smallest Viable Iteration

The plan already represents the smallest viable iteration. Any smaller slice would leave the system in an inconsistent state:

- Can't implement async dispatch without removing synchronous provider calls from commands.
- Can't make dispatch observable without the lifecycle states.
- Can't make dispatch retryable without attempt tracking and manual retry API.

The exclusions (automatic retry, staff UI, event renaming) are appropriate deferrals.

---

## Required Plan Edits

None. The plan is ready for implementation as written.

---

## Validation Plan

The stated validation plan is complete:

1. **Targeted tests during implementation**: Send, projection, dispatcher, providers, retry, inbound acceptance
2. **`dev check` before completion**: Required per project workflow
3. **Manual local inspection**: Confirm pending→dispatching→sent flow with fake provider
4. **Simulated failure testing**: Confirm failed deliveries, diagnostics, and manual retry

This provides adequate proof that:
- The command succeeds without provider dependency
- Dispatch lifecycle is truthful and observable
- Provider failures are per-delivery with retry capability
- Existing features continue working

---

## Conclusion

This is a well-scoped technical iteration with clear boundaries, concrete acceptance criteria, resolved decisions, and a practical implementation path. The plan acknowledges follow-up work (automatic retry, UI polish, stronger idempotency) without letting scope creep into this slice. The author has done excellent work preparing this for implementation.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}