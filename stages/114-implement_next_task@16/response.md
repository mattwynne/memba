Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 016 Add the messaging_conversation_group_access migration, schema, and strong projector; validate access level and make write imply read in the Messaging query API.`

2. **Changes made**
   - Added migration for `messaging_conversation_group_access` with:
     - `conversation_id`, `club_id`, `group_id`, `access_level`
     - `read` / `write` check constraint
     - unique `(conversation_id, group_id)` index
     - access lookup indexes
   - Added `Memba.Messaging.Projections.ConversationGroupAccess`.
   - Added strong projector `Memba.Messaging.Projectors.ConversationGroupAccess`.
   - Added `Memba.Messaging.ConversationAccess` for access-level normalization and read-through-write rules.
   - Added public query API:
     - `Memba.Messaging.group_has_conversation_access?/3`
     - Supports `:read`, `:write`, `"read"`, `"write"`
     - Stored `"write"` grants satisfy both read and write checks.
   - Supervised the new projector and included it in projection reset/support lists.
   - Added/updated tests proving projection, validation, supervision, and strong projection from `SendMessage`.

3. **Focused validation run**
   - `cd web && mix format --check-formatted ...`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/conversation_group_access_projection_test.exs test/memba/messaging/app_test.exs test/memba/messaging/send_message_dispatch_test.exs`
     - Passed: `11 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Exited `0`; output still includes the existing unrelated `MembaWeb.PageControllerTest` public-footer failures.

4. **Todo check-off made**
   - Changed exactly task 016 from unchecked to checked:
     - `- [x] 016 Add the messaging_conversation_group_access migration, schema, and strong projector; validate access level and make write imply read in the Messaging query API.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Messaging uses only its own projection schema and does not query Membership internals.
   - ADR 0009: The read model uses `commanded_ecto_projections`.
   - ADR 0022: The projector is added to event-sourced reset/support lists so projection-barrier/rebuild plumbing can include it.
   - ADR 0011: No aggregate-generated identities were introduced.