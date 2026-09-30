Packet `task-003-ca07fef-page-title-revision-2` is `ready_for_review`.

Implemented:

- Added a shared `install_dashboard/2` path used by both initial mount and refresh in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:562).
- The helper keeps `:dashboard` as the sole projection-query result and derives only shell metadata `:page_title` from `dashboard.page_title`.
- Added the exact regression assertion in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:59):
  `assert page_title(view) == "Alpine Club · Memba"`
- Preserved all existing authorization, route, transient-state, and provisional notification behavior.
- Left the task unchecked as required.
- Recorded the result in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).

Validation passed:

- `bin/dev test test/memba_web/live/member_dashboard_live_test.exs` — 48 tests, 0 failures
- `bin/mix format --check-formatted lib/memba_web/live/member_dashboard_live.ex test/memba_web/live/member_dashboard_live_test.exs` — exit 0
- `git diff --check` — exit 0
- Worker-result JSON syntax validation — exit 0

The initial TDD run reproduced the defect as `"Memba · Memba"` before the implementation. No unresolved issues remain. Per the packet, the full `dev check` was not run in this worker node; the workflow’s deterministic gate handles it later.