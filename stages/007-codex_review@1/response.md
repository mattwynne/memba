# Iteration Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

1. None identified. The implementation evidence is consistent with the project’s accepted event-sourcing and CQRS direction: Commanded remains the write-side infrastructure, the Club aggregate owns group-membership state, lifecycle automation is implemented as a stateless event handler, current-state queries use rebuildable Ecto projections, and retained events remain the source for replay.

## Blocking issues

1. None identified.

## Bounded-safe fixes

1. None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Files:** `test/support/event_sourced_case.ex` and the event-sourced subscriber modules it enumerates  
   **Smell:** Projection rebuilding depends on explicit subscriber lists, direct supervision-tree inspection, aggregate-process termination, Commanded subscription resets, and EventStore checkpoint deletion.  
   **Why it may need human judgement:** This is appropriate test infrastructure for proving full replay, and the plan explicitly requires extending this helper. However, it is coupled to Commanded and supervisor internals. Future subscribers can be omitted silently unless every addition updates the helper. A later architectural decision could introduce a central subscriber registry or projection reset contract, but that would be broader than a safe polish change for this iteration.

2. **Files:** `Memba.Membership.Policies.SystemGroupMembership` and the Club aggregate command handlers used by it  
   **Smell:** Correctness spans an at-least-once event handler and idempotency implemented by the receiving aggregate rather than a transaction local to one process.  
   **Why it may need human judgement:** This is intentional and consistent with the plan’s event-sourced design, including replay from `:origin`. It does make aggregate idempotency a durable contract: future edits to the relevant commands must preserve duplicate-delivery safety. The invariant would benefit from continued explicit documentation and tests whenever these commands evolve.

3. **Files:** `Memba.Membership.SystemGroups.Backfill` and the release migration flow  
   **Smell:** Application-level event-sourced backfill is coupled to release migration ordering, application startup, read-model pagination, and command dispatch.  
   **Why it may need human judgement:** The coupling is mandated by the iteration plan and is preferable to manufacturing event-sourced state through SQL. It nevertheless increases operational complexity compared with ordinary schema migrations. Future backfills should reuse a clearly defined pattern rather than adding independently shaped release-time workflows.

## Suggested fixes

No changes are required for this iteration.

For future maintenance:

- Consider making the complete set of replayable subscribers discoverable through one registry or callback rather than duplicating it in replay-test infrastructure.
- Preserve focused duplicate-delivery tests whenever system-group commands or lifecycle policy subscriptions change.
- Keep release-backfill progress, failure, and retry behavior observable; avoid bypassing aggregates with direct projection writes.

## Validation notes

- The review started from a clean working tree.
- Sandbox/runtime validation passed.
- `dev ci` completed successfully on the reviewed committed state.
- The complete acceptance suite passed: **118 scenarios and 833 steps**.
- The implementation evidence includes the required projection-reset and subscriber-restart support for retained-event replay.
- The design retains the central architectural boundaries described by the plan:
  - Commanded aggregates and events remain authoritative.
  - The system-group policy is stateless and replayable from `:origin`.
  - Aggregate commands provide idempotency for replay and redelivery.
  - Group membership and conversation access are rebuildable current-state projections.
  - Existing installations are handled through the automatic release backfill rather than direct event-history fabrication.
- No evidence indicates that acceptance feature files were changed to weaken existing behavior.
