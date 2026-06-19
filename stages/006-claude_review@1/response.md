# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
**ACCEPT**

## Confidence
**High**

## ADR Conformance
**PASS**

---

## ADR Violations
None.

The implementation correctly applies event sourcing patterns for deprecating events while maintaining replay safety. No ADRs governing CQRS, event sourcing, domain modeling, or Commanded architecture were violated.

---

## Blocking Issues
None.

---

## Bounded-Safe Fixes
None.

The implementation is clean, complete, and requires no refactoring.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

### 1. Event Deprecation Pattern Documentation
**Files**: `docs/adr/` (absence of ADR)  
**Smell**: The event tombstone + no-op handler pattern is well-executed here but undocumented as a project-wide standard.  
**Why judgement-worthy**: If this pattern recurs (e.g., deprecating other event types like `MessageScheduled` or `MemberInvitationExpired`), contributors would benefit from a documented ADR establishing the canonical approach. The current implementation provides an excellent reference example, but an ADR would codify:
- When to use tombstones vs. event versioning
- Required documentation in no-op clauses
- Regression test requirements for replay safety
- Criteria for eventually removing tombstones

This is non-blocking because the current implementation is sound and self-documenting, but a future ADR could prevent inconsistent approaches if other events need deprecation.

### 2. Potential Metrics/Logging References
**Files**: Not in scope, but potentially `lib/memba/messaging/` telemetry or logging modules  
**Smell**: The iteration cleaned up code and tests, but production metrics, logs, or telemetry dashboards might still reference "opened" as a tracked status.  
**Why judgement-worthy**: If metrics or structured logs still emit "opened" counts/events, they create misleading operational signals. However, this is out of scope for a code-focused iteration and would require operational access to verify. A follow-up kaizen task could audit telemetry/logging for deprecated status references across all messaging delivery statuses.

### 3. Future Tombstone Removal Criteria
**Files**: Plan follow-ups, `lib/memba/messaging/events/email_delivery_opened.ex`  
**Smell**: The plan correctly notes that the shim could be removed if production contains zero historic `EmailDeliveryOpened` events, but doesn't establish a process for verifying this or scheduling tombstone cleanup.  
**Why judgement-worthy**: Without a defined verification approach, tombstones accumulate indefinitely. A future iteration could:
- Query production event store for event type counts
- Establish a retention policy (e.g., "remove tombstones for events older than 2 years with zero occurrences")
- Create a standard verification script for safe tombstone removal

This is non-blocking because preserving the tombstone is always safe, but unbounded tombstone accumulation is a maintainability smell.

---

## Suggested Fixes
None required. The implementation is correct and complete as-is.

---

## Validation Notes

### Tests Validating Plan Acceptance Criteria

1. **Regression test for historic event replay**: `test/memba/messaging/email_delivery_opened_replay_test.exs`
   - Persists historic `EmailDeliveryOpened` event
   - Rebuilds both `MemberDeliveryProjector` and `StaffDeliveryProjector`
   - Validates no side effects (empty projection tables)
   - Tests aggregate state (no-op application)
   - **Status**: Comprehensive, passing

2. **No "opened" assertions in tests**: Evidence shows removal from:
   - `test/memba/messaging/messaging_test.exs` (normalize status tests)
   - `test/memba_web/controllers/webhook_controller_test.exs` (rejection branch)
   - Acceptance step definitions and support files
   - **Status**: Complete

3. **Shim documentation**: All retained components include deprecation comments:
   - `EmailDeliveryOpened` event module (tombstone)
   - `Message` aggregate `apply/2` clause
   - Both projector `project/2` clauses
   - **Status**: Clear and consistent

4. **dev check**: Passed with all tests green, including new regression test
   - 82 acceptance scenarios passed
   - All ExUnit suites passed
   - **Status**: Green

### Structural Evidence

**Command removal**: `ReportEmailDeliveryOpened` deleted entirely. Router registration would cause compilation error if not removed; dev check passes confirm clean removal.

**Read model cleanup**: `Memba.Messaging.normalize_delivery_status/1` no longer maps `"opened"` to `"delivered"`.

**Webhook rejection**: `MembaWeb.WebhookController` no longer rejects `"opened"` events (branch removed).

**UI surfaces**: No member/staff dashboard or diagnostic surfaces reference "opened" status (acceptance tests validate this behaviorally).

### Replay Safety Validation

The regression test actually exercises projection rebuilds (`rebuild_projection/1`), not just forward dispatch. This proves the no-op clauses work during real projection rebuild scenarios where historic events replay in order. This matches the plan's requirement that "the regression test must actually exercise a rebuild, not just a forward dispatch, to prove it."

---

## Summary

This is a textbook implementation of event deprecation in an event-sourced system. The tombstone pattern is correctly applied, documentation is clear and consistent, regression tests are thorough, and all active behavior referencing the deprecated status is cleanly removed. The three judgement-worthy items are forward-looking maintainability considerations, not defects in this iteration's scope.

The implementation satisfies all plan acceptance criteria, passes dev check, follows event sourcing best practices, and introduces no technical debt. Recommended for merge without changes.