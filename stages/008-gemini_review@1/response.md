# Iteration 044 Review: Shared App Shell

## Decision: ACCEPT

## Confidence: Medium

The plan-conformance gate, implementation evidence, and green `dev check` are strong. Confidence is not “High” only because the evidence shown here is partially truncated and no specific ADR files were cited in the plan excerpt.

## ADR conformance: PASS

No ADR violations found.

The implementation appears to touch Phoenix layout/components, HEEx, CSS, routing/form structure, and tests. It does not appear to alter domain modeling, Commanded boundaries, aggregates, projections, event streams, read models, or CQRS/event-sourcing infrastructure.

The plan’s explicit technical decision to port the design-system app-shell classes 1:1 into `web/assets/css/app.css` appears to have been followed.

## ADR violations

None.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **`flash` is accepted/passed but not visibly rendered in the new shell**
   - **Files:** `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`
   - **Smell:** The layout tests pass `flash={@flash}`, but the evidence does not show the `club_site` shell rendering a flash group.
   - **Why it may need human judgement:** This may be intentional if flash rendering is handled by an outer/root layout or deferred out of scope. If `club_site` is now the primary shell for these member/public club pages, missing flash rendering could eventually hide redirect or action feedback. The plan did not require flash work, so this should not block the iteration.

2. **Member display-name fallback logic appears duplicated**
   - **File:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The fallback from optional `member_name` to the email local-part appears to be used both for displayed identity text and avatar initials.
   - **Why it may need human judgement:** The duplication is small and readable today. Extracting a helper such as `member_display_name/1` would reduce repeated logic, but may be unnecessary abstraction until this identity presentation grows.

3. **Identity dropdown behaviour is mostly structurally tested**
   - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
   - **Smell:** The evidence shows strong DOM-shape tests for the dropdown and sign-out form, but does not show interaction-level coverage for opening/closing, escape/click-away handling, focus behaviour, or `aria-expanded` state changes.
   - **Why it may need human judgement:** The iteration goal was a shared shell and identity dropdown presence, and the automated structural checks are appropriate for that scope. If this dropdown becomes a reusable app interaction pattern, it should receive explicit accessibility/interaction validation later.

4. **Sign-out form is covered structurally, not end-to-end from the new menu**
   - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
   - **Smell:** Tests assert the form posts to `/auth` with `_method=delete`, but the evidence does not show submitting the new dropdown sign-out form from a rendered club-site page.
   - **Why it may need human judgement:** Existing auth/controller coverage likely verifies the route itself. Still, because this is a new sign-out entry point, a future test could assert the full rendered form includes the expected CSRF token and successfully signs out when submitted.

## Suggested fixes

No required fixes.

Optional future polish:

- If `club_site` owns user-facing flash display, render the project-standard flash component inside the shell and add a focused layout test.
- If the identity fallback logic grows, extract a small helper for display-name derivation.
- Add a lightweight interaction/manual-a11y check for the identity dropdown.
- If not already covered elsewhere, add an assertion that the sign-out form generated in the shell includes CSRF protection.

## Validation notes

- `dev check` / `dev ci` passed before review.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- No feature-file changes were indicated.
- Evidence shows coverage for:
  - shared `club_site` app frame;
  - app bar rendering club name;
  - app-card wrapping inner content;
  - identity dropdown gated by signed-in identity;
  - signed-out public page omitting identity controls;
  - sign-out form shape targeting `DELETE /auth` through POST + `_method=delete`;
  - app-shell CSS class structure;
  - all relevant `club_site` surfaces rendering under the new shell.
- Plan fidelity appears good: the implementation delivers the shared app-like shell without obvious out-of-scope domain or architecture changes.