# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
**ACCEPT**

## Confidence
**High**

## ADR conformance
**PASS**

The implementation correctly follows event-sourcing and CQRS architectural patterns required by Memba's accepted ADRs:

- **Event immutability**: Historic `EmailDeliveryOpened` events preserved as immutable facts via tombstone struct rather than deleted or renamed
- **Replay safety**: Aggregate and projectors provide explicit no-op handling to prevent projection rebuild failures
- **CQRS separation**: Write-side command cleanly removed; read-side normalization and presentation removed independently
- **Domain clarity**: Deprecated status has no active behavior, only backward-compatibility infrastructure

The tombstoning pattern is the standard event-sourcing solution when you cannot delete historic events but need to stop processing a deprecated event type. This matches the reference guidance in `docs/reference/event-sourcing.md` and `docs/reference/cqrs.md`.

## ADR violations
None.

## Blocking issues
None.

The synthesized review blocker `broaden-opened-projector-noops` was based on speculation that projector no-op clauses might constrain metadata shape. Investigation during repair proved this speculation was incorrect:

**Actual projector clauses** (both projectors):
```elixir
# Historic event: no-op for replay safety.
project(%EmailDeliveryOpened{}, fn multi -> multi end)
```

These are already maximally broad - they match only the event struct, not metadata. No broadening needed. The repair agent correctly identified this and made no changes.

The `verify_review_repair` stage failure is a **pipeline design issue** (expects either working-tree changes or explicit human routing when no changes are needed), not an implementation quality issue.

## Bounded-safe fixes
None needed. The code is already in the desired state.

## Judgement-worthy non-blocking code-health findings

1. **Permanent tombstone maintenance surface**
   - **Files**: `lib/memba/messaging/events/email_delivery_opened.ex`, aggregate no-op clause, projector no-op clauses
   - **Smell**: The codebase must permanently carry this event's structure and empty handling to satisfy the event store's append-only nature
   - **Why it may need human judgement**: This is the correct event-sourcing implementation. However, if a future operational audit confirms zero instances of `EmailDeliveryOpened` were ever appended in production, the team could safely delete these tombstones. The plan explicitly defers this decision.
   - **Current state**: Safe, well-documented ("DO NOT REMOVE"), and poses no correctness risk. This is a maintenance optimization opportunity, not a quality issue.

2. **Replay test manipulates EventStore/projection internals**
   - **Files**: The replay-safety regression test containing `reset_event_store!/1`, `reset_projection_tables!/1`, and rebuild orchestration
   - **Smell**: Direct manipulation of EventStore tables, projection tables, subscriptions, and schemas using raw SQL
   - **Why it may need human judgement**: This is appropriate for a replay-safety regression test, but if similar tests accumulate, the project may want a shared, well-named test helper module for "historic event replay/rebuild" scenarios to reduce duplication and isolate fragile knowledge of EventStore internals.
   - **Current state**: Valuable and proves the important risk that historic `EmailDeliveryOpened` events do not break projection rebuilds. Not blocking.

## Suggested fixes
None. The implementation is production-ready.

## Validation notes

### Plan Fidelity
✅ The plan-conformance gate already passed. Independent sanity check confirms:
- Command removed from write side
- Read-model normalization removed
- Presentation mapping removed
- Webhook rejection branch removed
- Aggregate/projector reduced to documented no-ops
- Event struct retained as deserialization tombstone
- Tests updated to remove "opened" assertions
- Replay regression added
- No scope creep

### ADR Evidence
✅ Event sourcing pattern correctly applied:
- Historic events immutable (tombstone pattern, not deletion)
- Replay safety proven by rebuild test
- Clean CQRS separation (write/read sides independent)
- Clear deprecation documentation

### Test Coverage
✅ Dev check passed: 82 scenarios, 493 steps
✅ Comprehensive replay safety test:
- Persists real historic event to EventStore
- Rebuilds all projections from scratch (not just forward dispatch)
- Asserts read models remain valid after rebuild
- Proves deserialization + aggregate + projectors all safe

✅ Existing test suites updated:
- All "opened" assertions removed from ExUnit tests
- Acceptance feature files unchanged (correct - domain specs, not implementation specs)
- No test failures from removing status

### Code Quality
**Strengths**:
- Excellent module documentation on tombstone event with clear deprecation warning
- Consistent no-op pattern across aggregate and both projectors
- Clean removal of all active "opened" behavior
- Comprehensive replay safety test
- No scope creep - matches plan exactly

**Projector no-op clauses are already maximally broad**:
```elixir
project(%EmailDeliveryOpened{}, fn multi -> multi end)
```
This matches only the event struct, not metadata. Contrary to the synthesized review speculation, there is no `%{email_delivery_id: _}` or other metadata constraint to broaden.

**Maintainability**: High. Clear documentation makes deprecation intent obvious. Pattern established for future similar deprecations.

### Pipeline Note
The `verify_review_repair` stage failed because:
1. Synthesized review created blocker based on speculation about metadata constraints
2. Repair agent investigated and correctly determined no changes needed
3. Verify stage expected either working-tree diff or explicit human routing

This is a pipeline workflow gap, not an implementation issue. The implementation is correct and complete.

## Summary

This is a textbook-correct implementation of event-sourcing tombstoning:
1. ✅ Preserved event deserialization capability for historic events
2. ✅ Added explicit no-op handlers to prevent replay crashes (already maximally broad)
3. ✅ Removed all active behavior cleanly
4. ✅ Documented deprecation clearly to prevent future confusion
5. ✅ Proved replay safety with comprehensive rebuild test
6. ✅ Stayed within scope and delivered exactly what the plan specified

The code is production-ready, maintainable, safe, and ADR-conformant. The two judgement-worthy findings are optimization opportunities (event store cleanup, test helper extraction) that the plan appropriately deferred, not quality issues.

**Recommendation**: Accept and merge. The verify_review_repair failure is a false positive caused by correct "no changes needed" determination during repair.