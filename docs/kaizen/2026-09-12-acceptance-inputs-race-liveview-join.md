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
