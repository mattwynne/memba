# Iteration Review Report: 035-obliterate-opened-delivery-status

## Decision
**ACCEPT**

## Confidence
**High**

## ADR Conformance
**PASS**

## ADR Violations
None.

The implementation correctly adheres to event-sourcing and CQRS constraints. Persisted historical events (`EmailDeliveryOpened`) are retained as deserializable tombstones, and their aggregate and projector handlers are reduced to no-ops. This ensures that historical event streams remain replay-safe without retaining active domain behavior for a deprecated concept, conforming to immutable event stream principles.

## Blocking Issues
None. 

## Bounded-Safe Fixes
None. The implementation cleanly removes the active code while preserving necessary infrastructure for the tombstone event.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Formalizing the Event Tombstone Pattern**
   - **Files:** `lib/memba/messaging/events/email_delivery_opened.ex`, associated aggregate/projector no-op clauses, and `docs/adr/`.
   - **Smell:** The project has successfully executed a safe event deprecation pattern (tombstone event struct + no-op aggregate clause + no-op projector clauses + projection rebuild regression test). However, this pattern currently lives only as implementation knowledge in this specific iteration.
   - **Why it may need human judgement:** If other events are deprecated in the future, developers might attempt to delete them entirely or handle them inconsistently. Establishing an ADR or adding a section to `docs/reference/event-sourcing.md` detailing the "Event Deprecation / Tombstone" standard would prevent future drift.

2. **Low-level Projection Rebuild Test Helpers**
   - **Files:** `test/memba/messaging/email_delivery_opened_replay_test.exs` (and associated test helpers).
   - **Smell:** To test replay safety, the regression test relies on low-level Postgres truncations (`reset_event_store!`, `reset_projection_tables!`) and mapping projectors to Commanded apps (`projector_commanded_app/1`).
   - **Why it may need human judgement:** While perfectly appropriate and necessary for verifying this iteration's specific replay risk, these low-level interactions are highly coupled to Commanded and EventStore internals. If the project requires more projection-rebuild regression tests in the future, this code should be extracted into a formal `Memba.EventStoreTestHarness` or similar shared support module.

3. **Indefinite Tombstone Retention**
   - **Files:** `lib/memba/messaging/events/email_delivery_opened.ex`
   - **Smell:** The tombstone is retained safely, but there is no operational trigger defined to ever remove it.
   - **Why it may need human judgement:** A future technical chore could involve querying the production event store to confirm if `EmailDeliveryOpened` events actually exist. If the count is zero, the shim can be safely deleted. Deciding whether to automate this check or leave the tombstone permanently is an architecture/operations decision.

## Suggested Fixes
None required before merge.

Optional future follow-ups:
- Document the "Event Tombstone" pattern in the project's event-sourcing reference documentation.
- Extract the projection rebuild test helpers into a shared test support module if future replay tests are added.

## Validation Notes
- **Test Suite:** The `dev ci` pipeline executed successfully. All 82 acceptance scenarios passed, confirming that the removal of the "opened" status did not break existing delivery workflows or UI surfaces.
- **Regression Test:** The specific inclusion of a replay test that leverages `reset_event_store!` and forces a projection rebuild validates the critical path constraint: ensuring the system can process historical `EmailDeliveryOpened` events without crashing or affecting read models.
- **Structural Integrity:** `ReportEmailDeliveryOpened` and its routing are entirely removed. Active logic normalizing `"opened"` to `"delivered"` was safely excised without leaving dangling references. All retained pieces are properly documented as shims.