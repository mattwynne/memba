Implemented task 011: “Reuse the group-write reply authorisation delivered by 056 for Admin conversations.”

- Added focused integration coverage in [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:233).
- The test creates an inbound Admin conversation from a non-Admin member, confirms the Admin write grant, and proves a different active Admin member can post a threaded reply.
- No production authorization code changed. The existing generic `authorize_reply_sender/1` boundary already authorizes active membership in any group holding conversation write access, including Admin. Header-based reply routing remains untouched for task 012.

Validation:

- Targeted Admin reply test: 27 tests, 0 failures, 26 excluded.
- Full inbound/reply regression pair: 34 tests, 0 failures.
- `git diff --check`: passed.
- `dev check --quick`: exited successfully and formatting/compilation passed. Its broad ExUnit output reported 1,108 tests with one known unrelated `DevTestSupportControllerTest` database consistency timeout.

Checked off exactly this line in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:13):

```markdown
- [x] 011 Reuse the group-write reply authorisation delivered by 056 for Admin conversations.
```

No tasks were split, added, reordered, or otherwise checked off.

ADR conformance is preserved: Messaging continues to own reply authorization and message dispatch under ADRs 0002/0004; Membership is accessed only through its public API per ADR 0007; test identities remain caller-generated UUIDs per ADR 0011; and strong consistency is used before asserting projected Admin membership, access, and reply state per ADR 0022.