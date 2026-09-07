Implemented task 012 and left the exact staged state passing `dev check`.

1. Selected task

   `012 The server remains the authority for every final selection.`

2. Changes made

   - Fixed a fail-open edge in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:88). An invalid or inaccessible remembered group still falls back to Everyone, but a fresh `:forbidden` result—such as revoked club membership—now terminates access instead of retaining stale dashboard authorization.
   - Added a regression test in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:241) that mounts the dashboard, revokes club membership, then verifies a remembered-selection event fails closed.

3. Validation

   - The new focused test initially failed against the previous behavior: expected a forbidden exit, but the server returned Everyone.
   - After the fix:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:240`
       - 1 test, 0 failures.
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
       - 40 tests, 0 failures.
     - `mix format ...`
       - Passed.
     - `git diff --cached --check`
       - Passed.
     - `PATH="$PWD/bin:$PATH" dev check`
       - Passed, including ExUnit and browser acceptance suites, on the exact staged diff with no unstaged changes.

4. Todo check-off

   Changed only [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:14):

   `- [ ] 012 ...` → `- [x] 012 ...`

   Task 013 remains the first unchecked task.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0013: the authorization behavior is covered through `Phoenix.LiveViewTest`.
   - ADR 0015: authorization remains owned by the existing member-dashboard LiveView.
   - ADR 0023: canonical routed state remains server-controlled; browser-local storage is only a proposed selection.
   - ADR 0019: the regression continues to exercise the host-selected club context.