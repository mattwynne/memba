1. **Selected todo line**

   `- [ ] 003 Deliver the reply by email to every current member (excluding the author) by reusing the send_club_message delivery + receipt path; build the reply email on the shared transactional layout/footer with <club> via Memba sender and conversation context.`

2. **Changes made for task 003 only**

   - Reply fan-out now resolves current club members **excluding the reply author**.
   - Updated the `Message` aggregate recipient validation so:
     - root `SendMessage` still requires the sender to be among recipients;
     - `PostMessageReply` rejects recipients that include the author;
     - replies can have zero email recipients after excluding the author.
   - Added conversation metadata to the message projection:
     - migration: `conversation_id`, `reply_to_message_id`;
     - projector stores conversation references from `MessageSent`.
   - Extended delivery request construction so reply email provider requests include:
     - conversation id;
     - replied-to message id;
     - conversation URL;
     - replied-to sender/body context where available.
   - Updated member-message email rendering:
     - original club messages preserve existing sender-based email shape;
     - replies render as reply notifications from `<club name> via Memba`;
     - reply subjects use `Re: ...`;
     - reply HTML uses the shared transactional shell/footer, includes conversation context, CTA, and quoted replied-to context;
     - reply text bodies include conversation context too.
   - Updated Local/Postmark/Resend providers to use shared `MemberMessageEmail.text_body/1`.
   - Updated tests for reply delivery, delivery receipts, dispatcher request context, reply email rendering, and projection/test helpers affected by the new non-null projection field.
   - Checked off only task 003 in `todo.md`.

3. **Focused validation commands/results**

   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Result: passed after manual formatting fixes.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/message_test.exs test/memba/messaging/message_projection_test.exs test/memba/messaging/post_message_reply_test.exs test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs test/memba/messaging/send_club_message_test.exs test/memba_web/live/admin_operations_index_live_test.exs`
     - Result: `76 tests, 0 failures`.
   - Broad quick validation:
     - First `PATH="$PWD/bin:$PATH" dev check --quick` surfaced test helper inserts missing the new non-null `conversation_id`; fixed those helpers.
     - Rerun `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `837 tests, 0 failures`.

   I did not run full `dev check` for this task because the selected task changed backend/email behaviour, not browser-facing routes/LiveView/feature files; the final full check remains task 007.

4. **Exact todo check-off made**

   Changed:

   `- [ ] 003 Deliver the reply by email to every current member (excluding the author) by reusing the send_club_message delivery + receipt path; build the reply email on the shared transactional layout/footer with <club> via Memba sender and conversation context.`

   to:

   `- [x] 003 Deliver the reply by email to every current member (excluding the author) by reusing the send_club_message delivery + receipt path; build the reply email on the shared transactional layout/footer with <club> via Memba sender and conversation context.`

5. **Todo splits/additions/reordering**

   None.

6. **ADR conformance evidence**

   - **ADR 0002 / 0008:** reply delivery remains event-sourced through Commanded commands/events and persistent EventStore-backed projections.
   - **ADR 0004:** preserved one `Message` aggregate per root/reply message; reply delivery receipts remain owned by the reply message aggregate stream.
   - **ADR 0005:** recipient resolution remains outside the aggregate and is supplied on the command; task-specific change narrows reply recipients to current members excluding the author.
   - **ADR 0007:** Messaging continues to use Membership’s public APIs for active member, club, and person context lookups.
   - **ADR 0009:** conversation metadata needed for delivery email context is projected via Commanded Ecto projections.
   - **ADR 0011:** reply/message/delivery identities remain caller-generated UUIDs.