# Iteration Review Report: 035 — Obliterate Opened Delivery Status

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation is consistent with the project’s event-sourcing/CQRS direction and the domain-design guidance relevant to this slice:

- Historic events are preserved as immutable facts rather than deleted or renamed.
- `EmailDeliveryOpened` remains only as a replay/deserialization tombstone.
- Aggregate/projector handling is reduced to explicit replay-safe no-ops.
- The active command, webhook branch, read-model normalization, and presentation mapping for `"opened"` are removed.
- The new regression coverage exercises replay/rebuild behaviour rather than only forward command dispatch.

No evidence suggests the implementation replaced ADR-mandated Commanded/EventStore infrastructure with local substitutes or bypassed projection/read-model boundaries.

## ADR violations

None identified.

## Blocking issues

None.

## Bounded-safe fixes

1. **Consider making replay-only no-op projector clauses maximally broad**
   - **Files:** the projector modules retaining `EmailDeliveryOpened` no-op clauses.
   - **Issue:** If the no-op clauses still pattern-match on metadata shape such as `%{email_delivery_id: _}`, that is slightly narrower than the intent of a tombstone replay shim.
   - **Why safe:** The event is deprecated and should have no behaviour regardless of metadata. Matching `_metadata` would make the replay shim more robust against older or malformed historic metadata without changing product behaviour.
   - **Suggested change:** Prefer heads equivalent to:

     ```elixir
     # Historic event retained for replay only; intentionally ignored.
     def project(%EmailDeliveryOpened{}, _metadata, _context_or_multi) do
       :ok
     end
     ```

     or the project’s equivalent projector callback shape.

   - **Not blocking:** The current implementation passed the replay regression and full `dev check`; this is defensive polish only.

## Judgement-worthy non-blocking code-health findings

1. **Replay regression test reaches into EventStore/projection internals**
   - **Files:** the new replay-safety regression test containing helpers such as `reset_event_store!/1`, `reset_projection_tables!/1`, and projector rebuild orchestration.
   - **Smell:** The test necessarily manipulates EventStore tables, projection tables, subscriptions, schemas, and rebuild mechanics directly.
   - **Why it may need human judgement:** This is appropriate for a replay-safety regression, but if similar tests accumulate, the project may want a shared, well-named test helper for “historic event replay/rebuild” scenarios. Otherwise, future tests may duplicate fragile knowledge of EventStore table names and reset semantics.
   - **Not blocking:** For this iteration, the test is valuable and proves the important risk: historic `EmailDeliveryOpened` events do not break projection rebuilds or mutate read models.

2. **Permanent tombstone surface remains by design**
   - **Files:**
     - `lib/memba/messaging/events/email_delivery_opened.ex`
     - aggregate no-op clause for `EmailDeliveryOpened`
     - projector no-op clauses for `EmailDeliveryOpened`
   - **Smell:** The codebase retains a deprecated event module and replay-only handlers for a status that no longer exists as product behaviour.
   - **Why it may need human judgement:** Removing this later would require operational confidence that no production event store contains `EmailDeliveryOpened` events, plus an explicit decision about replay compatibility. Until then, the tombstone is the correct event-sourcing tradeoff.
   - **Not blocking:** The comments and no-op implementation make the intent clear, and this exactly matches the iteration plan.

## Suggested fixes

Only optional bounded-safe polish:

1. If any `EmailDeliveryOpened` no-op projector clause unnecessarily constrains metadata, loosen it to ignore all metadata.
2. If replay/rebuild regression tests become common, extract the EventStore/projection reset and rebuild helpers into a shared test-support module with a name that makes the destructive test-only behaviour explicit.

## Validation notes

- `dev ci` completed successfully.
- Acceptance suite passed: **82 scenarios / 493 steps**.
- The implementation evidence shows the active `"opened"` delivery behaviour was removed:
  - deleted `ReportEmailDeliveryOpened` command path,
  - removed read-model `"opened"` normalization,
  - removed `"opened" -> "delivered"` presentation mapping,
  - removed webhook `"opened"` rejection branch,
  - removed UI/test assertions that treated `"opened"` as an active status.
- Historic replay safety is covered by a regression test that persists/replays `EmailDeliveryOpened` and rebuilds projections.
- Remaining `opened`/`Opened` references appear limited to the documented replay-only shim and intentional regression coverage.
- Acceptance feature files appear to remain domain-focused rather than being updated as implementation specs, which is appropriate for this cleanup slice.