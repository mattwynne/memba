1. **Selected todo line**
   - `002 Set reply email headers: club/reply emails should route normal replies to <club-slug>@clubs.memba.io; reply notification emails should set In-Reply-To / References so email clients thread and Memba can recognize the conversation on inbound.`

2. **Changes made**
   - Updated member-message email reply behavior:
     - Club-message/reply emails now use the club inbound address via `Memba.ClubInboundEmailAddress.address/1` for `Reply-To` when a valid `club_slug` is present.
     - Kept sender-address fallback for requests missing a valid club slug.
   - Added reply threading support:
     - `EmailDeliveryRequest` now carries `in_reply_to_outbound_message_id` and `references_outbound_message_ids`.
     - `EmailDeliveryDispatcher` resolves reply-thread header IDs from previous outbound delivery records, preferring the same recipient’s prior delivery and falling back to the first known delivery for that message.
     - Local, Postmark, and Resend providers set `In-Reply-To` and `References` headers for reply notifications.
   - Updated email copy for club-addressable emails so the hint no longer says replies go only to the sender.
   - Added/updated tests covering:
     - Dispatcher-populated threading reference fields.
     - Same-recipient and fallback outbound reference lookup.
     - Local/Postmark/Resend `Reply-To`, `Message-ID`, `In-Reply-To`, and `References` headers.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...` — passed for touched Elixir files.
   - Attempted focused test command:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs`
     - Did not reach tests because the sandbox mix wrapper failed its Postgres readiness check with the existing `PGHOST=/tmp/devenv/postgres` mismatch.
   - Final broad validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick` — passed on final diff: `874 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Set reply email headers...`
     - to:
     - `- [x] 002 Set reply email headers...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs are explicitly referenced by the plan.
   - Relevant accepted ADRs inspected/respected:
     - ADR 0004: kept delivery-related state and lookup around existing message/email-delivery read models.
     - ADR 0005: preserved resolved-recipient delivery shape; no recipient resolution moved into providers.
     - ADR 0016: preserved switchable provider boundary and Swoosh-based Local/Postmark/Resend paths; no direct provider HTTP code added.