Implemented and checked off task 009: “Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.”

Changes:

- [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:15) now refreshes server-authoritative dashboard state after matching club changes from the Group, GroupMembership, Membership, Role, and ConversationGroupAccess projectors.
- Route patches and remembered-group events now reauthorize the selected group, closing the race where a member could interact with stale private rows before receiving a PubSub notification.
- [new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:349) now rechecks current audience participation through `Membership.list_active_groups_for_member/2` immediately before dispatch. An already-open compose form can no longer send after the member loses group access.
- Added focused regressions in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:398) covering discovery refresh, membership loss, immediate section patches, admin-role loss, and conversation-access revocation.
- Added the stale-compose regression in [new_send_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_send_test.exs:226), proving no message or email delivery is created.

Validation:

- TDD red: corrected focused dashboard suite produced five expected behavior failures; stale compose also reproduced an unauthorized send.
- Focused LiveView suites: 72 tests, 0 failures.
- Browser scenario `Bob starts an Admin conversation in the web app`: 1 scenario, 7 steps, all passed.
- Formatting check and `git diff --check`: passed.
- Exact current working-tree state: `dev check --quick` passed with 1,272 tests and 0 failures.
- Full `dev check` was not run because task 011 explicitly owns the final delivery gate.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:11):

```markdown
- [x] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.
```

No tasks were split, added, removed, or reordered. Tasks 010 and 011 remain unchecked.

Architecture remains consistent with ADR 0021’s committed read-model notification boundary, ADR 0015’s LiveView ownership, and ADR 0023’s URL-addressable state. Production web code reauthorizes through the public Membership API and introduces no projection-schema joins, preserving ADR 0007’s context boundary.