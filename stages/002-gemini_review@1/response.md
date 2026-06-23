## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Delivery disclosure implementation is still unresolved.** The plan explicitly lists an open technical decision: whether the delivery disclosure is server-driven or client-only. It states a preference for server-driven, but does not make the decision final. For implementation readiness, this should be decided before work starts.

2. **Zero-reply presentation is ambiguous.** The acceptance criterion says the “Replies · N” header is “hidden or ‘no replies yet’ treatment when there are none.” Those are different UI outcomes, so this is not objectively testable as written.

## Non-blocking improvements

1. The plan is otherwise well-scoped around one coherent outcome: aligning the member conversation page to the wireframe while preserving richer app treatments.
2. Goal, beneficiary, and outcome are clear: members viewing a message-detail/conversation page get a more conversation-first layout.
3. The BDD decision is acceptable: this is behaviour-facing but presentational, and the plan explains why existing Cucumber coverage is sufficient.
4. The acceptance criteria cover the main presentation changes and preserve existing behavioural boundaries.
5. The validation plan is strong, with LiveView/component assertions, existing acceptance tests, and gallery-walk visual confirmation.

## Smallest viable iteration

The smallest useful slice is the current member conversation page alignment, but with two decisions finalized before implementation:

- Use a server-driven delivery disclosure, consistent with the existing receipt-group expansion pattern.
- Choose one zero-reply treatment, preferably always showing the header as `Replies · 0` with an empty-state/no-replies message if that matches the design intent.

## Required plan edits

1. Replace the open technical decision with a finalized implementation choice, e.g. “Delivery disclosure will be server-driven using a LiveView assign and toggle event, consistent with `toggle_receipt_group`.”
2. Make the zero-reply acceptance criterion objective, e.g. “When there are no replies, show `Replies · 0` above an empty-state message” or “When there are no replies, omit the replies header and list.”

## Validation plan

To prove the iteration succeeded:

1. Add/update LiveView/component tests for `MemberMessageLive.Show` covering:
   - Follow toggle presence, initial state, and follow/unfollow event behaviour.
   - Delivery detail collapsed by default.
   - Delivery detail expands via the finalized disclosure mechanism.
   - Reply composer renders after the reply list.
   - Composer keeps “Replying as <name>” and removes the verbose helper sentence.
   - Replies header displays the correct count, including the chosen zero-reply behaviour.
   - Each reply renders a timestamp.
   - Original-message meta renders the sent date.
   - Original message and replies remain boxed cards.
2. Confirm existing `club_message_replies.feature` scenarios remain green.
3. Capture/verify a `bin/dev gallery-walk` screenshot of the member message-detail page against the updated wireframe.
4. Stop when all targeted tests pass, existing behaviour-facing acceptance coverage remains green, and the visual layout matches the intended design.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":2,"gemini_review_blocking_gaps":"Delivery disclosure implementation decision remains open; Zero-reply presentation is ambiguous and not objectively testable","gemini_review_required_edits":"Finalize delivery disclosure as server-driven or client-only; Specify exact zero-reply header/empty-state treatment"}}