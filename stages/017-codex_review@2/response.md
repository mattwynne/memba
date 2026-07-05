# Iteration 044 Review: Shared App Shell

## Decision: ACCEPT

## Confidence: Medium

The implementation appears plan-conforming, automated validation is green, and the reviewed evidence shows the key shell behaviours are covered. Confidence is Medium rather than High because the evidence available in this review is partially truncated and no direct ADR file contents were provided, but the touched area is UI/layout/CSS and does not appear to exercise the project’s domain/CQRS/event-sourcing architecture.

## ADR conformance: PASS

No ADR violations found.

The plan excerpt cites no specific ADRs. The implementation appears limited to Phoenix layout/component, HEEx, CSS, and tests. It does not appear to alter aggregates, commands, events, projections, read models, routing architecture beyond layout usage, or infrastructure decisions governed by the domain/CQRS/event-sourcing ADRs.

The explicit plan decisions were followed in the available evidence:

- The shared `club_site` shell uses the design-system class names such as `app-frame`, `app-bar`, `app-card`, `app-menu`, and `app-foot`.
- Identity UI is optional and gated by signed-in member identity.
- Member name fallback/initials behaviour is tested.
- Public signed-out club pages render without the member identity dropdown.
- Sign out is wired as `POST /auth` with `_method=delete` and a CSRF token.

## ADR violations

None.

## Blocking issues

None.

The two synthesized blockers do not appear to be actual merge blockers:

1. **CSRF protection for club-site sign out** — evidence shows the layout test asserts a hidden `_csrf_token` input with a non-empty value inside `#club-site-sign-out-form`.
2. **Member display-name fallback duplication** — at most this is a small refactoring/code-health concern. It does not create a behavioural or architectural defect requiring rejection.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Flash assign is accepted but not visibly rendered by the shell**
   - **Files:** `web/lib/memba_web/components/layouts.ex`, `web/test/memba_web/components/layouts_test.exs`
   - **Smell:** The `club_site` layout is invoked with `flash={@flash}`, but the evidence does not show the shared app shell rendering a flash group.
   - **Why it may need human judgement:** This may be intentional if flash rendering remains owned by an outer/root layout or if flash display is outside this iteration’s scope. If `club_site` is now the effective app shell for member-facing pages, hidden flash messages could become a UX issue later. Not blocking because the plan did not require flash changes and existing checks are green.

2. **Identity display-name fallback logic may be worth centralizing if it grows**
   - **File:** `web/lib/memba_web/components/layouts.ex`
   - **Smell:** The optional `member_name` / email-local-part fallback is used to drive both displayed identity text and initials. Even if currently deduped or small, this is a likely place for future drift as identity presentation grows.
   - **Why it may need human judgement:** Extracting a helper is simple, but adding indirection for two call sites may be premature. If later work adds role badges, names, avatars, or richer member identity data, this should become a named helper or component boundary.

3. **Identity dropdown coverage is structural, not interaction-level**
   - **Files:** `web/lib/memba_web/components/layouts.ex`, `web/test/memba_web/components/layouts_test.exs`
   - **Smell:** Tests assert the DOM shape and sign-out form but do not demonstrate open/close behaviour, focus handling, escape/click-away behaviour, or dynamic ARIA updates.
   - **Why it may need human judgement:** Structural coverage is appropriate for this iteration’s shared-shell goal. If the dropdown becomes a reusable application interaction pattern, it should eventually receive explicit accessibility/interaction coverage or a manual a11y checklist.

4. **Sign-out from the new menu is tested structurally rather than end-to-end**
   - **Files:** `web/lib/memba_web/components/layouts.ex`, layout/component tests
   - **Smell:** Evidence verifies `POST /auth`, `_method=delete`, CSRF token presence, and the submit button, but does not show a browser/request-level test submitting sign out from a rendered club-site page.
   - **Why it may need human judgement:** Existing auth route/controller tests likely cover the actual sign-out behaviour. The new shell entry point is probably adequately covered by form-structure tests, but an end-to-end assertion could add confidence if sign-out regressions become likely.

5. **Manual visual validation is not evidenced in the review output**
   - **Files/areas:** `web/assets/css/app.css`, shared shell layout, gallery screenshots
   - **Smell:** The plan calls for `./bin/dev gallery-walk` and comparison against design-system wireframes. The provided pipeline evidence shows `dev ci`/`dev check` success but not a gallery-walk artifact.
   - **Why it may need human judgement:** This is a CSS/design fidelity slice, so visual validation matters. However, the review workflow is primarily automated/code-health focused, and the structural tests strongly verify shell class usage. I would not block merge solely on missing visual evidence unless the team treats gallery-walk artifacts as mandatory for design-system iterations.

## Suggested fixes

No required fixes before merge.

Optional follow-ups:

- Decide whether `club_site` should render the project-standard flash component.
- If identity presentation expands, extract a single helper/component for member display label and initials.
- Add an accessibility/interaction check for the identity dropdown if it becomes reused.
- Consider a small integration/browser test for submitting sign out from the club-site shell if auth regressions appear.

## Validation notes

- `dev ci` / `dev check` passed.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- No acceptance feature-file changes were indicated.
- Evidence shows tests for:
  - shared `club_site` app frame;
  - app bar rendering the club name;
  - `app-card` wrapping page content;
  - signed-in identity dropdown presence;
  - signed-out public page omitting identity controls;
  - sign-out form targeting `/auth` with `_method=delete`;
  - CSRF hidden token presence and non-empty value;
  - app-shell class structure and absence of old inline `--club-site-` styling;
  - all relevant `club_site` surfaces rendering under the new shell.
- Plan fidelity appears sound: the implementation delivers the shared app-like shell without obvious out-of-scope domain or architecture changes.