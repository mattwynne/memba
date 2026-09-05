Implemented task 009: “Resolve deliveries through active group members and emit the group write-access grant.”

Changes:

- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:49) now documents group-targeted delivery with Everyone as the default audience.
- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:1408) resolves recipients from the selected `audience_group_id` through Membership’s public `list_active_members_of_group/1` API.
- The existing Message aggregate continues to emit the selected audience group’s write-access grant.
- [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:167) proves that an Admin-audience message:

  - creates deliveries for the two active Admin members;
  - excludes an active Everyone-only member;
  - emits and projects Admin write access.

- Task 010 remains deliberately untouched: the sender in this test is an Admin recipient, and the existing sender-must-be-a-recipient invariant remains in place.

Validation:

- TDD red: focused send suite — 8 tests, 1 expected failure because the Everyone-only member incorrectly received the Admin message.
- Focused green: send suite — 8 tests, 0 failures.
- Expanded Messaging validation: send and inbound suites — 33 tests, 0 failures.
- `dev check --quick` exited successfully after compilation and formatting; its broad ExUnit output reported 1,106 tests with the previously documented unrelated `DevTestSupportControllerTest` database consistency timeout. No task-focused test failed.
- `git diff --check` passed.

Exact todo check-off in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:11):

```markdown
- [x] 009 Resolve deliveries through active group members and emit the group write-access grant.
```

No todo items were split, added, reordered, or otherwise checked off.

ADR conformance:

- ADR 0002/0004: delivery creation and access grants remain events emitted by the existing Message aggregate.
- ADR 0005: recipients are resolved before dispatch and embedded in `SendMessage`.
- ADR 0007: Messaging calls Membership’s public group-member query and does not access Membership projection storage.
- ADR 0011: caller-generated message and delivery identities remain unchanged.
- ADR 0022: strong consistency is used in the focused test before asserting projected access.