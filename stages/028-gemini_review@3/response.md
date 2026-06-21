# Iteration 041 Review — Reply-by-email threading

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation conforms to the architectural shape required for this iteration:

- **ADR-0048 / Topicbox-style reply routing**: The implementation uses standard email headers to distinguish replies from new inbound club-wide messages, persists Memba-controlled outbound `Message-ID` values, parses inbound `In-Reply-To` / `References`, restricts matches to the same club, and falls back to the existing new-message path when no recognized same-club header exists.
- **ADR-0050 / optimistic query-command bridging**: The reply-by-email flow appears to preserve the event-sourced command path. Auto-follow behaviour is handled by querying current state and issuing the normal follow command after a successful reply, rather than directly mutating read models.
- **CQRS / event-sourcing / DDD fit**: Durable state changes continue to flow through the Messaging command/projection paths. The persisted outbound email metadata is used as a read-side lookup key, which is appropriate for this routing concern.

## ADR violations

None found.

## Blocking issues

None found.

The earlier synthesized “review blockers” appear to have been maintainability checks rather than actual blockers. The repair pass inspected `HEAD` and found those items already present, producing no application diff. The failed `verify_review_repair` stage failed because it expected a diff from the repair step, not because of an implementation defect.

## Bounded-safe fixes

1. **None required before merge.**

   The four previously synthesized bounded-safe items appear already satisfied in the committed implementation:

   - Inbound message-id lookup is contained within the `Memba.Messaging` context.
   - Provider-neutral header parsing exists via `MembaWeb.InboundEmailHeaders`, with Postmark and Resend parsers delegating to it.
   - Inbound routing strategy is documented on/near `receive_inbound_club_email/2`.
   - Persisted outbound `Message-ID` uniqueness is enforced and covered by a focused constraint test.

## Judgement-worthy non-blocking code-health findings

1. **Files:** `web/lib/memba/messaging/member_message_email.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`  
   **Smell:** Outbound `Message-ID` format may expose implementation details such as club slug and/or delivery identity.  
   **Why judgement may be needed:** Email headers are externally visible and durable in inboxes, forwards, provider logs, and support artifacts. This may be acceptable, but privacy/security may eventually prefer opaque random identifiers.

2. **File:** `web/lib/memba/messaging.ex`  
   **Smell:** Conversation matching appears to rely on ordering/limit semantics when multiple recognized message-id candidates are present.  
   **Why judgement may be needed:** This is safe if `outbound_message_id` is globally unique and each candidate maps deterministically. If real-world `References` chains contain multiple Memba-recognized messages from different same-club conversations, product/architecture may need to decide whether to prefer `In-Reply-To`, preserve header order, reject ambiguity, or keep newest-match behaviour.

3. **File:** `web/lib/memba/messaging.ex`  
   **Smell:** Quoted-history stripping is intentionally heuristic.  
   **Why judgement may be needed:** The plan explicitly allowed basic stripping, so this is not blocking. Real clients vary widely across HTML-only replies, localized quote markers, signatures, forwarded chains, and nested quotes. Production feedback may justify a stronger reply-parser later.

4. **File:** `web/lib/memba/messaging.ex` / inbound reply path  
   **Smell:** Recognized member replies are accepted without reply-specific rate limiting, autoresponder-loop detection, or additional spam controls beyond the current inbound trust model and member authorization.  
   **Why judgement may be needed:** This matches iteration scope, but reply-by-email lowers posting friction and can amplify compromised mailboxes, vacation responders, or mail loops.

5. **File:** `web/lib/memba/messaging.ex`  
   **Smell:** The inbound club email routing path is accumulating responsibilities: club/address routing, sender authorization handoff, header matching, body extraction, reply dispatch, fallback dispatch, auto-follow orchestration, and quote stripping.  
   **Why judgement may be needed:** Still acceptable for this iteration. If future inbound features add attachments, moderation, mentions, richer threading, or abuse controls, this area may warrant extraction into smaller collaborators.

6. **Files:** `web/test/memba_web/inbound_email_headers_test.exs`, Postmark parser tests, Resend parser tests  
   **Smell:** Header parsing coverage appears good for common cases but necessarily limited for RFC/email-client edge cases.  
   **Why judgement may be needed:** Email parsing is irregular in practice. Folded headers, comments, unusual quoting, internationalized addresses, and provider-specific payload quirks should be expanded based on real inbound examples.

## Suggested fixes

No required fixes before merge.

Recommended future follow-ups, if product/engineering chooses:

1. Consider making outbound `Message-ID` values fully opaque if privacy/security review finds slug or delivery identifier exposure undesirable.
2. Monitor reply content quality and revisit quote stripping after real-world usage.
3. Add reply-by-email abuse controls if operational signals show autoresponder loops, compromised inboxes, or excessive posting.
4. Revisit inbound routing decomposition if later iterations add more responsibilities.
5. Expand parser/header tests using real provider payloads observed in production.

## Validation notes

- Full `dev ci` passed.
- ExUnit evidence: **891 tests, 0 failures**.
- Acceptance evidence: **82 scenarios passed**, **493 steps passed**.
- Acceptance feature files appear unchanged.
- Behavioural coverage evidence includes:
  - outbound persisted `Message-ID` generation;
  - reply email `Reply-To`, `In-Reply-To`, and `References` headers;
  - Postmark and Resend inbound header parsing;
  - same-club conversation matching;
  - cross-club reply prevention;
  - fallback to new club-wide inbound messages;
  - non-member, ambiguous sender, malformed payload, and unsupported inbound rejection paths;
  - reply attribution;
  - auto-follow on reply;
  - follower fan-out;
  - basic quoted-history stripping.
- The failed `verify_review_repair` stage was a workflow expectation mismatch: the repair agent made no diff because the requested bounded-safe fixes were already present. This does not change the implementation decision.