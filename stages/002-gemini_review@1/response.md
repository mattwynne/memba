## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/046-club-home-section-tabs/plan.md`. I did not edit files.

## Blocking gaps

1. **Open business/product/copy decisions remain unresolved.**  
   The plan explicitly says it is “draft pending Matt’s confirmation” and includes unresolved decisions for:
   - replacing the large compose CTA with compact **New message** action while preserving the inbound-email note;
   - whether to keep or drop the hero greeting.

2. **Open technical decision remains unresolved.**  
   The plan names the tab-switching mechanism as an open technical decision: `Phoenix.LiveView.JS` client commands vs server-side active-tab assign. The recommended path is clear, but the plan still asks implementers to confirm or fall back during implementation.

## Non-blocking improvements

1. Name the likely test file(s) to update, not just “LiveView/controller test.”
2. Clarify the expected hidden-panel mechanism for accessibility, e.g. whether inactive panels use `hidden`, `aria-hidden`, CSS-only hiding, or LiveView JS display toggling.
3. Specify whether keyboard support means standard tab-button focus/click behavior only, or arrow-key tablist navigation as well.
4. Add stable DOM IDs/selectors for the tabs, panels, and action slot to make tests and JS commands less fragile.

## Smallest viable iteration

The smallest useful slice is:

> Convert the existing member club home into two client-side tabs — **Conversations** as default and **Members** as secondary — preserving the current conversation list, member card, permissions, compose flow, invite flow, and inbound-email affordance, with no app-bar, club switcher, named member rows, role badges, schema changes, or new business rules.

That slice is coherent and appropriately small, but it is not ready until the open decisions are closed.

## Required plan edits

1. Resolve the **Compose CTA + inbound-email note** decision:
   - state the final chosen behavior;
   - update Acceptance Criteria and Implementation Plan accordingly;
   - remove the “pending Matt” status note.

2. Resolve the **Hero greeting** decision:
   - state whether it stays or is removed;
   - reflect that in scope/acceptance criteria if user-visible.

3. Resolve the **tab-switching mechanism**:
   - choose `Phoenix.LiveView.JS` or server-side assign;
   - remove or replace the Open Technical Decisions section;
   - update implementation/test guidance to match.

4. Change the plan status from draft only after the above decisions are finalized.

## Validation plan

Success should be proven by:

1. Automated tests confirming:
   - Conversations and Members tab controls render;
   - Conversations is selected by default;
   - switching tabs updates visible panel and active/ARIA state;
   - Conversations has the **New message** action wired to existing compose path;
   - Members has the **Invite member** action only for members with manage-member permission;
   - existing conversation rows/empty state, members content, and inbound-email affordance are preserved.

2. `dev check` passes after implementation.

3. Visual/manual validation:
   - load member club home;
   - compare tab spine/action-slot/panel layout against `design-system/wireframes/club-home.html` for this slice only;
   - verify no full-page navigation during tab switching;
   - verify keyboard and screen-reader-relevant tab attributes.

Stop condition: the club home exposes the two-section tab structure with preserved existing behavior and no unresolved scope or decision questions.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":2,"gemini_review_blocking_gaps":"Open business/product/copy decisions remain unresolved for compose CTA/inbound-email note and hero greeting; Open technical decision remains unresolved for tab switching mechanism","gemini_review_required_edits":"Resolve compose CTA/inbound-email note decision and update criteria/implementation; Resolve hero greeting decision; Choose tab switching mechanism and remove open technical decision; Remove draft pending note/status only after decisions are finalized"}}