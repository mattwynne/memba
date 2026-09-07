Implemented and checked off task 016:

`At the Messaging boundary, resolve/verify the audience group under the supplied club before recipient lookup and command construction.`

Changes:

- Updated [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:1607) so `send_club_message/2` now:
  - validates the supplied club ID;
  - resolves the explicit audience group or deterministic Everyone default;
  - verifies the group belongs to the supplied club through Membership’s public `get_group/1` API;
  - rejects missing or foreign groups with `:audience_group_not_found`;
  - performs recipient lookup and constructs `SendMessage` only after verification.
- Added a regression test in [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:235) proving an unknown group is rejected without appending a `MessageSent` event.
- Updated the API documentation to describe the strengthened boundary contract.

Validation:

- Initial focused test correctly failed with the previous behavior: expected `:audience_group_not_found`, received `:invalid_recipients`.
- `dev test test/memba/messaging/send_club_message_test.exs`
  - 9 tests, 0 failures.
- `dev check --quick`
  - 1,165 tests, 0 failures.
- `git diff --cached --check`
  - Passed.

Checked off only [todo.md item 016](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:18). No tasks were split, added, removed, or reordered. Task 017 remains unchecked for its explicit two-club mismatch regression coverage.

ADR conformance:

- ADR 0005: recipient resolution remains in the Messaging application service and occurs before command dispatch.
- ADR 0007: Messaging uses Membership’s public plain-map query API without accessing Membership projection schemas.
- ADR 0002: the invariant is enforced at the application-service command boundary before the Commanded aggregate is invoked.

The three-file diff is staged with no unstaged changes.