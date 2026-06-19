# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
**ACCEPT**

## Confidence
**High**

## ADR conformance
**PASS**

The implementation conforms fully to the project's event-sourcing and CQRS architecture rules:
- **Event Immutability:** Historic `EmailDeliveryOpened` events are preserved as immutable facts using a tombstone struct, adhering to append-only semantics.
- **Replay Safety:** Explicit no-op clauses in the aggregate and projectors ensure that any past instances of the event will not crash projection rebuilds.
- **CQRS Separation:** The write-side command and its dispatch logic are removed, and the read-side read-model normalizations are independently cleaned up.

## ADR violations
None.

## Blocking issues
None. 

*(Note: The failure in the `verify_review_repair` pipeline stage was caused by a false-positive synthesized review blocker `broaden-opened-projector-noops`. The projector no-op clauses were already maximally broad (`project(%EmailDeliveryOpened{}, fn multi -> multi end)`). The repair agent correctly identified that no changes were needed, resulting in an empty diff. This is a pipeline workflow limitation when handling false positives, not an implementation flaw.)*

## Bounded-safe fixes
None. 

## Judgement-worthy non-blocking code-health findings

1. **Test-suite coupling to Commanded/EventStore internals**
   - **Files:** The new replay-safety regression test for `EmailDeliveryOpened`.
   - **Smell:** The test directly manipulates internal EventStore and projection tables using raw SQL (e.g., `TRUNCATE TABLE snapshots, subscriptions, stream_events...`).
   - **Why it may need human judgement:** Testing projection rebuilds is extremely valuable, and doing so here proves the central risk of the iteration is mitigated. However, this tightly couples the test suite to underlying library schema internals. If replay/rebuild tests become a recurring pattern, the project should centralize these destructive reset operations into a dedicated test-support module to isolate fragility.

2. **Permanent maintenance surface for a deprecated feature**
   - **Files:** `EmailDeliveryOpened` event module, Aggregate no-op clause, Projector no-op clauses.
   - **Smell:** The codebase must forever carry this event's structure and empty handling to satisfy the event store's append-only nature.
   - **Why it may need human judgement:** This is the strictly correct event-sourcing implementation. As the plan notes, if a future operational audit confirms zero instances of `EmailDeliveryOpened` were ever appended in the production database, the team could safely delete these tombstones. This decision is appropriately deferred.

## Suggested fixes
None. The code is production-ready.

## Validation notes
- `dev ci` / `dev check` passed successfully before repair.
- The `opened` status was cleanly removed from all boundaries (Webhooks, Commands, Normalization, UI).
- A robust integration test proves that historical events are safely handled: the system can parse the event from the database, the aggregate does not mutate state, and projectors do not crash upon encountering it during a full rebuild.
- The repair pass correctly applied zero changes, confirming the initial implementation already satisfied the requested constraints.