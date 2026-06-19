# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
**ACCEPT**

## Confidence
**High**

## ADR Conformance
**PASS**

The implementation follows sound event sourcing, CQRS, and DDD patterns:

- **Event immutability**: Historic events preserved via tombstone struct
- **Deserialization safety**: Event module retained for EventStore replay capability  
- **Replay safety**: Aggregate and projectors provide explicit no-op handling
- **Command lifecycle**: Dead command cleanly removed from write side
- **Read model consistency**: Status removed from query side normalization and presentation
- **Domain clarity**: Deprecated status has no domain behavior, only backward-compatibility infrastructure

The tombstoning pattern is textbook-correct for event-sourced systems where you cannot delete historic events but need to stop processing a deprecated event type.

## ADR Violations
None.

## Blocking Issues
None.

## Bounded-Safe Fixes
None needed. The implementation is clean, complete, and maintainable as-is.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Potential event store cleanup opportunity** (optimization, not correctness)
   - **Files**: `lib/memba/messaging/events/email_delivery_opened.ex`, aggregate and projector no-op clauses
   - **Smell**: The tombstone and replay-safety shim add permanent maintenance surface for a deprecated feature
   - **Why human judgement needed**: 
     - Requires production event store analysis to confirm zero `EmailDeliveryOpened` events exist
     - Needs decision on whether operational cost of maintaining the shim outweighs re-introduction risk
     - Depends on event retention policy and replay frequency
   - **Current state**: Safe and well-documented. The tombstone is cheap to maintain, has excellent deprecation notices, and poses no correctness risk.
   - **Potential future action**: If production proves zero historic instances exist and policy ensures none will be replayed, a future iteration could remove the entire shim (event struct + no-op handlers) and close this technical debt. The plan explicitly defers this decision.
   - **Not blocking**: The code is clean, the documentation is clear ("DO NOT REMOVE"), and the pattern is standard. This is optimization territory, not a quality issue.

## Suggested Fixes
None. The implementation is ready to merge.

## Validation Notes

### Test Coverage
✅ **Replay safety test is comprehensive**:
- Persists a real historic `EmailDeliveryOpened` event to the EventStore
- Rebuilds all projections from scratch (not just forward-dispatch)
- Asserts read models remain valid after rebuild
- Proves deserialization + aggregate + projectors all handle the deprecated event safely

✅ **Existing test suites updated**:
- All "opened" assertions removed from ExUnit tests
- Acceptance tests unchanged (correct - they're domain specs, not implementation specs)
- No test failures from removing the status

### Implementation Evidence
✅ **Tombstone pattern correctly applied**:
- Event struct remains with `@derive Jason.Encoder` for deserialization
- Module documentation clearly explains it's DEPRECATED and DO NOT REMOVE
- No business logic, just structure

✅ **No-op handlers consistent**:
- Aggregate: `apply(%EmailDelivery{}, %EmailDeliveryOpened{})` returns delivery unchanged
- Both projectors: `project(%EmailDeliveryOpened{}, _, %{email_delivery_id: _})` returns `:ok`
- All handlers include inline comment "Historic event: no-op for replay safety"

✅ **Active behavior removed**:
- `ReportEmailDeliveryOpened` command deleted
- Read-model `normalize_delivery_status/1` no longer has "opened" clause
- No "opened" → "delivered" presentation mapping
- Webhook rejection branch removed (implied by passing tests)

✅ **Grep verification**:
- Only remaining `opened`/`Opened` references in `lib/` are the documented shim
- Test files only reference it in the replay safety test
- No stray references in UI, contexts, or business logic

### Dev Check Results
✅ All stages passed:
- 82 acceptance scenarios (493 steps) passed
- Zero compiler warnings
- Zero Credo issues
- Zero formatter issues
- Clean Dialyzer run
- Sandbox runtime check passed

### Code Quality
**Strengths**:
- Excellent module documentation on the tombstone event explaining deprecation and warning against removal
- Consistent no-op pattern across aggregate and both projectors
- Clean removal of all active "opened" behavior with no leftover branches
- Comprehensive replay safety test that proves the shim works
- No scope creep - implementation matches plan exactly

**Maintainability**: High. The next developer will immediately understand:
- Why the event struct exists (clear deprecation doc)
- That it's a tombstone, not active code (DO NOT REMOVE warning)
- How to handle similar deprecations in future (pattern established)

## Summary

This is a textbook-correct implementation of event sourcing tombstoning. The developer:

1. Preserved event deserialization capability for historic events (correct)
2. Added explicit no-op handlers to prevent replay crashes (correct)
3. Removed all active behavior cleanly (correct)
4. Documented the deprecation clearly to prevent future confusion (excellent)
5. Proved replay safety with a comprehensive rebuild test (thorough)
6. Stayed within scope and delivered exactly what the plan specified (disciplined)

The code is production-ready, maintainable, and safe. The single judgement-worthy finding is an optimization opportunity (event store cleanup) that the plan explicitly deferred, not a quality issue.

**Recommendation**: Merge with confidence.