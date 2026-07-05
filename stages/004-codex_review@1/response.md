## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Specify the exact test file(s) likely to be updated, e.g. the current controller/LiveView test covering `MemberDashboardLive` / club home rendering.
2. Clarify the accessibility implementation details for the tabs: `aria-controls`, `role="tabpanel"`, `aria-labelledby`, `hidden`/visibility state, and whether arrow-key tab navigation is required or whether native button keyboard behavior is sufficient.
3. Consider explicitly saying that the Members panel’s existing invite affordance should not be duplicated if the new per-tab action owns the invite action.
4. Clarify whether the tab action slot itself is hidden/swapped along with panels via `Phoenix.LiveView.JS`, so the active tab has only its own primary action visible.

## Smallest viable iteration

Implement the two-tab club-home information architecture only:

- Conversations tab selected by default.
- Members tab hidden by default.
- Existing conversations content and inbound-email affordance moved into Conversations.
- Existing members content moved into Members.
- One primary action per active tab: New message for Conversations, Invite member for Members when permitted.
- No About tab, no member-row redesign, no permissions or data changes.

This is already the smallest useful slice because the outcome depends on establishing the section-tab IA with both sections represented.

## Required plan edits

None required before implementation.

## Validation plan

Success can be proven by:

1. Automated tests confirming:
   - Conversations and Members tabs render.
   - Conversations is selected/default-visible.
   - Selecting Members hides Conversations and reveals Members without navigation/server state change where testable.
   - New message action links to the existing compose path.
   - Invite member action appears only when `@current_member_can_manage_members?` permits it.
   - Existing conversation rows/empty state, inbound-email affordance, and members content still render.

2. Accessibility checks confirming:
   - Tab controls expose appropriate roles and `aria-selected`.
   - Active/inactive state changes are reflected for assistive tech.
   - Tabs are keyboard-operable.

3. Visual/manual validation:
   - Run `./bin/dev gallery-walk`.
   - Compare `member-club-home` against `design-system/wireframes/club-home.html` for the tab spine, per-tab action slot, and panels.
   - Manually toggle tabs in the 044 shell and verify preserved actions/content.

4. Final stop condition:
   - `dev check` passes.
   - No feature-file changes are required.
   - The club home now presents Conversations/Members as the app-like tabbed interface described by the plan.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}