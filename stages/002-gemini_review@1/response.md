## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **An open business decision remains about unmatched inbound reply handling.**  
   The plan’s acceptance criteria say unmatched/garbled addresses reuse existing fallback and do not create stray replies, but `## Open Business Decisions` still asks whether to reject with feedback or silently drop and says to confirm copy during implementation. That is a product/workflow/copy decision and should be resolved before implementation.

2. **Core token strategy and persistence are unresolved.**  
   The iteration depends on a conversation-addressed reply token, but `## Open Technical Decisions` leaves token format/derivation and where the token↔conversation mapping lives undecided. That affects schema, migration shape, lookup semantics, security, and test design.

3. **Inbound sender authenticity / spoofing policy is still unresolved.**  
   The plan says to require current membership, but also leaves open how far to trust `From` under the existing inbound pipeline. Because this affects authorization and abuse handling for posting into conversations, the plan should explicitly state the trust model for this iteration and what hardening is deferred.

## Non-blocking improvements

1. **Name likely implementation modules/files.**  
   The implementation plan is understandable, but would be easier to execute if it named the existing inbound mail handler, reply notification mailer/template, conversation/reply context modules, and expected migration/test files.

2. **Clarify header behavior.**  
   The plan says email headers are secondary confirmation and also says `Message-ID`/`References` should be set, but it should clarify whether an address-token match succeeds when headers are absent or malformed.

3. **Define “basic quoted-history stripping” more concretely.**  
   The plan can keep this lightweight, but should define the minimum acceptable behavior, e.g. remove common quoted blocks while preserving the sender’s new text, and never reject solely because quote stripping fails.

4. **Clarify ambiguous-address handling.**  
   “Ambiguous addresses” are mentioned, but tokenized conversation routing should usually be unambiguous. The plan could define examples: multiple matching recipients, multiple club addresses, malformed typed segments, or token/club mismatch.

## Smallest viable iteration

The smallest useful slice is:

- Generate and persist an opaque conversation reply token.
- Set reply notification `Reply-To` to `<club-slug>+c.<token>@clubs.memba.io`.
- Parse inbound mail sent to that address.
- If the sender is a current club member, post the inbound body as a reply in the matched conversation, attribute it to the sender, auto-follow them, and fan out to followers.
- If the sender is not a member or the address/token cannot be resolved, create no reply and follow one explicitly defined fallback/rejection behavior.
- Preserve existing bare `<club-slug>@clubs.memba.io` behavior.

Defer advanced quote parsing, attachments, groups/channels, and deeper anti-spoofing hardening beyond the existing inbound trust model.

## Required plan edits

1. Resolve `## Open Business Decisions` by choosing the exact unmatched-reply behavior: reject with existing rejection email, silently drop, or another defined action. Include whether copy changes are in or out of scope.

2. Resolve token design: specify random opaque vs signed token, whether it is stored on conversations or in a separate mapping table, uniqueness constraints, when it is generated, and whether it rotates.

3. Resolve inbound authenticity policy for this iteration: explicitly state how the sender email is matched to a member, what existing Postmark/inbound trust assumptions are reused, and what spoofing protections are deferred.

4. Update acceptance criteria to reflect those decisions, especially unmatched-address behavior and sender-authentication behavior.

5. Optionally add likely implementation touchpoints: migration/schema, inbound parser/handler, reply mailer/template/header code, conversation reply context, and tests.

## Validation plan

To prove the iteration succeeded:

1. Add/update acceptance scenarios in `acceptance-tests/features/club_message_replies.feature` tagged `@iteration-041`.
2. Test that reply notification emails use `Reply-To: <club-slug>+c.<token>@clubs.memba.io`.
3. Test that the conversation token resolves only to the correct conversation and club.
4. Test that a current member’s inbound email reply creates a conversation reply, attributes it correctly, auto-follows the sender, and fans out to followers.
5. Test that a non-member inbound reply creates no reply and follows the decided rejection/drop behavior.
6. Test that unknown, malformed, token/club-mismatched, or otherwise unmatchable inbound addresses create no stray reply and follow the decided fallback behavior.
7. Test that bare `<club-slug>@clubs.memba.io` still follows the existing club-wide inbound message path.
8. Test the minimum quote-stripping behavior.
9. Run the `@iteration-041` acceptance scenarios with temporary todo tags removed or narrowed.
10. Run `dev check`.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Unmatched inbound reply fallback/copy decision remains open; Token format and persistence/mapping strategy are unresolved; Inbound sender authenticity/spoofing trust model is unresolved","gemini_review_required_edits":"Choose exact unmatched-reply fallback behavior and copy scope; Specify token design and storage/constraints/generation; State sender membership/authenticity trust model and deferred hardening; Update acceptance criteria to match those decisions"}}