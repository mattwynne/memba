## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/plan.md`. The plan is ready for implementation. It clearly frames the iteration as a technical/design-system catch-up slice, not an app-behaviour change, and it gives enough scope, constraints, acceptance criteria, implementation steps, and validation guidance for an implementer to proceed without starting implementation now.

## Blocking gaps

None.

## Non-blocking improvements

1. **Name the minimum empty-state set more explicitly.**  
   The plan says “canonical empty states such as a club home with no messages yet.” This is likely enough, but it would be stronger if it named the minimum required empty-state preview(s), e.g. “club home with no messages” as mandatory and others optional.

2. **Enumerate the email-verification states for the public account-request flow.**  
   The plan requires “email-verification states,” but could be clearer by listing the exact states expected, such as submitted/check-email, verified entry, expired/invalid token, or already verified if applicable.

3. **Add a concrete render-verification command or convention if one exists.**  
   The plan correctly requires headless-Chrome render verification, but implementation would be smoother if it pointed to the exact command/script used in iteration 036 or stated that the implementer should follow that convention.

4. **Clarify repo preview paths once iteration 036 has landed.**  
   The dependency on the repo preview-location convention from 036 is acceptable, but once 036 is merged, the plan could be updated with exact directories/file naming expectations.

5. **Turn “visually matches the shipped surface” into a slightly more objective comparison checklist.**  
   For example: palette, major layout regions, button/avatar/status-badge treatment, key copy, form states, and email layout.

## Smallest viable iteration

The smallest useful slice would be:

> Add/refresh repo-side DS previews for the onboarding-request journey only: public account request with email-verification states, staff request-review/convert screen, and new-request notification email, each self-contained and render-verified.

That said, the current combined scope is still coherent and implementable because it is all one outcome: finishing the DS catch-up so the design system reflects shipped app surfaces. The empty-state/member-refresh work is related enough to remain in this iteration.

## Required plan edits

None required before implementation.

Optional edits would be to specify the exact empty-state minimum, enumerate email-verification states, and add the concrete render-verification command/convention once known.

## Validation plan

To prove the iteration succeeded:

1. Confirm new or updated repo-side DS preview files exist for:
   - Public account-request flow with email-verification states.
   - Staff request review and convert screen.
   - New-request notification email.
   - Empty/first-run state previews.
   - Refreshed club-home and member messaging/read previews.

2. Confirm every preview is self-contained:
   - Uses daisyUI prebuilt CSS via CDN.
   - Includes app theme `:root` variables.
   - Uses plain CSS for layout.
   - Does not rely on unresolved Tailwind utility classes.
   - Does not link bespoke shared component CSS.

3. Confirm every preview has the required `@dsCard` header and correct relative asset paths.

4. Render-verify every new/changed preview in headless Chrome and compare against the corresponding shipped app surface.

5. Confirm the diff does not change app code, routes, LiveViews, templates, or `.feature` files.

6. Run `dev check` and require it to pass.

7. After merge, PM manually pushes approved preview files to the cloud DS via DesignSync and visually confirms the cards render correctly in `claude.ai/design`.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}