Implemented task 017: “Make this invariant fail closed for mismatched group/club IDs, and cover it with a regression test so a future caller cannot create a cross-club conversation.”

1. Added a two-club regression test in [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:255). It creates populated clubs, attempts to send using the other club’s Everyone group, and verifies:

   - `{:error, :audience_group_not_found}` is returned.
   - No `MessageSent` event—and therefore no cross-club conversation—is created.

2. No production change was needed. Task 016’s existing boundary logic already validates group ownership before resolving recipients or constructing the command.

3. Validation passed:

   - `dev test test/memba/messaging/send_club_message_test.exs` — 10 tests, 0 failures.
   - `dev check --quick` — 1,166 tests, 0 failures.
   - `git diff --check` — passed.

4. Checked off exactly [todo.md task 017](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:19).

5. No tasks were split, added, removed, or reordered. Tasks 018–022 remain unchecked.

6. ADR conformance:

   - ADR 0002: the regression verifies the invariant is enforced before Commanded dispatch.
   - ADR 0005: foreign-group rejection occurs before recipient resolution and `SendMessage` construction.
   - ADR 0007: group ownership remains resolved through Membership’s public API, preserving the Membership/Messaging boundary.