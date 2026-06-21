# Iteration 041 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation evidence shows conformance with the relevant accepted architectural decisions and project design guidance:

- Header-based reply routing follows the Topicbox-style decision: outbound `Message-ID` values are persisted, inbound `In-Reply-To` / `References` values are parsed, and recognized same-club headers route to an existing conversation.
- Missing, unknown, malformed, or different-club headers do not create cross-club replies and fall back to the existing new club-wide inbound path where appropriate.
- Reply posting reuses the existing messaging/reply/follower mechanisms rather than introducing a parallel delivery path.
- Auto-follow on reply follows the accepted optimistic query/command bridging pattern: query current following state, then issue the follow command after the reply succeeds.
- The implementation remains compatible with the event-sourced/CQRS shape of the app: durable state changes still flow through commands/events/projections, with read models used for lookup.

## ADR violations

1. None found.

## Blocking issues

1. None found.

## Bounded-safe fixes

1. **Move inbound conversation lookup behind the Messaging context**
   - File: `lib/memba_web/email/inbound_router.ex`
   - The inbound router appears to query `DeliveryReceipt` directly through `Repo`.
   - This works, but the Messaging context should own the read-model lookup rule for “given these RFC message IDs and this club, find the matching conversation.”
   - A small context function would reduce web-boundary coupling without changing behaviour.

2. **Deduplicate inbound message-id parsing**
   - Files:
     - `lib/memba_web/postmark_inbound_email_parser.ex`
     - `lib/memba_web/resend_inbound_email_parser.ex`
   - The provider parsers appear to carry similar logic for parsing `In-Reply-To` / `References`.
   - Extract the shared RFC message-id normalization into one small module so Postmark and Resend cannot drift as edge cases are added.

3. **Add lightweight documentation for inbound routing**
   - File: `lib/memba_web/email/inbound_router.ex`
   - This module now encodes an important product rule: one club address handles both new messages and replies, and headers decide which path applies.
   - Add a concise `@moduledoc` and internal comments describing:
     - same-club-only matching,
     - fallback-to-new-message behaviour,
     - rejection behaviour remaining delegated to the existing inbound pipeline,
     - the intentionally basic quoted-history stripping.

4. **Add explicit tests or documentation for the intended `message_id` invariant**
   - Files:
     - delivery receipt schema/projection/migration files
     - `lib/memba/messaging/member_message_email.ex`
   - The implementation depends on persisted outbound message IDs being reliable lookup keys.
   - Even if uniqueness is guaranteed by the generated format today, a focused test or schema-level comment would help future changes avoid accidentally weakening the invariant.

## Judgement-worthy non-blocking code-health findings

1. **Files: `lib/memba/messaging/member_message_email.ex`, delivery receipt persistence/projection**
   - **Smell:** The generated external `Message-ID` format appears to include implementation details such as delivery receipt identity and club slug.
   - **Why judgement may be needed:** Email headers are durable and externally visible in mailboxes/provider logs. This may be acceptable, especially if IDs are UUIDs, but it should be intentional. A future privacy/security review may prefer opaque random identifiers or hashes.

2. **Files: delivery receipt lookup path, `lib/memba_web/email/inbound_router.ex`**
   - **Smell:** Lookup appears to choose one matching delivery receipt using ordering/limit semantics.
   - **Why judgement may be needed:** This is deterministic, but if multiple candidate headers match different same-club conversations, the “newest matching receipt” may not be the semantically intended conversation. A human/product decision may eventually be needed on whether to prefer `In-Reply-To`, preserve header order, reject ambiguous matches, or keep newest-match behaviour.

3. **Files: delivery receipt schema/migration and inbound lookup path**
   - **Smell:** The uniqueness/scoping rule for persisted `message_id` values is not obviously encoded as a database invariant.
   - **Why judgement may be needed:** If each outbound delivery receipt should have a globally unique `message_id`, a partial unique index may be appropriate. If multiple delivery records may intentionally share one RFC `Message-ID`, then uniqueness should not be enforced and the lookup semantics should document that. That distinction is architectural enough to merit human confirmation before changing constraints.

4. **File: `lib/memba_web/email/inbound_router.ex`**
   - **Smell:** Quoted-history stripping is intentionally heuristic.
   - **Why judgement may be needed:** The plan allowed basic stripping, so this is not blocking. Real clients vary widely across HTML-only replies, localized “wrote:” markers, mobile signatures, and forwarded chains. This may become a UX follow-up after production use.

5. **Files: inbound reply routing path**
   - **Smell:** Recognized member replies appear to be accepted without additional rate limiting, spam checks, or autoresponder-loop protection beyond the existing inbound provider/member trust model.
   - **Why judgement may be needed:** This matches the iteration scope and existing trust model, but reply-by-email makes high-volume posting easier if a mailbox is compromised or an autoresponder loops. Product/security should decide whether monitoring is sufficient or whether rate limits are needed later.

6. **File: `lib/memba_web/email/inbound_router.ex`**
   - **Smell:** The router is accumulating several responsibilities: club/address routing, sender authorization handoff, header matching, quoted-body extraction, reply command dispatch, fallback-to-new-message dispatch, and auto-follow orchestration.
   - **Why judgement may be needed:** It is still acceptable for this iteration, but if more inbound behaviours are added, splitting out a header matcher and reply body extractor would help preserve responsibility boundaries.

## Suggested fixes

For the bounded-safe items, suggested concrete changes:

1. Add a Messaging context function, for example:
   - `Memba.Messaging.find_conversation_by_message_ids(club_id, message_ids)`
   - Return `{:ok, conversation}` or `{:error, :not_found}`.
   - Keep the current same-club constraint and non-null conversation constraint.
   - Update `InboundRouter` to call the context rather than querying `DeliveryReceipt` directly.

2. Extract shared header parsing:
   - Add a small module such as `MembaWeb.Email.HeaderParser` or a provider-neutral messaging/email helper.
   - Responsibilities:
     - normalize angle-bracketed message IDs,
     - handle folded whitespace and comma/space-separated `References`,
     - drop blanks,
     - preserve candidate order,
     - optionally deduplicate while preserving first occurrence.
   - Keep provider-specific payload validation in the Postmark/Resend parser modules.

3. Document routing strategy:
   - Add a concise `@moduledoc` to `MembaWeb.Email.InboundRouter`.
   - Avoid adding `@doc` to private functions; prefer internal comments or public documentation on any extracted/context function.

4. Clarify the `message_id` invariant:
   - If each persisted non-null `message_id` must be unique, consider a partial unique index after confirming current/future fan-out semantics.
   - If not, add tests/comments that explain the allowed multiplicity and how inbound lookup remains deterministic.

## Validation notes

- The provided `dev ci` / dev check run passed.
- Acceptance suite passed: `82 scenarios`, `493 steps`.
- Review evidence shows coverage for:
  - outbound Memba-controlled `Message-ID` generation and persistence,
  - `Reply-To`, `In-Reply-To`, and `References` email headers,
  - Postmark and Resend inbound header parsing,
  - same-club conversation matching,
  - no cross-club reply routing,
  - fallback to new club-wide inbound message when no recognized same-club header exists,
  - non-member / ambiguous / malformed inbound rejection paths,
  - reply attribution, auto-follow, and follower fan-out,
  - basic quoted-history stripping.
- No evidence of acceptance criteria being weakened.
- Working tree was clean at review start, and this review made no file changes.