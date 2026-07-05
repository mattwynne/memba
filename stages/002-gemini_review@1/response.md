## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Add the no-receipts/empty-state behavior to acceptance criteria and tests. The risk section mentions it, but the acceptance criteria do not explicitly require it.
2. Name the likely test file(s) or test module(s) for the new LiveView/route coverage to make implementation handoff slightly clearer.
3. Specify expected unauthorized behavior for the delivery route, e.g. redirect, 404, or existing conversation auth failure behavior, while still saying it must match the conversation route.

## Smallest viable iteration

The current slice is already appropriately small: add the member-facing per-message Delivery details page, link to it from each conversation message, and remove the duplicated inline delivery UI from the conversation. Splitting the new page from the removal would leave duplicate/conflicting UX, so the planned scope is the smallest useful coherent outcome.

## Required plan edits

None required before implementation.

## Validation plan

Success can be proven by:

1. Automated LiveView/route tests showing:
   - A conversation message and each reply expose a Delivery details menu item/link.
   - `/messages/:message_id/delivery` renders the expected header, summary, legend, grouped recipients, bounce reasons, and Back to conversation link.
   - The route enforces the same authorization as the existing conversation view.
   - The conversation page no longer renders the inline delivery summary, grouped member delivery breakdown, or “sent to N members” meta line.
   - Delivery status/data computation remains unchanged.
2. Visual validation with `./bin/dev gallery-walk`, comparing:
   - Delivery page against `design-system/wireframes/delivery-details.html`.
   - Conversation page against `design-system/wireframes/member-conversation.html`.
3. Full project validation with `dev check`.
4. Manual smoke test:
   - Open a member conversation.
   - Use a message’s ⋮ menu to navigate to Delivery details.
   - Confirm delivery details are visible.
   - Return via Back to conversation.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}