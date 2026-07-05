## Decision: READY

## Confidence: High

I read `docs/iterations/048-named-member-rows/plan.md` completely, lines 1–120.

## Blocking gaps

None.

## Non-blocking improvements

1. Rename or reframe `## Open Technical Decisions` because the “member since” item is effectively decided: include it only if already available; otherwise omit it. Calling it “open” could confuse implementers.
2. Add an explicit note that member ordering should remain whatever `@members` / `MemberDashboardPresentation` already provides, unless the design requires a different order.
3. Name the likely existing test file(s) to update, if known, to make implementation slightly faster.
4. Clarify the fallback meta text for non-current members if no “member since” value exists. For example: current member meta is “You”; other rows may have no meta or an empty/omitted meta line.

## Smallest viable iteration

Replace the existing Members tab avatar-stack card with a named member-row list using existing `@members` data, mark the current member as “You,” and preserve invite gating and empty-state behavior. Defer role badges, membership-since data sourcing, pagination/virtualization, and any permission/data changes.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. Automated tests confirming:
   - Members render as named rows with avatar initials and names.
   - The current member row is marked “You.”
   - Invite member action remains gated as before.
   - Empty state still renders correctly.
   - No change to who appears in the member list or who can invite.
2. Visual validation with `./bin/dev gallery-walk`, comparing the Members tab against `design-system/wireframes/club-home.html`.
3. Manual check of the club home Members tab showing named rows and the current member marker.
4. Full `dev check` green before the implementation is considered complete.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}