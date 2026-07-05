## Decision: READY

## Confidence: High

## Blocking gaps

1. None.

## Non-blocking improvements

1. The plan could make the intended DOM targets for tab switching explicit, such as panel IDs and action-slot IDs/classes, to reduce implementation ambiguity.
2. The test plan could explicitly mention asserting that hidden inactive panels/actions are not exposed to users or assistive tech, not only visually hidden.
3. The plan status is still `draft`; if the workflow requires a document-state transition, it can be marked validated by the orchestration step. This is not a readiness blocker.

## Smallest viable iteration

The current slice is already the smallest useful iteration: add the two-tab club-home information architecture with Conversations as the default tab, Members as the second tab, and one primary action per tab, while preserving existing message, invite, permission, and member-list behaviour.

Further reducing it — for example adding tabs without per-tab actions, or moving only conversations but not members — would not deliver the intended app-like section-tab spine.

## Required plan edits

None.

## Validation plan

Success can be proven by:

1. Automated tests confirming:
   - Conversations and Members tabs render.
   - Conversations is selected by default.
   - Tab controls have appropriate accessible roles/state.
   - New message appears for Conversations.
   - Invite member appears for Members only when the viewer can manage members.
   - Existing conversation rows or empty state still render.
   - Existing members content still renders.
   - Existing permissions and routing are unchanged.

2. Visual validation:
   - Run `./bin/dev gallery-walk`.
   - Compare `member-club-home` against `design-system/wireframes/club-home.html` for the tab spine, per-tab action slot, and panel layout.

3. Manual validation:
   - Load the club home inside the 044 app shell.
   - Toggle between Conversations and Members without full-page navigation.
   - Confirm active styling and `aria-selected` update.
   - Confirm the email affordance remains available in Conversations.
   - Confirm keyboard and screen-reader operability.

4. Stop condition:
   - The club home presents the Conversations / Members section tabs with correct default state, actions, permissions, preserved content, accessible tab behaviour, visual alignment with the design subset, and `dev check` passes.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}