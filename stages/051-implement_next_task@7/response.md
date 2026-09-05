Implemented and checked off task 007:

`- [x] 007 For a new inbound conversation it authorises the resolved sender by active membership of the destination club, not membership of the addressed group.`

Changes:

- [group_email_posting_policy.ex](/workspace/memba/web/lib/memba/messaging/group_email_posting_policy.ex:33) now authorizes through `Membership.active_member_of_club?/2`, independent of Everyone/Admin group membership.
- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:260) documents the corrected `:club_members_only` contract.
- [group_email_posting_policy_test.exs](/workspace/memba/web/test/memba/messaging/group_email_posting_policy_test.exs:17) proves an active club member outside Admin is authorized while inactive and other-club senders remain rejected.
- [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:188) replaces the superseded rejection expectation with resolution-and-authorization coverage. It intentionally stops before root-message dispatch because audience propagation and sender-not-in-recipient handling belong to tasks 008–010.
- Checked off only task 007 in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:9). No tasks were split, added, or reordered.

Validation:

- TDD red: focused policy suite produced the expected failure under the old Everyone-group predicate — 5 tests, 1 failure.
- Focused green:
  `dev test test/memba/messaging/group_email_posting_policy_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
  — 29 tests, 0 failures.
- `git diff --check` passed.
- `dev check --quick` completed formatting/static checks, but the broad suite is not green due to the previously documented `DevTestSupportControllerTest` consistency timeout. An isolated run reproduced it with 6 tests, 1 failure; when it occurs early, the stopped `Memba.Supervisor` causes cascading setup failures. No task-focused test failed.

ADR conformance:

- ADR 0007: Messaging uses Membership’s public `active_member_of_club?/2` API and does not access Membership projections directly.
- ADR 0005: recipient resolution and message commands were not changed.
- ADR 0002: no commands, events, aggregates, or persisted policy configuration were introduced.