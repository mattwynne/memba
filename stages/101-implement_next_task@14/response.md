Implemented and validated todo task 014. The final three-file diff is staged with no unstaged changes.

1. Selected task

   `014 The compose confirmation and error paths must retain that group.`

2. Changes made

   - Updated compose navigation in [new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:549) so an explicitly selected group is retained in:
     - confirmation “Check delivery” links;
     - confirmation “Send another message” links;
     - confirmation and error “Back to club home” links;
     - validation/retry “Club home” and “Cancel” links.
   - Group-home links use the canonical `/groups/:group_id` route.
   - Compose and message-detail links carry the opaque ID as `?group_id=…`.
   - Only an explicit route group is propagated, so unscoped Everyone URLs remain unchanged.

3. Test coverage and validation

   Added coverage in [new_send_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_send_test.exs:168) for:

   - selected-group success confirmation links;
   - blank-body validation;
   - a real Messaging rejection caused by an invalid subject;
   - retry after send failure;
   - retained audience state throughout those transitions.

   Commands and results:

   - Initial TDD run: 6 tests, 2 expected failures.
   - Focused post-change run: 6 tests, 0 failures.
   - Combined compose suites: 17 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check`: passed, including the full browser acceptance suite.
   - `git diff --cached --check`: passed.

4. Todo check-off

   Changed only [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:16):

   `- [ ] 014 ...` → `- [x] 014 ...`

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 015 remains the first unchecked task.

6. ADR conformance

   - ADR 0013: user-facing success, validation, failure, retry, and navigation behavior is covered through LiveView tests.
   - ADR 0015: compose remains a LiveView-owned member application flow.
   - ADR 0019: tests exercise canonical club-subdomain routing.
   - ADR 0023: explicit selected-group state remains URL-addressable across confirmation and error navigation.