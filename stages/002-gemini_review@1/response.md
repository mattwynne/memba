## Decision: NOT READY

## Confidence: High

I read `docs/iterations/044-shared-app-shell/plan.md` completely, lines 1–176, and confirmed the file length is 176 lines.

## Blocking gaps

1. **Technical decisions are explicitly unresolved.**  
   The plan includes `[Open technical decision]` in the implementation plan and an `## Open Technical Decisions` section covering CSS source and identity name/initials plumbing. A ready-for-implementation plan should not leave these undecided.

2. **Identity display behaviour is not fully decided or testable.**  
   Acceptance criteria say signed-in club pages show “avatar initials + member name,” but the implementation plan says to “fall back gracefully” to `current_identity.email` where member display name is unavailable. The exact display rules, initials derivation, and fallback behaviour need to be decided before implementation.

3. **The “six `club_site` surfaces” are not enumerated clearly.**  
   The plan repeatedly says “all six” surfaces, but the acceptance criterion lists: club home, conversation/message detail, compose, member invitation, and public club page. That reads as five unless “conversation/message detail” is meant to represent two distinct surfaces. The exact pages/routes to update and test should be listed.

## Non-blocking improvements

1. Add likely test file names or existing test modules to make implementation handoff easier.
2. Include the exact design CSS source file/selector range if known, since the plan depends on porting design-system classes 1:1.
3. Clarify whether “public club page” is intentionally included in “member-facing club surfaces,” since it is signed-out/public but uses `club_site`.

## Smallest viable iteration

Build only the shared `Layouts.club_site` shell change:

- Replace the existing club-site header with the simplified app-bar.
- Wrap existing page content in the app-card/app-frame.
- Preserve existing sign-out and footer behaviour.
- Use the existing identity email initially, unless member-name plumbing is already straightforward and fully specified.

This is still a useful slice because it establishes the shared app-like frame for later tab/content iterations without changing domain behaviour.

## Required plan edits

1. Resolve `## Open Technical Decisions`; remove the open-decision section or replace it with final decisions.
2. State the final CSS approach, likely: port design-system app-shell classes into `web/assets/css/app.css` using the same class names.
3. Define final identity display rules:
   - Which assign supplies the display name.
   - How initials are derived.
   - What exact fallback appears when member name is unavailable.
   - Whether fallback is email, blank, or another value.
4. Update acceptance criteria to include the decided identity fallback behaviour.
5. Enumerate the exact six `club_site` surfaces/routes/pages that must still render and be tested.
6. Update implementation steps and validation plan to match the resolved decisions.

## Validation plan

To prove the iteration succeeded after implementation:

1. Automated layout/LiveView tests verify:
   - App-bar renders on each listed `club_site` surface.
   - Club name appears on the left.
   - Signed-in identity dropdown appears only when `@current_identity` is present.
   - Identity label and initials follow the decided display/fallback rules.
   - Sign out still submits to `DELETE /auth`.
   - Page content is wrapped in the app-card frame.
   - “Powered by Memba” footer link is preserved.
   - No club switcher, club dropdown, or Memba mark appears in the app-bar.

2. Visual validation:
   - Run `./bin/dev gallery-walk`.
   - Compare club home and member conversation screenshots against the refreshed design-system wireframes for app-bar, app-card, and footer structure.

3. Final project validation:
   - Run `dev check` and require it to pass.

{"context_updates":{"gemini_review_decision":"NOT READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":3,"gemini_review_blocking_gaps":"Open technical decisions remain for CSS source and identity name/initials plumbing; Identity display and fallback behaviour conflicts between acceptance criteria and implementation plan; Exact six club_site surfaces are not clearly enumerated","gemini_review_required_edits":"Resolve open technical decisions; Define identity display/initials/fallback rules and update acceptance criteria; Enumerate exact six club_site surfaces/routes to update and test"}}