# Iteration 044 Review: Shared App Shell

## Decision: ACCEPT

## Confidence: Medium

Confidence is limited mainly by the truncated implementation evidence and lack of direct ADR contents in the provided context. The available evidence, plan excerpt, and green `dev check` are strong enough to accept.

## ADR conformance: PASS

No ADR violations were identified from the provided plan/evidence. The plan excerpt cites no specific ADRs, and the implementation appears limited to Phoenix layout/CSS/test work rather than domain modeling, Commanded, CQRS, event sourcing, projections, or read-model boundaries.

The implementation also appears to follow the plan’s explicit technical decision to port the design-system shell classes directly into the application stylesheet instead of re-expressing the shell with Tailwind utilities.

## ADR violations

None.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Unused `flash` assign in the shared layout**
   - **Files:** `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`
   - **Smell:** The layout accepts/passes `flash`, but the evidence does not show flash rendering inside the new `club_site` shell.
   - **Why judgement is needed:** This may be intentional because flash handling is out of scope for this iteration, or because flash is rendered by another/root layout. If `club_site` is now the effective application shell for these pages, a future pass should decide whether flashes belong inside it.

2. **Identity display-name fallback appears duplicated**
   - **File:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The member-name fallback logic appears to be repeated for display text and initials derivation.
   - **Why judgement is needed:** Extracting a helper such as `member_display_name/1` would reduce duplication, but the current duplication is small and may not justify extra abstraction yet.

3. **Dropdown behaviour/a11y may deserve a follow-up check**
   - **File:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The identity menu evidence verifies static DOM shape and the sign-out form, but does not demonstrate dynamic behaviour such as closing the menu, escape/click-away handling, focus management, or `aria-expanded` updates.
   - **Why judgement is needed:** The current implementation likely satisfies the iteration’s structural shell goal, and Phoenix/JS helpers may already provide enough behaviour. However, if the identity dropdown becomes a reusable interaction pattern, it should eventually get explicit accessibility/interaction coverage.

4. **Sign-out form coverage is structural rather than behavioural**
   - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
   - **Smell:** Tests assert the form posts to `/auth` with `_method=delete`, but the evidence does not show a test submitting the new dropdown sign-out form from a club-site page.
   - **Why judgement is needed:** Existing auth tests may already cover the controller route. Still, because this is a new sign-out entry point, a future test could assert the rendered form includes all required fields, especially CSRF protection if a raw `<form>` is used.

## Suggested fixes

No merge-blocking fixes are recommended.

Potential future polish:

- If `club_site` should own flash rendering, add the project-standard flash component to the shell and test it.
- If the identity label logic grows, extract a small helper for member display-name fallback.
- Consider adding an interaction-level test or manual accessibility checklist for the identity dropdown.
- If not already covered elsewhere, add a small assertion that the sign-out form includes CSRF protection or use the project-standard form helper.

## Validation notes

- `dev check` / `dev ci` passed successfully.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- No feature-file changes were indicated.
- Evidence shows tests for:
  - shared `club_site` app frame;
  - app bar rendering the club name;
  - app card/content wrapping;
  - identity dropdown gated by signed-in identity;
  - signed-out public page omitting identity UI;
  - sign-out form shape using `POST /auth` plus `_method=delete`;
  - app-shell CSS class structure;
  - all relevant `club_site` surfaces rendering under the new shell.
- Plan fidelity appears good: the implementation delivers the shared app-like shell and avoids obvious out-of-scope domain or architecture changes.