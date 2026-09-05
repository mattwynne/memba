Implemented task 008: “Carry the resolved audience group through the existing inbound root-message command.”

Changes:

- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:1277) now passes the resolved `InboundClubDestination.group_id` into `SendMessage.audience_group_id`.
- Existing non-group-specific callers continue defaulting to the deterministic Everyone group.
- Recipient resolution remains unchanged and Everyone-based, preserving task 009’s boundary.
- [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:207) proves an email to the Admin address creates an Admin write grant without granting Everyone access.
- [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:10) now contains exactly:
  `- [x] 008 Carry the resolved audience group through the existing inbound root-message command.`

Validation:

- TDD red: focused inbound suite — 25 tests, 1 expected failure because the command still carried Everyone.
- Focused green: inbound suite — 25 tests, 0 failures.
- Expanded focused suites covering inbound, shared send behavior, and the aggregate — 60 tests, 0 failures.
- `git diff --check` passed.
- `dev check --quick` completed formatting/static checks but the suite reported 1105 tests, 1 failure from the previously documented `DevTestSupportControllerTest` consistency timeout.
- Isolated reproduction: 6 tests, 1 failure with the same unrelated timeout. No task-focused test failed.

No todo tasks were split, added, reordered, or otherwise checked off.

ADR conformance:

- ADR 0002/0004: reused the existing event-sourced `SendMessage`/Message aggregate behavior; no new command, event, or aggregate was introduced.
- ADR 0005: resolved recipients remain embedded in `SendMessage` and were deliberately not changed before task 009.
- ADR 0007: production code continues using Membership’s public query boundary and does not access Membership projection storage.
- ADR 0011: caller-generated message identities remain unchanged.