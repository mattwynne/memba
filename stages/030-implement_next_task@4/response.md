1. **Selected todo line**

   `- [ ] 004 Add/extend projector(s) and read APIs to load a conversation (root + ordered replies).`

2. **Changes made for task 004 only**

   - Added `Memba.Messaging.list_conversation_messages/1`.
     - Accepts either a root message id or a reply message id.
     - Returns the root message first, then replies ordered by projected post time and message id.
     - Returns `[]` for invalid, missing, or orphaned projections.
   - Reused the conversation fields already projected in task 003 (`conversation_id`, `reply_to_message_id`); no write-model changes.
   - Added projection/read API tests covering:
     - root + replies in order;
     - loading the conversation from a reply id;
     - invalid/missing ids;
     - orphaned reply projections without a root.
   - Updated the Messaging public API allowlist test to include the new query API.
   - Checked off only task 004 in `todo.md`.

3. **Focused validation commands/results**

   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/messaging.ex test/memba/messaging/message_projection_test.exs --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/message_projection_test.exs`
     - Passed: `6 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/messaging.ex test/memba/messaging/message_projection_test.exs test/memba/messaging/no_crud_spike_test.exs --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/no_crud_spike_test.exs test/memba/messaging/message_projection_test.exs`
     - Passed: `10 tests, 0 failures`.
   - First `PATH="$PWD/bin:$PATH" dev check --quick`
     - Failed on the public API allowlist expecting no `list_conversation_messages/1`.
     - Fixed by updating `no_crud_spike_test.exs`.
   - Rerun `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `840 tests, 0 failures`.

4. **Exact todo check-off made**

   Changed:

   `- [ ] 004 Add/extend projector(s) and read APIs to load a conversation (root + ordered replies).`

   to:

   `- [x] 004 Add/extend projector(s) and read APIs to load a conversation (root + ordered replies).`

5. **Todo splits/additions/reordering**

   None.

6. **ADR / architecture conformance evidence**

   - Kept the change on the CQRS read side: a public query reads from `MessageProjection`; no command semantics changed.
   - Preserved event-sourced write behavior and existing Commanded projector flow.
   - Used the existing projected conversation metadata from prior tasks instead of introducing CRUD tables or direct write-side reads.
   - Kept the public Messaging API explicit and updated the no-CRUD guard test accordingly.
   - Did not implement task 005 UI/LiveView work or task 006 acceptance scenario work.