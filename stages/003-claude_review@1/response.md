Now I'll review the plan against all readiness criteria.

---

# Iteration 041 Plan Validation Report

## Decision: READY

## Confidence: High

## Blocking Gaps

None

## Non-Blocking Improvements

1. **Quote-stripping specificity**: "Basic quoted-history stripping" appears in scope and implementation but could be more concrete about what qualifies as "basic" (e.g., "strip lines starting with `>` and common email signatures") vs. deferred to follow-up. This is mild—acceptable to refine during implementation.

2. **Token generation timing**: Implementation step 1 says "generate a token per conversation" but doesn't clarify whether tokens are generated for all existing conversations on deploy or lazily on first email send. This is likely an implementation detail that can be decided during work, but clarifying "backfill on deploy" vs. "lazy generation on first email render" would tighten the plan.

3. **Header confirmation logic**: The plan states headers are "secondary" confirmation but doesn't specify what happens if the address matches but headers don't (e.g., forwarded email, different `Message-ID`). Likely acceptable to discover during implementation, but worth noting as an edge case to handle.

## Smallest Viable Iteration

The plan is already well-scoped and minimal. The smallest useful slice would be:

**"Reply by email lands in conversation for members"** — exactly what's in scope, minus the reserved `+g.` namespace documentation. However, the namespace reservation is a good design affordance with negligible cost, so keeping it is pragmatic.

No further reduction recommended; this iteration is already a coherent minimum.

## Required Plan Edits

None. The plan is ready for implementation as written.

## Validation Plan

The plan includes a clear validation section:

- **Unit/integration tests**: Token resolution, `Reply-To` header generation, membership authorization, quote stripping, rejection handling, backward compatibility (bare club address).
- **Acceptance scenarios**: `@iteration-041` scenarios in `club_message_replies.feature` covering happy path (member reply lands and fans out), rejection (non-member), unmatchable/garbled addresses, and backward compatibility.
- **`dev check` passes**: Full test suite, static analysis, and acceptance tests green.

### How to prove success after implementation:

1. Send a reply notification email for a conversation; verify `Reply-To` is `<club-slug>+c.<token>@clubs.memba.io` and `Message-ID`/`References` are set.
2. Simulate an inbound email to that address from the conversation's club member via Postmark; verify the reply posts to the conversation, auto-follows the replier, and fans out to followers.
3. Simulate an inbound email from a non-member; verify rejection email sent.
4. Simulate inbound to an unknown token or garbled address; verify safe handling (no crash, no stray post).
5. Simulate inbound to `<club-slug>@clubs.memba.io` with no `+c.` suffix; verify it still creates a club-wide message (backward compatibility).
6. All `@iteration-041` scenarios pass; all existing scenarios stay green.
7. `dev check` passes on committed code.

---

## Detailed Review Against Readiness Questions

### 1. Goal Clarity ✅

- **Clearly articulated**: Yes. "Let members reply to a club conversation straight from their email client and have that reply land in the right Memba conversation."
- **User/business outcome**: Yes. The goal states the member capability (reply from inbox → lands in conversation) and the business outcome (completes the reply loop from 039/040).
- **Beneficiary clear**: Yes. Members of a club who receive reply notification emails and want to respond from their inbox.

### 2. Scope Focus ✅

- **One coherent outcome**: Yes. Enable email replies to conversations, routed by conversation-addressed reply address.
- **Could it be smaller**: The iteration is already minimal. It could theoretically be split into "address schema only" and "inbound routing," but that would leave the schema unused and untested—not useful on its own.
- **Non-goals clear**: Yes. Groups/channels, perfect quote parsing, attachments, in-app reply changes, and new provider integrations are all explicitly out of scope.

### 3. Acceptance Criteria, BDD, and Business Decisions ✅

- **Criteria concrete and testable**: Yes. Each criterion has a clear pass/fail condition: `Reply-To` set to conversation address; member reply posts and fans out; non-member rejected; unmatchable handled safely; bare club address backward-compatible; scenarios pass; `dev check` passes.
- **Coverage complete**: Yes. Happy path (member reply), error states (non-member, unmatchable, garbled), permissions (membership check), state changes (auto-follow, fan-out), and backward compatibility (bare club address) are all covered.
- **Iteration type classified**: Yes. "Behaviour-facing."
- **Acceptance scenarios section present**: Yes. Section "Acceptance Scenarios / Feature Files" is explicit. It names `club_message_replies.feature`, lists required scenarios (member reply lands and reaches followers; non-member rejected; unmatchable safely handled), and tags them `@iteration-041`.
- **Business decisions resolved**: One open decision noted (reject vs. silent drop for unmatchable inbound), with a clear recommendation (reuse rejection email, confirm copy during implementation). All other decisions confirmed (membership required, auto-follow, follower delivery, address schema).

### 4. Implementation Plan and Technical Decisions ✅

- **Steps clear and ordered**: Yes. Six numbered steps: (1) token mapping, (2) set `Reply-To`/headers, (3) extend inbound pipeline, (4) apply authorization/rejection, (5) make scenarios runnable, (6) `dev check`.
- **Files/modules/interfaces named**: Yes. `emails/reply-notification.html`, `club_message_replies.feature`, inbound pipeline (iterations 019/020), 039 reply path, 040 follower fan-out, and Postmark MX (`clubs.memba.io`).
- **Data model clear**: Yes. Conversation routing token ↔ conversation mapping (implementation detail: random vs. signed, where it lives—noted as open technical decision).
- **Integration points clear**: Yes. Postmark inbound webhook, existing inbound pipeline, 039 reply creation, 040 follower delivery.
- **Technical decisions**: Three open technical decisions listed (token format/storage, quote-stripping library vs. heuristic, spoofing trust model). All are appropriately scoped as implementation details that don't require product decisions.

### 5. Expected Capability and Validation ✅

- **What we can do after**: Clearly stated. Members can reply from their inbox and it lands in the Memba conversation, routed by conversation-addressed reply address, with same rules as in-app replies (membership, auto-follow, fan-out).
- **How to prove success**: Validation plan lists unit/integration tests, acceptance scenarios (`@iteration-041`), and `dev check`.
- **Clear stop condition**: Yes. `@iteration-041` scenarios pass, existing scenarios green, `dev check` passes.

---

## Summary

This plan is **well-structured, complete, and ready for implementation**. It demonstrates strong continuity with prior iterations (039/040), clear scope boundaries, explicit acceptance scenarios, and thoughtful forward-compatibility (reserved `+g.` namespace). The open business decision (rejection email vs. silent drop) has a clear recommendation and can be confirmed during implementation. The open technical decisions are appropriately scoped as implementation details.

The plan meets all readiness criteria with high confidence.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}