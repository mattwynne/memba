Packet `006-92cda0d-2` is complete with result `ready_for_review`.

The targeted-add panel now consistently uses the authoritative group name returned by the Membership resolver:

- Retained as `targeted_group_member.group_name` in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:496).
- Passed to the panel instead of the projected selected-group name in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:324).
- Added a regression where the projection says “Projected Board” while the aggregate says “Board,” proving the heading and consequence copy use “Board” in [member_dashboard_targeted_add_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_targeted_add_live_test.exs:92).

Validation passed:

- Focused LiveView suite: 8 tests, 0 failures.
- Scoped format check: passed.
- `git diff --check`: passed.
- No unresolved issues.

The ordinary projection-backed display gate and read-only behavior remain unchanged. No targeted Add mutation, welcome handling, authority query, keyboard transition, acceptance feature, or browser journey work was added.

The required artifact is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/066-request-group-access/.delivery/latest-worker-result.json:1). The task remains unchecked as required. `dev check` was not run because this packet explicitly reserves the full gate for task 009.