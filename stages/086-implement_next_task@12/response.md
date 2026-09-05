Implemented task 012 and checked off only that todo line.

Changes in [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:233):

- Extended the Admin reply test to prove an active club member outside Admin cannot post a direct reply and creates no message or deliveries.
- Added Admin-address header-routing coverage proving an inbound reply:
  - threads onto the existing Admin conversation;
  - inherits the root subject;
  - delivers only to existing followers;
  - excludes the replying member, non-following Admin members, and non-Admin members;
  - makes the successful replier a follower.
- Added a forged-header test proving an active non-Admin cannot gain reply rights by supplying another Admin recipient’s genuine outbound Message-ID.
- No production code or acceptance feature files changed.

Validation:

- `dev test test/memba/messaging/inbound_club_message_acceptance_test.exs`: 29 tests, 0 failures.
- Inbound and direct-reply regression suites together: 36 tests, 0 failures.
- `git diff --check`: passed.
- `dev check --quick`: exited successfully and formatting/compilation completed. Its broad ExUnit output still reported the pre-existing unrelated `MembaWeb.DevTestSupportControllerTest` consistency timeout: 1,110 tests, 1 failure. A focused rerun reproduced that database consistency timeout; it is outside task 012’s scope.

Checked off [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:14):

```markdown
- [x] 012 Keep header routing and follower-only reply delivery unchanged; cover direct/forged non-member reply attempts with focused domain tests rather than a new stakeholder scenario.
```

No todo tasks were split, added, reordered, or otherwise checked off.

ADR conformance remains intact: Messaging’s public API continues to own reply authorization and dispatch under ADRs 0002/0004; Membership access stays behind its public context API per ADR 0007; test message identities are caller-generated UUIDs per ADR 0011; and strong consistency is used before projected-state assertions per ADR 0022. No shared feature files were changed under ADR 0010.