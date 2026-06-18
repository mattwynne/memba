## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The plan could explicitly name the likely test files/suites to update, but it already gives enough touchpoints and validation criteria for implementation.
2. The “Open Technical Decisions” section could be renamed to “Implementation-time details” to avoid implying unresolved readiness blockers. The decisions are bounded and have a clear validation method.

## Smallest viable iteration

The current slice is already the smallest useful coherent iteration: remove `"opened"` as a live status everywhere while retaining only the documented replay-safety tombstone needed for historic event-store compatibility.

Splitting this smaller would risk leaving the codebase in another inconsistent half-removed state.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. A final grep/inventory showing no `opened`/`Opened` references in `lib/` except the documented replay shim.
2. Removal of the deprecated command, read-model normalization, presentation mapping, webhook special case, and active projector behavior.
3. Updated ExUnit and acceptance support code with no remaining assertions or fixtures treating `"opened"` as a supported status.
4. A regression test that persists/replays a historic `EmailDeliveryOpened` event and proves:
   - replay/rebuild succeeds;
   - member projections are unaffected;
   - staff projections are unaffected;
   - read models do not surface `"opened"`.
5. `dev check` passes before delivery.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}