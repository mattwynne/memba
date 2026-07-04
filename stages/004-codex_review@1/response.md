## Decision: NOT READY

## Confidence: High

I read `docs/iterations/046-club-home-section-tabs/plan.md` directly and completely. The plan is close, but it is not ready for implementation because it explicitly contains unresolved business and technical decisions.

## Blocking gaps

1. **Compose CTA + inbound-email placement is unresolved.**  
   The plan says it is “draft pending Matt’s confirmation” and lists alternatives for the compose CTA / inbound-email note. Acceptance criteria and implementation steps assume the recommended default, but the business/product decision is not confirmed.

2. **Hero greeting decision is unresolved.**  
   The plan says to keep or drop the “Hello, {first name}.” greeting, with “keep” as the default. Because this affects visible UI and layout, the plan should settle it before implementation.

3. **Tab switching mechanism is still open.**  
   The implementation plan recommends `Phoenix.LiveView.JS`, but `## Open Technical Decisions` still says to confirm JS vs server-side active-tab state. The plan should make this decision final or define the exact fallback condition.

## Non-blocking improvements

1. Clarify what “keyboard-operable” means for the tabs: e.g. whether Tab + Enter/Space is sufficient, or whether arrow-key tab navigation is expected.
2. Specify expected hidden-panel semantics more concretely, such as `hidden`, `aria-controls`, and panel IDs, if the project has an accessibility convention for tabs.
3. Name the likely existing test file(s) to update, if known, rather than saying only “LiveView/controller test.”
4. Update the `Status: draft` line once the open decisions are resolved.

## Smallest viable iteration

The smallest useful slice is the plan’s current intended slice: add the Conversations / Members tab spine to the member club home, keep existing content and permissions unchanged, and provide one primary action per tab. Do not include app-bar / club switcher, named member rows, role badges, Events, or mobile redesign.

However, that slice should only proceed after the CTA/email-note, hero greeting, and tab-switching decisions are made explicit.

## Required plan edits

1. Resolve the compose CTA decision: state definitively whether to replace the large CTA with compact **New message**, preserve the inbound-email note, drop the note, or keep the full CTA card.
2. Resolve the hero greeting decision: state definitively whether “Hello, {first name}.” remains above the tabs in this slice.
3. Resolve the technical tab-switching decision: choose `Phoenix.LiveView.JS` or server-side state, and remove the “Open Technical Decisions” uncertainty or define a concrete fallback.
4. Change the plan status from draft/pending once the above decisions are resolved.
5. Optionally tighten accessibility acceptance criteria around keyboard behavior and tab/panel ARIA relationships.

## Validation plan

To prove the iteration succeeded after implementation:

1. Automated test coverage verifies:
   - Conversations and Members tab controls render.
   - Conversations is selected by default.
   - Switching tabs shows the selected panel and hides the other without full navigation.
   - Active styling and `aria-selected` update correctly.
   - Conversations contains the existing conversation rows or empty state.
   - The inbound-email affordance appears if that decision is retained.
   - New message opens the existing compose flow.
   - Invite member appears only for members who can manage members.
   - Existing member content remains present in the Members panel.

2. Run `dev check` and confirm it passes.

3. Visual/manual validation:
   - Load member club home.
   - Compare against `design-system/wireframes/club-home.html` for the tab spine/action-slot subset.
   - Toggle tabs.
   - Confirm no permissions, recipients, member visibility, or compose/invite behavior changed.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":3,"codex_review_blocking_gaps":"Compose CTA and inbound-email placement not confirmed; Hero greeting decision not confirmed; Tab switching mechanism still open","codex_review_required_edits":"Resolve compose CTA and inbound-email placement; Resolve hero greeting; Choose tab switching mechanism and remove open technical decision; Update draft status once resolved"}}