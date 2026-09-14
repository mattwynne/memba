Implemented the task 019 revision and left it unchecked for independent validation.

Selected task:

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

Changes made:

- In [messaging.ex](/repos/mattwynne/memba/web/lib/memba/messaging.ex:326), nil-status inbound retries now look for the deterministic committed message before entering normal sender/destination authorization.
- Committed reply reconciliation now accounts for subject canonicalization: the stored reply subject is validated against the root conversation subject, while the inbound subject may contain `Re:`.
- Documented the stable authorization check as the membership-ordering point for web sends and replies. A departure committed afterward races with an already-authorized dispatch; fully closing that check/use boundary would require cross-context locking or transactions.
- Strengthened the concurrent rejection test to prove exactly one retry wins, seven are recognized as duplicates, one rejection event is recorded, and exactly one rejection email is sent.
- Strengthened the stale-follow test so `ConversationGroupAccess` remains behind during reply recipient resolution. The authoritative root aggregate access and Club membership state exclude the rejoined-but-no-longer-private-group member despite the stale follow.
- Added the committed inbound reply/departure regression in [inbound_club_message_acceptance_test.exs](/repos/mattwynne/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:2106).
- Tightened the lagging-access recipient test in [send_club_message_test.exs](/repos/mattwynne/memba/web/test/memba/messaging/send_club_message_test.exs:684).

Validation:

- The new reply-recovery test first failed with `{:error, :inbound_message_mismatch}`, confirming the regression.
- Three targeted validator scenarios: 3 tests, 0 failures.
- Full inbound messaging file: 38 tests, 0 failures.
- Full club-message sending file: 15 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`: 1,343 tests, 0 failures.
- `git diff --check`: passed.

The browser-inclusive full `dev check` was intentionally not run because it remains explicitly assigned to task 021.

No todo lines were split, added, reordered, or checked. The exact pending line remains:

`- [ ] 019 Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended.`

ADR conformance:

- ADR 0004: deterministic retry reconciliation reads the existing per-message aggregate.
- ADR 0005: recipient resolution remains command-side, with authoritative access filtering before delivery creation.
- ADR 0007: Messaging continues to consult Membership through its public APIs without crossing bounded-context ownership.
- ADR 0022: stable checkpoint checks remain the synchronization and authorization mechanism.
- ADR 0024: current club/private-group membership is determined from the authoritative Club aggregate, not lagging projections.