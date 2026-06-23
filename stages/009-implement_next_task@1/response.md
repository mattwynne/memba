Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 001 Add Messaging.list_conversations_for_club/1: a read-model query over`

2. **Changes made**
   - Added `Memba.Messaging.list_conversations_for_club/1`.
   - Query returns one row per root conversation for a club, including:
     - root `MessageProjection` as `:message`
     - root fields (`message_id`, `conversation_id`, `club_id`, `sender_id`, `subject`, `body`, timestamps)
     - `reply_count`
     - `latest_replier_id`
     - `latest_replier_name`
   - Conversations are ordered by root `inserted_at` descending, then root `message_id` descending.
   - Replies are counted by `conversation_id`, excluding the root row.
   - Latest replier is selected from replies by newest reply `inserted_at`, then `message_id`.
   - Latest replier name is resolved through `Membership.list_person_contact_summaries/1`.
   - Updated the Messaging no-CRUD API-shape test to include the new public query.
   - Added focused query tests covering grouping, reply count, latest replier, no-reply conversations, club scoping, and original-send-time ordering.

3. **Validation run**
   - `devenv shell -- bin/mix format lib/memba/messaging.ex test/memba/messaging/message_projection_test.exs test/memba/messaging/no_crud_spike_test.exs` — passed.
   - `devenv shell -- bin/mix test test/memba/messaging/message_projection_test.exs test/memba/messaging/no_crud_spike_test.exs` — passed, `11 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed, `906 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add Messaging.list_conversations_for_club/1: a read-model query over`
   - To:
     - `- [x] 001 Add Messaging.list_conversations_for_club/1: a read-model query over`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002 / CQRS: implemented as a side-effect-free query over read models.
   - ADR 0007: kept the query in the Messaging public context and used Membership’s public summary API for person names rather than joining Membership tables directly.
   - ADR 0009: queried Commanded Ecto projection storage (`MessageProjection`) without altering projection mechanics.
   - ADR 0021 / 0022: no read-model publication or projection-barrier behavior was changed; this task only adds a read query.