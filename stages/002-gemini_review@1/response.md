## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/044-shared-app-shell/plan.md` lines 1–183.

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the “all six `club_site` surfaces” wording. The plan repeatedly says six surfaces but the listed examples read like five unless “conversation/message detail” represents two separate surfaces. Name all six explicitly to avoid test/implementation ambiguity.
2. Consider adding a small accessibility validation note for the identity dropdown, e.g. keyboard/focus behavior and accessible label/trigger text, since this is user-visible chrome.
3. The acceptance criteria could explicitly say the club name remains linked to `/` if that behavior is intended to be preserved from the existing header.

## Smallest viable iteration

The smallest useful slice is the one already described: replace only the shared `Layouts.club_site` chrome with the app-bar/app-card shell, port the required shell CSS, preserve existing sign-out/identity/footer behavior, and verify all existing `club_site` surfaces still render. Do not include tabs, conversation content alignment, club switching, membership status, or staff/marketing layouts.

## Required plan edits

None required before implementation.

Optional cleanup: explicitly enumerate the six `club_site` surfaces and, if intended, state that the club-name link target remains unchanged.

## Validation plan

Success should be proven by:

1. Automated layout/LiveView tests verifying:
   - app-bar renders the club name;
   - identity dropdown appears only when `current_identity` is present;
   - Sign out still submits to `DELETE /auth`;
   - page content is wrapped in the app-card frame;
   - the “Powered by Memba” footer link remains;
   - every `club_site` surface renders under the new shell.

2. Full project validation:
   - run `dev check` after implementation and require it to pass.

3. Visual/manual validation:
   - run `./bin/dev gallery-walk`;
   - compare club-home and conversation screenshots against the design-system wireframes for app-bar, app-card, and footer;
   - manually confirm signed-in pages show the identity dropdown and Sign out works;
   - manually confirm the public signed-out club page shows no identity dropdown.

Clear stop condition: the shared shell is present across all `club_site` pages, existing behavior is preserved, relevant tests pass, visual comparison matches the refreshed design, and `dev check` is green.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}