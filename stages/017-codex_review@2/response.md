# Iteration Review Report: 035 — Obliterate Opened Delivery Status

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation conforms to the relevant event-sourcing/CQRS expectations reflected in the plan and project guidance:

- Historic `EmailDeliveryOpened` events are preserved as immutable facts via a replay/deserialization tombstone rather than deleted or renamed.
- Active write-side behaviour was removed: `ReportEmailDeliveryOpened` and its routing/dispatch path are gone.
- Active read-side/presentation behaviour was removed: `"opened"` normalization, `"opened" -> "delivered"` presentation mapping, webhook rejection handling, and UI/test assertions for opened status are gone.
- Replay safety is handled explicitly through no-op aggregate/projector clauses.
- The new regression test exercises historic-event persistence/replay/projection rebuild safety, rather than only testing forward dispatch.

The synthesized blocker `broaden-opened-projector-noops` appears to be a false positive. The implementation evidence shows the projector clauses already use the broad Commanded projection shape:

```elixir
project(%EmailDeliveryOpened{}, fn multi -> multi end)
```

They do not constrain metadata shape such as `%{email_delivery_id: _}`.

## ADR violations

None identified.

## Blocking issues

None.

## Bounded-safe fixes

None.

The only previously raised bounded-safe fix was to broaden replay-only projector no-ops, but the clauses are already broad and metadata-independent. Changing them would be churn without improving behaviour.

## Judgement-worthy non-blocking code-health findings

1. **Permanent replay tombstone surface**

   - **Files:**
     - `lib/memba/messaging/events/email_delivery_opened.ex`
     - aggregate no-op clause for `EmailDeliveryOpened`
     - projector no-op clauses for `EmailDeliveryOpened`

   - **Smell:** The codebase continues to carry a deprecated event module and no-op handlers for a product status that no longer exists.

   - **Why it may need human judgement:** This is the correct event-sourcing tradeoff when historic events may exist. If an operational audit later proves no production event store contains `EmailDeliveryOpened`, the team could consider removing the tombstone. Until then, keeping it is safer and plan-conformant.

2. **Replay regression test reaches into EventStore/projection internals**

   - **Files:** replay-safety regression test containing helpers such as `reset_event_store!/1`, `reset_projection_tables!/1`, and rebuild orchestration.

   - **Smell:** The test manipulates EventStore tables, subscriptions, streams, snapshots, and projection tables with raw SQL.

   - **Why it may need human judgement:** For this iteration, that coupling is justified because the central risk is replay/rebuild safety. If similar tests accumulate, these destructive internals should probably move into a clearly named test-support helper to isolate knowledge of EventStore schema details.

## Suggested fixes

No merge-blocking or bounded-safe fixes are needed.

Optional future follow-ups only:

- Consider extracting shared replay/rebuild test helpers if more historic-event replay tests are added.
- Consider auditing production event stores before ever removing the `EmailDeliveryOpened` tombstone.

## Validation notes

- `dev ci` / dev check passed successfully.
- Acceptance suite passed: **82 scenarios / 493 steps**.
- The repair pass made no code/config/test changes because the synthesized projector-noop blocker was already satisfied.
- Because no repair diff was introduced, the earlier successful dev check still applies to the reviewed implementation state.
- Plan fidelity looks sound:
  - active `"opened"` command path removed;
  - read-model normalization removed;
  - presentation mapping removed;
  - webhook branch removed;
  - aggregate/projectors reduced to documented no-ops;
  - event module retained only as replay tombstone;
  - tests updated away from active `"opened"` behaviour;
  - replay regression added.
- Acceptance feature files appear to remain domain-focused and were not changed as implementation-detail specs.