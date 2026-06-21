# Iteration 041 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to obey the binding architectural decisions relevant to reply-by-email threading:

- **ADR-0048 / Topicbox-style routing:** The implementation uses outbound Memba-controlled `Message-ID` values, persists them, sets `Reply-To`, `In-Reply-To`, and `References` headers where appropriate, parses inbound reply headers, restricts matches to the same club, and falls back to the existing new club-wide inbound path when no recognized same-club header exists.
- **ADR-0050 / optimistic query-command bridging:** The inbound reply path appears to query existing follow state before issuing the follow command after the reply succeeds, rather than replacing the event-sourced command path with a local shortcut.
- The implementation stays broadly aligned with the project’s CQRS/event-sourcing/read-model guidance: durable state changes continue to flow through existing messaging/conversation commands and projections, while persisted outbound email metadata is used as a read-side lookup key.

## ADR violations

None found.

## Blocking issues

None found.

The plan-conformance and behavioural gates appear satisfied, and the remaining concerns are maintainability or future-design smells rather than merge blockers.

## Bounded-safe fixes

1. **Extract inbound message-id conversation lookup into a named helper**
   - File: `web/lib/memba/messaging.ex`
   - Evidence indicates `route_inbound_club_email/1` owns the correct context boundary, but still contains inline read-model lookup logic against persisted email delivery metadata.
   - A private helper such as `find_conversation_by_message_ids/2` would make the routing policy clearer and easier to test/review without changing behaviour.

2. **Deduplicate inbound RFC message-id parsing across providers**
   - Files:
     - `web/lib/memba_web/postmark_inbound_email_parser.ex`
     - `web/lib/memba_web/resend_inbound_email_parser.ex`
   - Both provider parsers appear to carry similar logic for extracting and normalizing `In-Reply-To` / `References` message IDs.
   - Extracting the shared parsing into a small provider-neutral helper would reduce divergence risk as real-world email header edge cases are discovered.

3. **Document inbound routing strategy and invariants**
   - File: `web/lib/memba/messaging.ex`
   - `route_inbound_club_email/1` now encodes an important product/architecture rule: the same club address handles new messages and replies, with recognized same-club headers deciding the reply path.
   - Add concise documentation covering:
     - same-club-only header matching,
     - fallback to new club-wide messages,
     - unchanged sender authorization/rejection behaviour,
     - basic quoted-history stripping limitations.

4. **Add an explicit test for outbound `Message-ID` uniqueness**
   - Files:
     - `web/lib/memba/messaging/projections/email_delivery.ex`
     - relevant migration/test module under `web/test/memba/messaging/`
   - The implementation relies on persisted outbound message IDs being deterministic lookup keys.
   - If the migration already enforces uniqueness for non-null `outbound_message_id`, add a focused DB constraint test documenting that invariant.

## Judgement-worthy non-blocking code-health findings

1. **Files: `web/lib/memba/messaging/member_message_email.ex`, email delivery projection**
   - **Smell:** The outbound `Message-ID` format appears to include internal implementation details such as delivery identity and/or club slug.
   - **Why it may need human judgement:** Email headers are externally visible and durable in user mailboxes and provider logs. This may be acceptable, but privacy/security should intentionally decide whether opaque random identifiers would be preferable.

2. **File: `web/lib/memba/messaging.ex`**
   - **Smell:** Inbound routing appears to select a matching delivery/conversation using ordering/limit semantics.
   - **Why it may need human judgement:** This is safe if persisted outbound message IDs are globally unique. If multiple candidate headers can match different same-club conversations, product/architecture may eventually need to decide whether to prefer `In-Reply-To`, preserve header order, reject ambiguity, or keep newest-match semantics.

3. **File: `web/lib/memba/messaging.ex`**
   - **Smell:** Quoted-history stripping is intentionally heuristic.
   - **Why it may need human judgement:** The plan explicitly allowed basic stripping, so this is not blocking. Real email clients vary widely across HTML-only replies, localized quote markers, mobile signatures, forwarded messages, and nested chains. This may become a UX follow-up after production use.

4. **Files: inbound reply routing path in `web/lib/memba/messaging.ex`**
   - **Smell:** Recognized member replies appear to be accepted without additional reply-specific rate limiting, spam checks, or autoresponder-loop protection beyond the existing inbound trust model.
   - **Why it may need human judgement:** This matches current scope, but reply-by-email lowers posting friction and may increase risk from compromised mailboxes or autoresponders.

5. **File: `web/lib/memba/messaging.ex`**
   - **Smell:** `route_inbound_club_email/1` is accumulating responsibilities: club/address routing, sender authorization handoff, header matching, body extraction, reply command dispatch, fallback dispatch, auto-follow orchestration, and quote stripping.
   - **Why it may need human judgement:** Still acceptable for this iteration, but future inbound behaviours such as attachments, mentions, moderation, or richer threading could make this function a maintenance hotspot.

6. **Files: inbound parser tests**
   - **Smell:** Header parsing coverage appears good for common cases but necessarily limited for RFC/email-client edge cases.
   - **Why it may need human judgement:** Email parsing is notoriously irregular. Production observations should drive whether to expand tests for folded headers, comments, unusual quoting, internationalized addresses, and provider-specific payload variants.

## Suggested fixes

For the bounded-safe items:

1. Add a private helper in `Memba.Messaging`, for example:
   - `find_conversation_by_message_ids(club_id, message_ids)`
   - Keep the same same-club and non-null conversation constraints.
   - Return `{:ok, conversation_id}` / `{:error, :not_found}` or an equivalent internal shape.

2. Add a shared parser module, for example:
   - `MembaWeb.InboundEmailHeaders` or `MembaWeb.Email.HeaderParser`
   - Responsibilities:
     - extract `Message-ID`, `In-Reply-To`, and `References`,
     - normalize angle-bracketed IDs,
     - handle folded whitespace and comma/space-separated references,
     - drop blanks,
     - preserve candidate order,
     - optionally deduplicate while preserving first occurrence.
   - Keep provider-specific payload validation in the Postmark/Resend parser modules.

3. Add concise documentation near `route_inbound_club_email/1` explaining the ADR-driven routing strategy and fallback semantics.

4. Add a focused constraint test proving duplicate non-null outbound message IDs are rejected, assuming that is the intended invariant.

## Validation notes

- `dev ci` / dev check passed before this review.
- Acceptance suite passed: `82 scenarios`, `493 steps`.
- ExUnit suite passed: `891 tests`, `0 failures`.
- Evidence shows coverage for:
  - outbound persisted `Message-ID` generation,
  - reply email headers,
  - Postmark and Resend inbound header parsing,
  - same-club reply matching,
  - no cross-club reply routing,
  - fallback to new club-wide inbound messages,
  - non-member / ambiguous / malformed inbound rejection paths,
  - reply attribution,
  - auto-follow on reply,
  - follower fan-out,
  - basic quoted-history stripping.
- Acceptance feature files appear unchanged.
- The attempted review-repair stage reported no final working-tree diff, so the bounded-safe maintainability improvements remain recommendations rather than already-applied fixes. This does not change the acceptance decision.