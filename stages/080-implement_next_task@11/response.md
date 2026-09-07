Implemented and checked off task 011. The exact staged state passes `dev check`, with no unstaged changes.

1. Selected task

`011 Add a small LiveView client hook or equivalent browser-local mechanism that remembers a successful rail selection by club, restores it only when no explicit group route is requested, and lets the server fall back safely to Everyone when a saved group is absent or unauthorised.`

2. Changes made

- Added a club-scoped localStorage hook in [remember_group_selection.mjs](/workspace/memba/web/assets/js/remember_group_selection.mjs:1), using keys such as `memba:lastGroup:<club-id>`.
- Registered the hook with LiveView in [app.js](/workspace/memba/web/assets/js/app.js:27).
- Attached restoration metadata and the hook to the club home in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:12).
- Added server-side restoration handling in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:64):
  - authorises remembered IDs through `MemberDashboardPresentation`;
  - restores authorised groups using canonical `push_patch` routes;
  - preserves the Conversations or Members section;
  - leaves stale, malformed, or unauthorised selections on Everyone;
  - prevents remembered selections from overriding explicit group routes;
  - returns the final selected group to the hook so stale storage is replaced.
- Added LiveView coverage for authorised restoration, stale private-group fallback, explicit-route precedence, canonical URLs, and no-disclosure behavior in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:126).
- Added focused hook tests in [remember_group_selection_hook.test.js](/workspace/memba/acceptance-tests/test/remember_group_selection_hook.test.js:1).
- No acceptance feature files or runner-debt tags were changed.

3. Validation

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
  - 39 tests, 0 failures.
- `npm run test:config -- --test-name-pattern='selection|remembered|explicit group|rail update'`
  - 54 tests, 0 failures.
- `mix format ...`
  - Passed for touched Elixir and HEEx files.
- `git diff --cached --check`
  - Passed.
- Final `PATH="$PWD/bin:$PATH" dev check`
  - Passed on the exact staged state, including the full ExUnit and browser acceptance suites.

4. Todo check-off

Changed exactly task 011 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:13). Task 012 remains unchecked.

5. Todo structure

No tasks were split, added, removed, or reordered.

6. ADR conformance

- ADR 0013: added user-facing LiveView tests and focused client-hook tests.
- ADR 0015: restoration remains part of the existing member-dashboard LiveView.
- ADR 0019: restoration uses canonical host-relative club routes.
- ADR 0023: restored group and section state is represented through canonical LiveView URL patches; localStorage is only a restoration hint.