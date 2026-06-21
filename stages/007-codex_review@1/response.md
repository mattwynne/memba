# Iteration 041 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to conform to the iteration plan and the governing architectural decisions:

- Header-based reply routing follows the Topicbox-style decision: standard `Message-ID`, `In-Reply-To`, and `References` headers are used to decide whether inbound email is a reply or a new club-wide message.
- Same-club matching is enforced, avoiding cross-club reply routing.
- Missing or unrecognized reply headers fall back to the existing new-message inbound path.
- Reply posting reuses the existing conversation/reply/follower behaviour rather than introducing a parallel local mechanism.
- Auto-follow on reply appears to follow the accepted optimistic query/command bridging pattern: query current following state, then issue the follow command after the reply succeeds.
- Event-sourced / CQRS boundaries appear broadly preserved: commands/events/projections remain the source of durable behaviour, with read models used for lookup and email delivery metadata.

## ADR violations

None found.

## Blocking issues

None found.

## Bounded-safe fixes

1. **Move inbound conversation lookup behind the Messaging context**
   - Evidence indicates `MembaWeb.Email.InboundRouter` performs a direct `Repo` query against `DeliveryReceipt` to resolve inbound header message IDs.
   - This works, but it couples the web/inbound boundary to a messaging read-model schema.
   - A bounded improvement would be to expose a context function such as `Memba.Messaging.find_conversation_by_message_ids/2` or similar.

2. **Deduplicate RFC message-id parsing between provider parsers**
   - `MembaWeb.PostmarkInboundEmailParser` and `MembaWeb.ResendInboundEmailParser` appear to contain similar parsing logic for `In-Reply-To` / `References`.
   - Extracting the shared logic into a small module such as `MembaWeb.Email.HeaderParser` would reduce divergence risk as additional providers or header quirks are added.

3. **Add lightweight documentation around inbound routing**
   - `MembaWeb.Email.InboundRouter` is now responsible for an important product rule: same address, header-decided reply-vs-new routing.
   - A concise `@moduledoc` explaining:
     - header-based matching,
     - same-club restriction,
     - fallback-to-new-message behaviour,
     - and quoted-history stripping limitations
     would help future maintainers preserve the ADR intent.

4. **Consider making the delivery receipt message-id invariant explicit**
   - The implementation persists outbound `Message-ID` values and looks them up later.
   - If the intended invariant is “each persisted outbound `message_id` is globally unique,” that should be enforced at the database/schema level where practical, likely with a partial unique index on non-null `message_id`.
   - If uniqueness is only scoped differently, the context API/query should document that explicitly.

## Judgement-worthy non-blocking code-health findings

1. **File(s): `lib/memba_web/email/inbound_router.ex` — web-layer coupling to messaging read model**
   - **Smell:** The inbound router appears to know about `DeliveryReceipt` lookup details.
   - **Why judgement may be needed:** This may be acceptable for a thin integration boundary, but it slightly weakens the Messaging context as the owner of message/conversation lookup rules. If more inbound channels are added, this coupling may spread.

2. **File(s): `lib/memba_web/postmark_inbound_email_parser.ex`, `lib/memba_web/resend_inbound_email_parser.ex` — duplicated email header parsing**
   - **Smell:** Provider parsers contain similar logic for parsing message IDs out of mail headers.
   - **Why judgement may be needed:** Duplication is currently small and tested, but RFC email header parsing tends to accumulate edge cases. A shared parser would make behaviour more consistent across providers.

3. **File(s): `lib/memba/messaging/member_message_email.ex`, delivery receipt projection/schema — external `Message-ID` format and persistence**
   - **Smell:** The generated `Message-ID` format is now externally visible and durable.
   - **Why judgement may be needed:** If the format exposes internal IDs, club slugs, or sequencing, that may be acceptable but should be intentional. External identifiers in email headers tend to live forever in user mailboxes and provider logs.

4. **File(s): `lib/memba_web/email/inbound_router.ex` — basic quoted-history stripping**
   - **Smell:** Quote stripping is intentionally heuristic.
   - **Why judgement may be needed:** The plan explicitly allowed basic stripping, so this is not blocking. However, real mail clients vary significantly, especially for HTML-only replies, localized quote markers, mobile signatures, and forwarded/replied chains. This may become a UX issue after launch.

5. **File(s): delivery receipt lookup path — duplicate `message_id` handling**
   - **Smell:** If lookup orders by newest receipt and limits to one result, duplicates would route deterministically but perhaps not semantically correctly.
   - **Why judgement may be needed:** This is harmless if `message_id` uniqueness is guaranteed by generation plus storage constraints. If not, a malformed projection, replay bug, or manual data repair could silently misroute replies.

6. **File(s): inbound email reply path — abuse/rate-limit posture**
   - **Smell:** Authenticated inbound replies from recognized members appear to be accepted without additional rate limiting beyond existing provider/member trust.
   - **Why judgement may be needed:** This matches the current inbound trust model and is not part of iteration 041, but reply-by-email increases the ease of high-volume posting if an address is compromised or an autoresponder loop occurs.

## Suggested fixes

For the bounded-safe items, suggested concrete changes:

1. **Add a Messaging context lookup function**
   - Move the `DeliveryReceipt` query out of `MembaWeb.Email.InboundRouter`.
   - Suggested shape:
     - `Memba.Messaging.find_conversation_by_message_ids(club_id, message_ids)`
     - Return `{:ok, conversation}` or `{:error, :not_found}`.
   - Keep the same same-club and non-null conversation constraints.
   - Update router tests to assert behaviour through the router, not query internals.

2. **Extract shared header parsing**
   - Add a small module, for example:
     - `MembaWeb.Email.HeaderParser`
   - Responsibilities:
     - normalize angle-bracketed message IDs,
     - handle folded/whitespace/comma-separated values,
     - return a deduplicated ordered list of candidate message IDs.
   - Use it from both Postmark and Resend parsers.
   - Keep provider-specific payload validation in the provider parser modules.

3. **Document inbound routing strategy**
   - Add a short `@moduledoc` to `MembaWeb.Email.InboundRouter`.
   - Include the key invariant: only recognized same-club headers route to an existing conversation; otherwise the message is treated as a new club-wide inbound message.

4. **Clarify/enforce message-id uniqueness**
   - If safe for current data, add a partial unique database index on `delivery_receipts.message_id` where not null.
   - If not safe yet, add a follow-up note or test that documents expected uniqueness from the generator/projection path.

## Validation notes

- `dev ci` / dev check passed before this review.
- Acceptance suite passed: `82 scenarios`, `493 steps`.
- The implementation evidence shows coverage for:
  - outbound persisted `Message-ID` generation,
  - reply headers including `Reply-To`, `In-Reply-To`, and `References`,
  - Postmark and Resend inbound header parsing,
  - matched reply routing into an existing conversation,
  - fallback to new club-wide message when headers do not match,
  - same-club restriction,
  - non-member / ambiguous / malformed inbound rejection paths,
  - reply fan-out and auto-follow behaviour.
- No blocking plan-fidelity gap found.
- No ADR conflict found.