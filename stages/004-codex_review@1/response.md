## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/041-reply-by-email-threading/plan.md`.

## Blocking gaps

1. **An open business decision remains unresolved.**  
   The plan explicitly lists “Fallback when an inbound reply can't be matched” as an open business decision, with “reject with a conversation-aware rejection email, or silently drop” still to confirm. The acceptance criteria also use the ambiguous phrase “rejected/ignored safely,” which is not objectively testable.

2. **Core token/mapping design is still unresolved.**  
   The plan depends on a conversation routing token but leaves open whether it is random opaque vs. signed, where the token-to-conversation mapping lives, and by implication how it is generated, persisted, migrated/backfilled, and constrained for uniqueness. This is central to the data model and implementation.

3. **Inbound authenticity / sender trust policy is unresolved.**  
   The plan says to reuse the existing inbound path’s assumptions but still lists spoofing/authenticity as an open technical decision. Since this feature creates replies attributed to members from inbound email, the plan needs a clear implementation rule for how `From` is matched and trusted, and what happens on ambiguous/multiple/no member matches.

4. **Header confirmation behavior is underspecified.**  
   The plan says `In-Reply-To` / `References` are a secondary confirmation, but does not define what happens when headers are missing, mismatched, or point elsewhere while the address token resolves. That affects safety and edge-case behavior.

## Non-blocking improvements

1. Name likely implementation files/modules/migrations/tests once the token strategy is chosen, especially for inbound parsing, reply email generation, and conversation persistence.
2. Define “basic quoted-history stripping” with a minimal objective stop condition, for example “store the visible new reply body and remove common quoted sections when detectable; never reject solely because stripping fails.”
3. Clarify whether rejection emails should include conversation context, and if so what minimal copy is acceptable.
4. Separate “email client threading headers” from “server-side routing safety” so implementers know which parts are required for correctness versus UX polish.

## Smallest viable iteration

The smallest useful slice is:

- Generate and persist a stable, unguessable conversation reply token.
- Set reply notification `Reply-To` to `<club-slug>+c.<token>@clubs.memba.io`.
- Accept inbound email sent to that address from a current club member.
- Create a reply in the matched conversation, attribute it to the member, auto-follow the replier, and fan out to followers.
- Safely handle non-members, unknown tokens, garbled addresses, and bare club addresses with explicitly defined behavior.
- Add acceptance coverage for the member happy path and the key rejection/fallback paths.

Defer groups/channels, attachments, sophisticated quote parsing, and deeper anti-spoofing hardening beyond the existing inbound trust model.

## Required plan edits

1. Resolve the unmatched inbound behavior: choose reject-with-feedback or silent drop, and make each relevant acceptance criterion objectively testable.
2. Specify the routing token design: random opaque or signed, storage location, uniqueness constraints, generation timing, and migration/backfill approach for existing conversations.
3. Define the inbound sender-authentication policy: how `From` maps to a member, what existing inbound assumptions are reused, and what happens for ambiguous, absent, or spoof-suspect senders.
4. Define header-confirmation semantics: whether missing/mismatched `In-Reply-To` / `References` are ignored, logged, rejected, or used only for diagnostics/threading.
5. Update acceptance criteria and scenarios to reflect those decisions precisely.

## Validation plan

Success should be proven by:

1. Unit/integration tests for conversation reply address generation and token resolution.
2. Email-generation tests proving reply notifications use the conversation `Reply-To` and expected threading headers.
3. Inbound tests for:
   - current member reply posts into the correct conversation;
   - reply is attributed to the sender;
   - replier auto-follows;
   - followers receive fan-out;
   - non-member inbound creates no reply and follows the chosen rejection/drop behavior;
   - unknown/garbled token creates no stray reply;
   - bare `<club-slug>@clubs.memba.io` still follows the existing club-wide message path;
   - missing/mismatched headers follow the newly specified rule.
4. `@iteration-041` acceptance scenarios passing with temporary todo tags removed or narrowed.
5. Existing 039/040 reply/follower scenarios remaining green.
6. Full `dev check` passing.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":4,"codex_review_blocking_gaps":"Unmatched inbound fallback/rejection behavior remains an open business decision; Conversation token format/storage/lifecycle is unresolved; Inbound sender authenticity/member matching policy is unresolved; Secondary header confirmation behavior is underspecified","codex_review_required_edits":"Choose and specify unmatched inbound behavior; Define token generation/storage/constraints/migration; Define From-to-member trust and ambiguity policy; Define missing/mismatched header semantics; Update acceptance criteria and scenarios accordingly"}}