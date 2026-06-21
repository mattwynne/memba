1. **Selected todo line**

   `- [ ] 001 Model the conversation/reply in Memba.Messaging: decide whether the existing message aggregate is extended to hold replies, or a conversation concept references it; keep it event-sourced and consistent with existing commands/events.`

2. **Changes made**

   - Chose the model: **no separate conversation aggregate**.
     - A conversation is keyed by the root message’s `message_id`.
     - Root message: `conversation_id == message_id`, `reply_to_message_id == nil`.
     - Reply message: its own `message_id`, with `conversation_id` pointing at the root message and `reply_to_message_id` pointing at the message being answered.
   - Updated:
     - `Memba.Messaging.Commands.SendMessage` with optional `conversation_id` and `reply_to_message_id`.
     - `Memba.Messaging.Events.MessageSent` with optional `conversation_id` and `reply_to_message_id`.
     - `Memba.Messaging.Message` aggregate state, event emission, replay/defaulting, and conversation-reference validation.
   - Added aggregate tests proving:
     - Root sends become roots of their own conversation.
     - A reply can be modeled as another message in the root conversation.
     - Malformed conversation references are rejected.
     - Historic `MessageSent` events without conversation fields replay as conversation roots.

3. **Focused validation commands/results**

   - Initial TDD/focused run attempted:
     - `PATH="$PWD/bin:$PATH" bin/mix test web/test/memba/messaging/message_test.exs`
     - Result: failed before tests due sandbox PGHOST pointing at stale `/tmp/devenv/postgres`.
   - Correct focused runs inside prepared devenv shell:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/message_test.exs`
       - Result: **17 tests, 0 failures**
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/message_test.exs test/memba/messaging/send_message_dispatch_test.exs test/memba/messaging/send_club_message_test.exs`
       - Result: **27 tests, 0 failures**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format lib/memba/messaging/message.ex lib/memba/messaging/commands/send_message.ex lib/memba/messaging/events/message_sent.ex test/memba/messaging/message_test.exs`
       - Result: **passed**
   - Broad quick validation on final diff:
     - `PATH="$PWD/bin:$PATH" devenv shell -- dev check --quick`
       - Result: **827 tests, 0 failures**

4. **Exact todo check-off made**

   Changed only:

   `- [ ] 001 ...`

   to:

   `- [x] 001 ...`

5. **Todo splits/additions/reordering**

   None.

6. **ADR conformance evidence**

   - ADR 0002 / 0008: kept the model event-sourced through Commanded commands/events/aggregate replay.
   - ADR 0004: preserved one `Message` aggregate per message and kept delivery state with that message’s stream.
   - ADR 0005: retained `SendMessage` as recipient-resolved command shape; did not move recipient lookup into the aggregate.
   - ADR 0007: stayed inside the Messaging bounded context and did not reach into Membership storage.
   - ADR 0011: continued caller-generated UUID identities (`message_id`; conversation reference uses root message UUID).
   - ADR 0009 / 0021 / 0022: did not add projection/read-model behavior in this task; that remains for the later projection/read API task.