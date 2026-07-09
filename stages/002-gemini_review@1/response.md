## Decision: READY

## Confidence: High

## Blocking gaps

1. None.

## Non-blocking improvements

1. The `## Open Technical Decisions` section contains a coordination note about iteration 051 rather than a true unresolved technical decision. Consider renaming it to “Coordination / Dependency Notes” or explicitly stating “No open technical decisions; implementation must coordinate with iteration 051 if still in flight.”
2. The plan could optionally name the likely Phoenix/LiveView template/component files once confirmed, but the current implementation steps are specific enough to proceed.
3. The visual acceptance criterion “visually match the desktop wireframe” is inherently somewhat subjective, but the detailed gallery-walk checklist makes it sufficiently reviewable for this presentation-only slice.

## Smallest viable iteration

The smallest useful slice is: align the desktop member message detail page to `design-system/wireframes/member-conversation.html`, including the compact footer policy for authenticated member app pages, while preserving existing reply/follow/delivery behaviours.

The current plan also includes removing the desktop club-home `Prefer email?` card. That is still small and coherent because it comes from the same desktop wireframe-alignment decision set, but it could be split out if implementation conflict with iteration 051 becomes significant.

## Required plan edits

None required before implementation.

## Validation plan

To prove the iteration succeeded:

1. Add/update the allowed `@iteration-052` scenarios in `acceptance-tests/features/club_message_replies.feature` for:
   - `All conversations` back-link copy.
   - Removed reply-helper sentence.
   - Inline `Replying as <name>` identity.
   - Quiet posted reply note: `Your reply is being sent.`
   - Conversation entries still showing sender, timestamp, and body.
   - Desktop club home no longer showing the `Prefer email?` card/copy.

2. Add/update Phoenix/LiveView/rendered tests for:
   - `.message*`, `.composer*`, and `.page-title` class usage.
   - Absence of the helper sentence.
   - Absence of prominent green success-alert styling.
   - Back link text.
   - Footer policy: member app pages omit the full public footer; public pages retain it.
   - Desktop club home omits the `Prefer email?` card.

3. Run the detailed gallery-walk validation:
   - `./bin/dev gallery-walk`
   - Compare the named desktop screenshots against the checked-in desktop wireframes.
   - Record a checklist covering message cards, composer, footer, spacing, title scale, back-link placement, and club-home card removal.

4. Smoke test as a seeded member on desktop:
   - Open club home Conversations and Members tabs.
   - Open a conversation.
   - Toggle follow/unfollow.
   - Open delivery details from the kebab menu.
   - Post a reply.
   - Confirm existing workflows still behave correctly.

5. Run `dev check` and require it to pass.

Stop condition: the automated tests and `dev check` pass, the desktop gallery-walk checklist confirms the intended visual alignment, and no out-of-scope mobile, routing, permission, notification, or data-model changes were introduced.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}