# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
ACCEPT

## Confidence
High

## ADR conformance
PASS

The implementation correctly honors the project's Event Sourcing and CQRS architecture constraints:
- **Immutability of Historic Data**: Rather than attempting to delete or alter historic events, `EmailDeliveryOpened` is preserved as a structurally valid, documented tombstone.
- **Replay Safety**: The aggregate and projectors gracefully ignore the deprecated event via explicit no-op clauses, ensuring projection rebuilds succeed without failing on unhandled events.
- **Read/Write Segregation**: The active command (`ReportEmailDeliveryOpened`) was entirely removed from the write model, and downstream normalization was removed from the read model.

## ADR violations
None identified.

## Blocking issues
None.

## Bounded-safe fixes
1. **Ensure maximally broad pattern matching on no-op projector clauses**
   - If the newly added projector no-op clauses for `EmailDeliveryOpened` still match on a specific metadata shape (e.g., `%{email_delivery_id: _}`), loosen them to `_metadata`. This ensures robust replay even if historic events have missing or malformed metadata, as the payload is being ignored anyway.

## Judgement-worthy non-blocking code-health findings
1. **Test-suite coupling to Commanded/EventStore database internals**
   - **Files**: Replay-safety regression test (evidence shows `reset_event_store!/1`, `reset_projection_tables!/1` with raw SQL `TRUNCATE` commands).
   - **Smell**: The test directly manipulates internal EventStore and projection tables using raw SQL (e.g., `TRUNCATE TABLE snapshots, subscriptions, stream_events...`).
   - **Why it needs human judgement**: Testing projection rebuilds is highly valuable, but raw SQL manipulation tightly couples the test suite to the underlying library's schema internals. If these replay/rebuild tests become a recurring pattern, the project should centralize these destructive reset operations into a dedicated, well-named test-support module to isolate this fragility. 

2. **Permanent maintenance surface for a deprecated feature**
   - **Files**: `EmailDeliveryOpened` event module, Aggregate no-op clause, Projector no-op clauses.
   - **Smell**: The codebase must forever carry this event's structure and empty handling to satisfy the event store's append-only nature.
   - **Why it needs human judgement**: This is the correct, safe event-sourcing implementation. However, if a future operational audit confirms zero instances of `EmailDeliveryOpened` were ever appended in production, the team could safely delete these tombstones. This is appropriately deferred by the current plan.

## Suggested fixes
- (Optional Polish) Review projector `project(%EmailDeliveryOpened{}, metadata, ...)` heads and replace specific map pattern matches on `metadata` with `_metadata` or `_` to guarantee maximum replay resilience.

## Validation notes
- `dev check` successfully completed (82 scenarios, 493 steps).
- The removal of the `opened` status was handled cleanly at all boundaries: Webhook handlers, Write API (Commands), Read Model (Normalization), and Presentation (UI strings/mapping).
- A robust integration test proves that historical events are safely handled: the system can parse the event from the database, the aggregate does not mutate state, and projectors do not crash upon encountering it during a full rebuild.
- Acceptance criteria are met, and domain feature files appropriately remain un-altered implementation specs.