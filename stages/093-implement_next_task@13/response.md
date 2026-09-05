Implemented and checked off task 013:

> Add public Messaging queries that list conversations and read a conversation through a supplied group ID and its access grant.

Changes:

- Added `Messaging.list_conversations_for_group/1` in [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:377).
  - Returns only conversations with a read-capable grant for the supplied group.
  - Treats write access as including read access.
  - Preserves existing overview ordering, reply counts, participants, and latest-replier enrichment.
- Added `Messaging.list_conversation_messages_for_group/2` in [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:417).
  - Accepts either a root or reply message ID.
  - Authorizes through the canonical root conversation’s grant.
  - Returns the complete root-first thread.
- Both APIs fail closed for invalid IDs, missing projections, missing grants, and cross-club access rows.
- Kept person/group membership authorization as a caller responsibility; the queries establish access through a supplied group grant only.
- Added focused coverage in [message_projection_test.exs](/workspace/memba/web/test/memba/messaging/message_projection_test.exs:366), including read/write grants, group isolation, shared conversations, reply-ID lookup, malformed IDs, and cross-club protection.
- Updated the public query API architecture assertion in [no_crud_spike_test.exs](/workspace/memba/web/test/memba/messaging/no_crud_spike_test.exs:13).

Validation:

- Initial test-first run: 16 tests, 6 expected undefined-function failures.
- Focused Messaging tests:
  - `dev test test/memba/messaging/conversation_group_access_projection_test.exs test/memba/messaging/message_projection_test.exs test/memba/messaging/no_crud_spike_test.exs`
  - 21 tests, 0 failures.
- `git diff --check`: passed.
- `dev check --quick` completed formatting and compilation, but its ExUnit output still reports the previously known unrelated `MembaWeb.DevTestSupportControllerTest` projection consistency timeout: 1,114 tests, 1 failure. A focused rerun reproduced that same timeout. I did not expand task 013 to alter that test infrastructure.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:15):

```markdown
- [x] 013 Add public Messaging queries that list conversations and read a conversation through a supplied group ID and its access grant.
```

No todo tasks were split, added, reordered, or otherwise checked off.

ADR conformance:

- ADR 0002/0009: queries use the existing Ecto read projections rather than aggregates or event streams.
- ADR 0007: Messaging joins only its own message and conversation-access projections; Membership remains behind its public API for replier-name enrichment.
- ADR 0021: no new projector or notification path was introduced.
- ADR 0022: task tests use projection-backed fixtures, avoiding hidden synchronization or side effects in query functions.