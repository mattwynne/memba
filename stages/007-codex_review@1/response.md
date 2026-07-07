# Iteration 047 Review: Conversation Delivery Details

## Decision: ACCEPT

## Confidence: Medium

The implementation has green automated feedback and appears consistent with the plan. Confidence is medium because the supplied transcript includes only excerpts of the implementation evidence and does not show the full ADR set or full touched-file diff inline.

## ADR conformance: PASS

The plan does not cite a specific ADR, and this iteration appears limited to member-scoped read-side Phoenix/LiveView UI, routing, presentation, CSS, and tests. The implementation appears to preserve the project’s CQRS/event-sourcing boundaries by:

- Reading delivery details through existing context/read-model APIs rather than introducing local query shortcuts.
- Reusing the existing member message authorization/loading pattern scoped to the member’s active clubs.
- Keeping delivery display shaping in the web/presentation layer.
- Avoiding changes to aggregates, commands, events, projections, or event streams.

## ADR violations

None detected.

## Blocking issues

None.

## Bounded-safe fixes

1. **Avoid continuing the LiveView assign pipeline after redirect**
   - File: `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - The mount pipeline appears to assign the message, then receipts, then counts, with downstream guards for the redirect/not-found case.
   - This is functionally safe, but a clearer `with`/case-style mount would avoid doing follow-on work after an authz/not-found redirect and would make the control flow easier to audit.

2. **Move delivery count derivation closer to the receipt presentation model**
   - Files:
     - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
     - `web/lib/memba_web/member_email_delivery_presentation.ex`
   - If `MemberEmailDeliveryPresentation.present_receipts/1` already owns grouping into delivered/failed/pending buckets, it should likely also expose the corresponding counts.
   - This would keep the LiveView from re-deriving presentation state from the presentation model and reduce coupling between the template and grouped-list internals.

3. **Make the zero-recipient state explicit if it is currently only implicit**
   - File: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`
   - The plan notes the page should have an empty/none state when a message has no receipts.
   - If the current behavior is only a 0-width delivery bar plus empty groups, consider adding a small explicit message such as “No delivery receipts yet” / “This message has not been sent to any recipients yet.”
   - Add or keep a LiveView test for this edge case if not already present.

4. **Keep percentage/bar-width helpers covered by tests**
   - Files:
     - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
     - relevant LiveView test file
   - The delivery bar depends on percentage calculation for visual correctness and zero-total safety.
   - If the helper is private, coverage through rendered HTML is enough; ensure there is a test proving zero receipts do not produce bad widths, division errors, or malformed style attributes.

## Judgement-worthy non-blocking code-health findings

1. **Presentation responsibilities are split between presentation module and LiveView**
   - Files:
     - `web/lib/memba_web/member_email_delivery_presentation.ex`
     - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - Smell: the presentation layer groups receipts, while the LiveView derives counts from those groups.
   - Why it may need judgement: this is small and harmless now, but it can become drift if more summary metadata is added later. A richer receipt presentation struct/map would better centralize delivery-summary semantics.

2. **Authorization/loading parity may rely on copied conversation-loader logic**
   - Files:
     - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
     - existing conversation/message detail loader code
   - Smell: the delivery page must enforce exactly the same member/club authorization as the conversation page.
   - Why it may need judgement: the plan explicitly asked to reuse the existing pattern, and the implementation appears to do so. If this was implemented by duplicating the load/authz steps instead of sharing a helper/context function, future authz changes may need to be updated in multiple places.

3. **Dynamic inline width styles in HEEx**
   - File: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`
   - Smell: delivery-bar segment widths are likely rendered with dynamic inline `style` attributes.
   - Why it may need judgement: dynamic widths are reasonable here and often unavoidable, but if the design system grows more delivery visualizations, a CSS-custom-property convention could make the markup/CSS split cleaner.

4. **Global CSS class port is intentionally broad**
   - File: `web/assets/css/app.css`
   - Smell: the iteration ports design-system classes such as `delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, and `deliv-*` into the global app stylesheet.
   - Why it may need judgement: this follows the plan, but these generic class names could collide with future delivery/status UI. Not a blocker; just worth watching as the design system expands.

## Suggested fixes

If doing a small polish pass, I would prioritize:

1. Refactor `mount/3` in `MemberMessageDeliveryLive.Show` so the unauthorized/not-found branch redirects and does not flow through receipt/count assignment.
2. Extend `MemberEmailDeliveryPresentation.present_receipts/1` to return counts alongside grouped recipients, then remove count derivation from the LiveView.
3. Add an explicit empty state for `total_count == 0` if the current UI lacks one, with a LiveView test covering the rendered state.
4. Ensure the delivery-bar percentage calculation is exercised through tests for both normal and zero-total cases.

## Validation notes

- `dev ci` / dev check completed successfully before review.
- Acceptance suite excerpt shows **85 scenarios / 523 steps passed**.
- Sandbox/runtime preflight passed on a clean working tree.
- The implementation appears to satisfy the plan-level capability:
  - member-scoped `/messages/:message_id/delivery` route;
  - delivery details LiveView;
  - conversation kebab link;
  - inline delivery sections removed from conversation;
  - delivery CSS ported;
  - tests added/updated.
- No blocking ADR, behavioural, or coverage issue is evident from the supplied review context.