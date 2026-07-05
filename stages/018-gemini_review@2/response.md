# Iteration 044 Review: Shared App Shell

## Decision: ACCEPT

## Confidence: Medium

The implementation appears plan-conforming, `dev check`/`dev ci` is green, and the collected evidence shows the important shared-shell behaviours are covered. Confidence is Medium rather than High because the review evidence is partially truncated and no specific ADR files were cited in the plan excerpt, but the touched implementation area appears to be Phoenix layout/HEEx/CSS/tests rather than domain, CQRS, event sourcing, or read-model architecture.

The two synthesized “blockers” should not block this merge:

1. The CSRF concern is already covered by evidence: the layout test asserts a hidden `_csrf_token` input with a non-empty value inside `#club-site-sign-out-form`.
2. The member display-name fallback concern is, at most, a small maintainability/refactoring smell. It is not an ADR, behavioural, or safety issue.

## ADR conformance: PASS

No ADR violations found.

The plan excerpt does not cite specific ADRs. Based on the available evidence, the implementation is limited to:

- Phoenix layout/component structure.
- HEEx rendering.
- CSS class porting from the design-system shell.
- Layout/component tests.
- Existing auth sign-out form wiring.

It does not appear to alter or bypass ADR-governed domain, Commanded, event-sourcing, CQRS, projection, read-model, or aggregate boundaries.

The plan’s explicit technical decisions appear followed:

- Design-system shell class names are used directly: `app-frame`, `app-bar`, `app-card`, `app-menu`, `app-foot`, etc.
- Signed-in member surfaces pass identity/name data into the shared shell.
- Signed-out public club page omits the identity dropdown.
- Sign out is rendered as a Phoenix form targeting `/auth` with `_method=delete` and a CSRF token.
- All relevant `club_site` surfaces render under the new shell.

## ADR violations

None.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Flash assign appears accepted by `club_site` but not visibly rendered in the shell**

   - **Files:** `web/lib/memba_web/components/layouts.ex`, `web/test/memba_web/components/layouts_test.exs`
   - **Smell:** Tests and call sites pass `flash={@flash}`, but the collected evidence does not show the new `club_site` shell rendering a flash group.
   - **Why it may need human judgement:** This may be intentional if flash remains owned by an outer/root layout, or if flash display was intentionally out of scope for this shell iteration. If `club_site` is now the effective app shell for member-facing pages, hidden flash messages could become a UX regression later. Not blocking because the plan did not require flash changes and the current automated checks pass.

2. **Identity dropdown coverage is structural rather than interaction-level**

   - **Files:** `web/lib/memba_web/components/layouts.ex`, `web/test/memba_web/components/layouts_test.exs`
   - **Smell:** Evidence verifies DOM structure, menu placement, identity gating, sign-out form fields, and CSRF token presence, but not dynamic dropdown behaviour such as open/close, escape/click-away, focus management, or changing `aria-expanded`.
   - **Why it may need human judgement:** Structural coverage is reasonable for a shared layout shell. If this dropdown becomes a reusable interaction pattern, it should eventually receive explicit accessibility/interaction validation, either automated or manual.

3. **Sign-out from the new menu is tested structurally, not end-to-end**

   - **Files:** `web/lib/memba_web/components/layouts.ex`, layout/component tests
   - **Smell:** Tests assert the form posts to `/auth`, uses method override `_method=delete`, includes a non-empty CSRF token, and has a submit button, but the evidence does not show a browser/request-level test submitting sign out from a rendered club-site page.
   - **Why it may need human judgement:** Existing auth route/controller coverage likely verifies the sign-out behaviour itself. The layout-level structural test is probably sufficient for this iteration, but an integration/browser assertion could be useful if sign-out menu regressions become likely.

4. **Manual visual validation artifact is not shown in the review evidence**

   - **Files/areas:** `web/assets/css/app.css`, shared `club_site` shell, gallery screenshots
   - **Smell:** The plan calls for `./bin/dev gallery-walk` and comparison to `design-system/wireframes/club-home.html` and `member-conversation.html`. The provided evidence shows `dev ci`/`dev check` success, but not gallery-walk output or screenshot comparison notes.
   - **Why it may need human judgement:** This iteration is visually oriented, so visual validation matters. However, the implementation evidence strongly verifies the intended shell structure and design-system class usage, and the review workflow is primarily code-health/ADR focused. I would not block merge unless the team treats gallery-walk artifacts as mandatory for this class of change.

5. **Member identity display fallback may deserve a named helper if it grows**

   - **File:** `web/lib/memba_web/components/layouts.ex`
   - **Smell:** The shell derives identity display from optional `member_name` with fallback to the email local part, and also derives initials for the avatar. If this logic is duplicated or expands, it could drift.
   - **Why it may need human judgement:** Today this is small presentation logic and does not justify blocking. If future slices add richer member names, role badges, profile links, avatars, or privacy rules, this should become a named helper/component boundary with focused tests.

## Suggested fixes

No required fixes before merge.

Optional future follow-ups:

- Decide whether `club_site` should render the project-standard flash component or whether flash remains outside this layout.
- Add manual or automated a11y/interaction validation for the identity dropdown if it becomes a reusable pattern.
- Consider an integration/browser test that submits the sign-out form from a club-site page if auth-entry regressions become a concern.
- Centralize identity display-name/initials derivation if identity presentation grows.

## Validation notes

- `dev ci` / `dev check` passed.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- No acceptance feature-file changes were indicated.
- Evidence shows coverage for:
  - Shared `club_site` app frame.
  - App bar rendering the club name.
  - `app-card` wrapping page content.
  - Signed-in identity dropdown presence.
  - Signed-out public page omitting the identity dropdown.
  - Sign-out form targeting `/auth` via POST with `_method=delete`.
  - Hidden `_csrf_token` input with a non-empty value.
  - Submit button labelled “Sign out”.
  - Design-system shell class usage.
  - Absence of old inline `--club-site-` styling on the shell.
  - All relevant `club_site` surfaces rendering under the new shared shell.

Overall, the implementation is mergeable. The remaining observations are polish and future-maintenance considerations, not blockers.