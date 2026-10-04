Implemented packet `task-009d-c903b57-title-disclosure-revision-2` with result `ready_for_review`.

Changes:

- [show.ex](/workspace/memba/web/lib/memba_web/live/member_message_delivery_live/show.ex:30) now synchronizes the socket-level browser title after initial binding and relevant refreshes, and clears it before access-loss navigation.
- Receipt-group `<details>` elements preserve browser-owned `open` state using `JS.ignore_attributes(["open"])` while retaining existing initial defaults and stable IDs.
- [show_test.exs](/workspace/memba/web/test/memba_web/live/member_message_delivery_live/show_test.exs:20) now proves initial/refreshed titles and disclosure preservation alongside the existing delivery, access, isolation, route, and presentation coverage.
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

Validation passed:

- Focused test command: 89 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted`: exit 0.
- `git diff --check`: exit 0.
- Worker-result JSON validated successfully.

Task 009D remains unchecked. No acceptance feature, plan, todo, or unrelated production files changed. Per packet constraints, I did not run `dev check`; the deterministic workflow owns that full gate.