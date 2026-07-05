## Decision: NOT READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/044-shared-app-shell/plan.md` through line 176 and confirmed there were no further lines.

## Blocking gaps

1. **The plan still contains unresolved technical decisions.**  
   The implementation plan explicitly marks identity name/initials plumbing as an `[Open technical decision]`, and the `## Open Technical Decisions` section leaves both CSS sourcing and identity-display plumbing unresolved. A ready-for-implementation plan should make these choices before work starts.

2. **The “six `club_site` surfaces” acceptance criterion is ambiguous.**  
   The plan says all six surfaces must render, but the list appears to name only five or uses ambiguous wording: “club home, conversation/message detail, compose, member invitation, and the public club page.” The exact six surfaces/routes need to be enumerated so implementation and validation have a clear stop condition.

## Non-blocking improvements

1. Clarify the expected fallback identity label and initials when a member display name is unavailable, after the identity plumbing decision is made.
2. Consider naming the specific test module(s) expected to cover the layout changes, if known.
3. Add a short note about whether minor visual differences from the design mirror are acceptable, or whether the shell CSS should be copied exactly except for app integration needs.

## Smallest viable iteration

The smallest useful slice is: update the shared `Layouts.club_site` shell once so every `club_site` surface renders inside the app-frame/app-card with the simplified app-bar, preserves the existing footer and sign-out behavior, and uses a clearly defined identity display contract.

If member-name plumbing is not already straightforward, the smallest viable version could use the existing signed-in identity/email as the identity label and defer richer member display names/initials to a follow-up — but the plan must explicitly choose that and update acceptance criteria accordingly.

## Required plan edits

1. Resolve and remove the open technical decision for CSS sourcing. For example: “Port the app-shell classes from the design-system CSS into `web/assets/css/app.css` with 1:1 class names.”
2. Resolve and remove the open technical decision for identity name/initials plumbing. Specify the exact assign(s), source data, fallback behavior, and which surfaces must provide them.
3. Replace the ambiguous “all six `club_site` surfaces” wording with an exact list of six surfaces and, ideally, their routes or LiveViews/controllers.
4. Update acceptance criteria and validation steps to match the resolved identity-display decision.

## Validation plan

Success should be proven by:

1. Automated layout/LiveView tests showing:
   - app-bar renders the plain club name;
   - signed-in pages render the identity dropdown;
   - signed-out pages do not render the identity dropdown;
   - Sign out still submits to `DELETE /auth`;
   - page content is inside the app-card frame;
   - every explicitly listed `club_site` surface renders.
2. `dev check` passes after implementation.
3. Visual comparison via `./bin/dev gallery-walk` against the refreshed `club-home.html` and `member-conversation.html` design-system wireframes.
4. Manual smoke check of signed-in club home, signed-in conversation, and signed-out public club page.

{"context_updates":{"codex_review_decision":"NOT READY","codex_review_confidence":"High","codex_review_blocking_gap_count":2,"codex_review_blocking_gaps":"Open technical decisions remain for CSS sourcing and identity name/initials plumbing; Acceptance criterion says six club_site surfaces but does not unambiguously enumerate six surfaces/routes","codex_review_required_edits":"Resolve CSS sourcing decision; Resolve identity display assign/source/fallback decision; Enumerate exact six club_site surfaces/routes and align acceptance/validation steps"}}