# Problem: Acceptance inputs raced LiveView root join

## Observation

Four browser acceptance scenarios intermittently filled or submitted forms while the page's LiveView root was still joining:

- `features/group_conversations.feature:43`
- `features/member_message_deliverability.feature:25`
- `features/person_email_addresses.feature:27`
- `features/staff_club_slugs.feature:17`

The shared helper only waited for `window.liveSocket.isConnected()`. That proves the WebSocket transport is connected, but not that the current LiveView root has joined and applied its initial render.

## Proven cause

Diagnostics in `/tmp/toronto-footer-join-experiment.log`, `/tmp/toronto-footer-ready-control.log`, and `/tmp/toronto-footer-browser-events.jsonl` showed the server-rendered forms were visible while `[data-phx-main]` still had `phx-loading`. Playwright then filled fields before the initial join render arrived. The join render overwrote unfocused values, causing empty message subjects, erased person names, and a reset slug value.

Under a deterministic delayed-join experiment, the old transport-only helper failed all four targeted scenarios. Waiting for the current `[data-phx-main]` root to become `phx-connected` made the same four scenarios pass.

## Resolution

Date: 2026-09-12

Root cause: The browser acceptance harness conflated LiveSocket transport readiness with current LiveView root readiness. Transport readiness can happen before the root channel joins and patches over server-rendered form state.

Fix applied:

- `acceptance-tests/features/support/member_message.js`: strengthened `waitForLiveViewConnected` to require `window.liveSocket.isConnected()` and a current `[data-phx-main]` root that is `phx-connected` and not `phx-loading`.
- `acceptance-tests/features/support/member_message.js`: added the readiness wait before person-create field editing.
- `acceptance-tests/features/step_definitions/staff_club_slug_steps.js`: added the readiness wait before staff slug editing.
- `acceptance-tests/features/support/delayed_liveview_join.js` and `acceptance-tests/features/support/world.js`: added an opt-in delayed LiveView join harness, enabled only by `ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS`, to keep this race reproducible without product changes.
- `acceptance-tests/test/member_message_steps.test.js`: added focused regression tests proving transport-connected/loading is not ready, joined root is ready, stale connected roots do not mask a loading current root, and transport state is still required.

Validation:

- `node --test --test-name-pattern 'LiveView readiness|member compose waits|creating people' test/member_message_steps.test.js` — 6 tests passed.
- Old-helper comparison: with `currentLiveViewRootIsReady` temporarily reduced to transport-only, `ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS=2000` made the four targeted browser scenarios fail: 4 scenarios, 25 steps, 4 failed / 8 skipped / 13 passed; delayed injection held 5 joins.
- Fixed-helper regression: `ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS=2000 ACCEPTANCE_DELAY_LIVEVIEW_JOIN_LOG=/tmp/memba-liveview-delay-events.jsonl ./bin/dev acceptance --name "^(Bob starts an Admin conversation in the web app|Alice's club-message email subject includes the club slug|Staff creates a person with primary and alternate email addresses|Staff enter an invalid slug)$" --format progress --format json:/tmp/memba-liveview-delay-fixed.json` — 4 scenarios and 25 steps passed; delayed injection held 6 joins.
- Final full gate on committed state: `ACCEPTANCE_SERVER_NODE=<unique> ./bin/dev check` — Mix precommit reported 1,261 tests and 0 failures; browser acceptance reported 134 scenarios and 951 steps passed.

Remaining follow-up:

- None for this narrow harness race. The delayed-join harness is opt-in and should remain disabled in normal acceptance runs.

## Additional observation and repair: 2026-09-14 — group-tab keyboard input

The full gate for the [iteration-062 timeout countermeasure](2026-09-03-iteration-workflow-timeout-masks-test-failure.md#iteration-062-investigation-and-partial-resolution-focused-browser-selection) failed in `An Admin member views Admin conversations and members` (`group_conversations.feature:33`). A focused rerun and a baseline using the original, unchanged Cucumber configuration reproduced the failure. The test expected Members to become selected after ArrowRight, but it stayed unselected.

Passive browser instrumentation captured ArrowRight at 292.5 ms after navigation while the transport was connected, the root was `phx-loading`, and the SectionTabs keyboard handler was absent. The hook installed the handler at 312.0 ms; the root became `phx-connected` at 313.1 ms. No tab click followed the lost key. Waiting longer for the resulting attribute cannot recover input dispatched before its handler exists.

Root cause: `selectGroup` navigated to a server-rendered group page, and `viewMembersAndAssertPresence` then exercised hook-dependent keyboard behaviour without calling the existing root-readiness barrier. The shared barrier was already correct; this call site, introduced in iteration 061 (`54a6ef709`), omitted it. This extends the earlier occurrence pattern from pre-join form edits to pre-mount keyboard input. Previous readiness tests and delayed-join URL targeting did not cover the group tab route.

Fix applied:

- `acceptance-tests/features/step_definitions/group_conversation_steps.js`: calls the already-imported `waitForLiveViewConnected` before reading tab state or focusing/pressing keys. Every existing keyboard, focus and membership assertion remains unchanged.
- `acceptance-tests/test/group_conversation_readiness.test.js`: executes the registered Cucumber step against a not-yet-ready harness; proves readiness precedes tab interaction, whether Members is already selected or not.
- `acceptance-tests/features/support/delayed_liveview_join.js`: includes the group root route in the existing opt-in delayed-join harness. Normal browser runs still have delay injection disabled.

Validation:

- Focused helper regression: both cases failed before the wait (`tab state read before LiveView readiness`) and passed after it.
- Controlled real-browser comparison with `ACCEPTANCE_DELAY_LIVEVIEW_JOIN_MS=2000`: before the wait, 1 scenario failed (8 passed, 1 failed, 1 skipped steps); after the wait, the same scenario and all 10 steps passed. No timeout increase, fixed sleep in production, retry, scenario edit, or application-code change was made.
- Evidence: `/tmp/memba-062-original-config-diagnostic-run.log`, `/tmp/memba-062-tab-events.jsonl`, `/tmp/memba-062-tab-delayed-red.log`, `/tmp/memba-062-tab-delayed-green.log`, and corresponding delayed-join event logs.
- Final full gate and Node config suite results on the staged candidate are recorded in the repair commit message; logs: `/tmp/memba-062-dev-check-final.log` and `/tmp/memba-062-config-suite-final.log`.

Expected result: keyboard assertions start only after the current view's hook is mounted. The delayed-join red/green run demonstrates this mechanism at the identified call site; it does not establish that every acceptance interaction already uses the readiness barrier.
