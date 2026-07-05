## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the “all six `club_site` surfaces” wording: the acceptance criteria list appears to name five items unless “conversation/message detail” represents two distinct surfaces.
2. Optionally name likely test files/modules to update, but the current validation guidance is specific enough for implementation.

## Smallest viable iteration

The smallest useful slice is the plan as written: update the shared `Layouts.club_site` shell once so all member-facing club pages inherit the app-bar, app-card frame, preserved footer, preserved sign-out behavior, and signed-in identity dropdown gating. Splitting CSS from markup would not deliver a useful user-visible outcome by itself.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. Automated LiveView/layout coverage showing:
   - app-bar renders the club name,
   - identity dropdown appears only when `current_identity` is present,
   - sign-out still posts to `DELETE /auth`,
   - content is wrapped in the app-card frame,
   - each `club_site` surface still renders.
2. `dev check` passes.
3. Visual comparison through `./bin/dev gallery-walk` against the refreshed `club-home.html` and `member-conversation.html` design-system wireframes.
4. Manual smoke test:
   - signed-in club home and conversation show the app-bar,
   - identity dropdown opens,
   - Sign out works,
   - public club page shows the app-bar without identity dropdown.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}