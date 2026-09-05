Implemented and checked off task 015. The codebase passes the full `dev check`.

1. Selected task

> `015 Add aggregate, policy, projection/replay, release-backfill, inbound-route, authorisation, recipient-delivery, sender-non-following, and reply-authorisation tests.`

2. Changes made

- Closed an aggregate invariant exposed by the new tests: genuinely new groups must now provide an email slug, while idempotent commands for historical slugless groups remain compatible in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:467).
- Added aggregate coverage for required group slugs in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:395).
- Reworked the slug projection test so it exercises a real `GroupEmailSlugAssigned` event against a historical slugless group rather than an idempotent no-op in [group_projection_test.exs](/workspace/memba/web/test/memba/membership/group_projection_test.exs:64).
- Extended projection replay parity to verify public Everyone/Admin slug lookups and retained `GroupEmailSlugAssigned` event counts for historical and modern clubs in [system_groups_replay_parity_test.exs](/workspace/memba/web/test/memba/membership/system_groups_replay_parity_test.exs:87).
- Added aggregate and projection-replay coverage proving a non-recipient sender is not restored as a follower:
  - [conversation_followers_test.exs](/workspace/memba/web/test/memba/messaging/conversation_followers_test.exs:141)
  - [conversation_follow_projection_test.exs](/workspace/memba/web/test/memba/messaging/conversation_follow_projection_test.exs:179)
- Strengthened Admin recipient resolution to exclude a removed former Admin in [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:168).
- Added realistic inbound Admin coverage for:
  - Active Admin sender delivery and following.
  - Non-Admin sender’s lack of Everyone-group read access.
  - Duplicate provider-message idempotency.
  - Inactive and other-club sender rejection before message, delivery, access, or acceptance events.
  - See [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:207).
- Updated the custom-group reply test fixture to provide the now-required email slug in [post_message_reply_test.exs](/workspace/memba/web/test/memba/messaging/post_message_reply_test.exs:449).
- Existing direct policy, inbound-route, release-backfill, direct/forged reply-authorisation, and sender-non-following tests were audited and retained. No acceptance feature files were changed.

3. Validation

- Test-first focused run: `98 tests, 2 failures`
  - Exposed the missing new-group slug invariant.
  - Exposed an incorrect replay checkpoint wait in the new test.
- After implementation:
  - Replay-focused test: `4 tests, 0 failures`.
  - Complete affected focused suite: `98 tests, 0 failures`.
  - Formatting check: passed.
  - `git diff --check`: passed.
- Full `PATH="$PWD/bin:$PATH" dev check`: passed on the exact final diff, including the todo check-off and browser acceptance suite.

4. Todo check-off

Updated [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:17) exactly to:

```markdown
- [x] 015 Add aggregate, policy, projection/replay, release-backfill, inbound-route, authorisation, recipient-delivery, sender-non-following, and reply-authorisation tests.
```

Tasks 016–018 remain unchecked.

5. Todo structure

No tasks were split, added, removed, or reordered.

6. ADR conformance

- ADR 0002: aggregate decisions, immutable events, historical compatibility, and replay remain explicit.
- ADR 0007: Messaging continues resolving group membership through Membership’s public API rather than Membership projection schemas.
- ADR 0009: read-model and replay coverage uses the established Commanded Ecto projectors.
- ADR 0021: existing committed read-model publication behavior remains unchanged.
- ADR 0022: replay tests synchronize using captured per-projector positions and projection barriers, without sleeps or polling.