Implemented task 013 and left the exact staged state passing `dev check`.

1. Selected task

   `013 Generalise the member compose entry and submit path to carry an authorised audience group from the selected group route.`

2. Changes made

   - Group-scoped dashboard actions now carry the opaque group ID into `/messages/new?group_id=…`, including both the header and empty-state actions in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:79) and [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:176).
   - The compose LiveView now resolves the signed-in active club member, authorizes12weruk and authorissionallk'tl?? Wait typo. Need clean final. Ensure no bizarre. Need regenerate. 
   - The compose LiveView now resolves the signed-in active club member, authorizes the requested group through Membership’s public APIs, scopes the recipient count to that group, and returns the ordinary not-found response for unavailable groups in [new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:22).
   - Submission passes the server-authorized `audience_group_id` to `Messaging.send_club_message/2`; it is not accepted from form parameters.
   - Added regression coverage proving:
     - dashboard compose links preserve selected-group context;
     - unauthorized private-group compose URLs disclose nothing;
     - a selected-group submission emails only that group’s active members and grants the conversation to that group, not Everyone.

3. Validation

   - TDD failure run: 56 tests, 3 expected failures before implementation.
   - Focused post-change run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs`
     - 56 tests, 0 failures.
   - `mix format` passed for all touched Elixir, HEEx, and test files.
   - Final `PATH="$PWD/bin:$PATH" dev check` passed on the exact staged diff:
     - 1,163 ExUnit tests, 0 failures.
     - 122 browser acceptance scenarios, 877 steps, all passed.
   - `git diff --cached --check` passed, with no unstaged changes.

4. Todo check-off

   Changed only [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:15):

   `- [ ] 013 ...` → `- [x] 013 ...`

   Task 014 remains the first unchecked task.

5. Todo structure

   No tasks were split, added, removed, or reordered. Confirmation and error-path retention remain task 014.

6. ADR conformance

   - ADR 0013: user-visible routing and interaction behavior is covered in the established LiveView web suites; lower-level LiveView helpers are used where dispatch and projection results must be inspected.
   - ADR 0015: compose remains a member-facing LiveView.
   - ADR 0019: tests exercise club selection through the configured club subdomain.
   - ADR 0023: selected-group compose context is URL-addressable through the opaque `group_id` query parameter.
   - Authorization uses public Membership APIs; the web layer does not query Membership projection schemas.