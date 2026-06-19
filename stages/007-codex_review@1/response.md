# Iteration Review Report: 035 — Obliterate Opened Delivery Status

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

## ADR violations

None found.

The implementation appears consistent with the project’s Commanded/CQRS/event-sourcing architecture. The historic `EmailDeliveryOpened` event is retained as a replay tombstone rather than deleted outright, and active behaviour has been removed from aggregate/projector/read-model paths. That matches the expected event-sourcing constraint that old persisted events must remain deserializable and replay-safe.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Event tombstone pattern is still implicit project knowledge**

   - **Files:** `lib/memba/messaging/events/email_delivery_opened.ex`, aggregate/projector no-op clauses, future ADR/docs area
   - **Smell:** This iteration uses a sound event-deprecation pattern: keep the event module as a tombstone, reduce aggregate/projector handling to documented no-ops, and prove replay safety with a regression test. That pattern is valuable but appears to live only in this implementation and its comments.
   - **Why it may need human judgement:** If future iterations remove or deprecate other persisted events, contributors may make inconsistent choices unless the project documents a canonical tombstone/replay-safety approach. This does not block this merge because the local implementation is clear and tested.

2. **Replay-regression test necessarily reaches into event-store/projection reset internals**

   - **Files:** `test/memba/messaging/email_delivery_opened_replay_test.exs` and related test helper code shown in collected evidence
   - **Smell:** The regression test exercises the right behaviour, but it uses low-level reset/rebuild mechanics such as truncating event-store/projection tables and mapping projectors to Commanded apps. That is appropriate for this class of test, but it is more infrastructure-coupled than ordinary context tests.
   - **Why it may need human judgement:** If more replay-safety tests are added, this helper may become a de facto event-store test harness. It may be worth extracting or documenting as a deliberate shared test pattern later, rather than allowing each iteration to grow bespoke reset/rebuild helpers. This is non-blocking because the current test validates the key risk directly.

3. **Long-term tombstone removal criteria remain operationally undefined**

   - **Files:** `lib/memba/messaging/events/email_delivery_opened.ex`, iteration follow-up notes
   - **Smell:** The plan correctly keeps the tombstone unless production can be proven to contain no historic `EmailDeliveryOpened` events. The implementation intentionally does not solve how that proof is obtained.
   - **Why it may need human judgement:** Tombstones are safe to keep, but over time they can accumulate. A future operational/architecture decision could define how to query production event stores and when, if ever, to remove historic event tombstones.

## Suggested fixes

No merge-blocking or bounded-safe fixes are recommended.

Optional future follow-ups:

- Document the event-deprecation/tombstone pattern in ADR or reference docs if this pattern recurs.
- Consider centralizing replay-test infrastructure if more projector rebuild regression tests are added.
- Define an operational process for verifying whether historic event tombstones can ever be safely removed.

## Validation notes

- `dev ci` completed successfully before review.
- Acceptance suite passed: 82 scenarios, 493 steps.
- The implementation matches the plan’s main acceptance criteria:
  - Active `opened` delivery-status behaviour was removed from command routing, read-model normalization, presentation mapping, webhook handling, UI-facing delivery surfaces, tests, and acceptance support.
  - `ReportEmailDeliveryOpened` was removed.
  - `EmailDeliveryOpened` remains only as a documented replay tombstone.
  - Aggregate and projector handling for `EmailDeliveryOpened` was reduced to documented no-op replay support.
  - A regression test persists/replays a historic `EmailDeliveryOpened` event and exercises projector rebuild safety rather than only testing forward dispatch.
- No evidence showed out-of-scope product behaviour changes.
- No ADR conflict or architecture bypass was found.