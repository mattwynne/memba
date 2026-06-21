1. **Selected todo line**
   - `004 Extend inbound routing: before creating a new club-wide message, attempt a same-club header match; when found, post via the 039 reply path, apply current-member authorization, auto-follow the replier, fan out to followers, and apply basic quoted-history stripping.`

2. **Changes made**
   - Updated `Memba.Messaging.receive_inbound_club_email/2` routing so authorized inbound club email now:
     - normalizes/strips the plain-text body using the existing inbound body policy,
     - checks parsed `In-Reply-To` first, then `References` newest/rightmost first,
     - resolves stored outbound `Message-ID` mappings with `get_outbound_message_reference/1`,
     - only treats a match as a reply when the outbound message belongs to the addressed club,
     - posts matched mail through the existing `post_message_reply/2` path,
     - records the inbound email as accepted against the created reply message.
   - Preserved the existing new club-wide message path when no same-club reply header matches.
   - Added an integration test proving a recognized same-club reply header:
     - posts into the existing conversation,
     - attributes the reply to the inbound sender,
     - strips quoted history,
     - fans out only to current followers except the replier,
     - auto-follows the replier through existing reply projection behavior,
     - records the inbound source as accepted.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging.ex test/memba/messaging/inbound_club_message_acceptance_test.exs` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors` — passed.
   - Focused `bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs:178` was attempted but blocked by the sandbox Postgres socket/lock readiness issue.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed: `879 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly task `004` from `- [ ]` to `- [x]`.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004/0005: inbound replies reuse the existing message aggregate and `post_message_reply/2` command path; reply recipients remain resolved before dispatch.
   - ADR 0007: membership/current-member authorization continues through Membership public APIs and existing inbound authorization flow; no direct Membership storage coupling added.
   - ADR 0016: routing uses provider-neutral `InboundEmail` reply-header fields and does not add provider-specific behavior.
   - ADR 0022: tests and implementation use existing strong-consistency/projection patterns; no new synchronization mechanism introduced.