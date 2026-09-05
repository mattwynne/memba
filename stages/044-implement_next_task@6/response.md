Implemented and checked off task 006:

`- [x] 006 Introduce a named fixed group-email posting policy in Messaging.`

Changes made:

- Replaced the unnamed inbound authorization service with [group_email_posting_policy.ex](/workspace/memba/web/lib/memba/messaging/group_email_posting_policy.ex:1).
- Named the fixed policy `:club_members_only` through `GroupEmailPostingPolicy.name/0`.
- Kept policy configuration entirely in code—no persistence, runtime configuration, UI, commands, or events were added.
- Updated [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:260) to delegate inbound sender authorization through the named policy.
- Renamed and expanded the focused test as [group_email_posting_policy_test.exs](/workspace/memba/web/test/memba/messaging/group_email_posting_policy_test.exs:1).
- Preserved the existing Everyone-group authorization predicate. Switching authorization to direct destination-club membership remains exclusively task 007.

Validation:

- TDD red run: 5 tests, 1 expected failure because `GroupEmailPostingPolicy.name/0` did not yet exist.
- Focused green run:
  `dev test test/memba/messaging/group_email_posting_policy_test.exs`
  — 5 tests, 0 failures.
- `git diff --check` passed.
- `dev check --quick` completed static and formatting checks and ran 1,104 tests. It surfaced the previously documented unrelated `DevTestSupportControllerTest` database consistency timeout: 1 failure. The task-specific suite passed.

No todo tasks were split, added, removed, reordered, or otherwise checked off.

ADR conformance:

- ADR 0007: authorization still calls Membership only through its public query API.
- ADR 0005: recipient resolution and `SendMessage` construction were not changed.
- ADR 0004: no Message aggregate or delivery-state behavior changed.
- ADR 0002: the fixed stateless policy introduced no unnecessary persisted configuration or event-sourced state.