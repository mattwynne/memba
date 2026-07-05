# Iteration 044 Review Report: Shared App Shell

## Decision: ACCEPT

## Confidence: Medium

Would be High with direct access to ADR files governing UI/layout/CSS decisions and full JavaScript implementation evidence for dropdown behaviour.

## ADR Conformance: PASS

No ADR violations detected in the implementation. The CSS porting approach (component classes from design-system rather than Tailwind utilities) is explicitly decided in the plan's "Open Technical Decisions" section and aligns with the README guidance that the design system is the source of truth. However, could not verify against all potentially relevant ADRs since none were explicitly cited in the plan.

## ADR Violations

None found.

## Blocking Issues

None found.

The implementation:
- Follows the plan's stated goal and capability (shared app-shell layout for club-site surfaces)
- Passes `dev check` with full test suite green
- Implements all planned components (app-bar, app-card, identity dropdown, footer)
- Provides comprehensive test coverage for layout structure, conditional rendering, and the initials helper
- Leaves feature files unchanged (domain acceptance criteria preserved)

## Bounded-Safe Fixes

None identified. The potential improvements below require human judgement about product intent or architectural direction.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Unused `@flash` assign** (files: `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`)
   - **Smell:** The layout tests pass `flash={@flash}` but the implementation doesn't render flash messages anywhere in the component.
   - **Why it needs judgement:** This could indicate (a) incomplete implementation if flash should be rendered in the app-shell, (b) intentional deferral if flash rendering is planned for a later iteration, or (c) vestigial code if flash is handled by a parent layout. Typical Phoenix root layouts render flash, and this appears to be a root layout for club sites (has full page structure from header to footer). However, the plan makes no mention of flash rendering, and the tests don't verify it, suggesting it's out of scope. A human should decide whether to remove the unused assign, add flash rendering, or document the deferral.

2. **Member name/initials fallback duplication** (file: `lib/memba_web/components/layouts.ex`)
   - **Smell:** The expression `assigns[:member_name] || String.split(@member_identity, "@") |> hd()` appears twice (once for initials, once for display name).
   - **Why it needs judgement:** Extracting this to a private helper like `member_display_name/1` would reduce duplication and make the fallback logic more explicit. However, with only two call sites and clear inline logic, the marginal benefit might not justify the abstraction. A human should weigh maintainability vs simplicity.

3. **Dropdown JavaScript dependency** (file: `lib/memba_web/components/layouts.ex`)
   - **Smell:** The identity dropdown relies on `MembaWeb.CoreComponents.show("#club-site-identity-menu")` for click handling, but the implementation evidence doesn't show the JavaScript side or tests verifying dynamic ARIA attribute updates (e.g., `aria-expanded` toggling when menu opens/closes).
   - **Why it needs judgement:** Phoenix CoreComponents typically provide dropdown/modal functions, so this is likely correct. However, without seeing the JS implementation or tests, can't verify full accessibility compliance (dynamic ARIA updates) or that the dropdown interaction works as expected. If CoreComponents doesn't provide `show/1`, or if ARIA states aren't updated, this could be a usability/a11y gap. A human should verify the JS side exists and handles ARIA correctly, or flag for manual accessibility testing.

## Suggested Fixes

None blocking. The implementation is solid as-is. The judgement-worthy items above are for potential future polish:

- **If flash should be rendered:** Add `<.flash_group flash={@flash} />` in the layout and verify with tests.
- **If flash is intentionally deferred:** Remove the unused `flash` assign from tests or add a comment documenting the deferral.
- **If duplication bothers future maintainers:** Extract `member_display_name/1` helper for the name/identity fallback logic.
- **For accessibility verification:** Manually test or add JavaScript tests confirming aria-expanded updates when dropdown toggles.

## Validation Notes

### Automated Coverage (Green)
- **Layout structure tests:** App-bar, app-card, app-foot, club name, identity dropdown, Sign out form all verified via DOM selectors.
- **Conditional rendering:** Identity dropdown correctly gated when signed out (no `member_identity` assign).
- **Initials helper edge cases:** Full name, email, empty string, nil, whitespace, single word all covered.
- **Sign-out form structure:** POST to `/auth` with `_method=delete` verified.
- **CSS class naming:** Tests confirm app-frame, app-bar, app-card, app-menu, app-foot classes present; legacy `--club-site-` variables absent.

### Dev Check (Passed)
- Full test suite green (85 scenarios, 523 steps, 3m57s).
- No feature file changes (domain acceptance criteria unchanged).
- Elixir compilation clean.

### Plan Fidelity
- All 14 implementation steps addressed in the evidence.
- CSS classes ported from design-system as decided (app-frame, app-bar, app-card, app-menu, app-foot, identity-dropdown pieces).
- Identity dropdown with member name/initials implemented.
- Signed-out public page correctly omits identity UI.
- Tests added for all club-site surfaces rendering under new shell (per step 12).

### Manual Validation Deferred
The plan calls for `./bin/dev gallery-walk` and screenshot comparison to design-system wireframes. This is manual validation outside the review scope, but the automated tests provide strong structural confidence.

---

**Summary:** This is a clean, plan-conforming implementation with solid test coverage and no blocking issues. The three non-blocking findings are minor code-health observations that may merit future attention but should not delay merge. The unused `@flash` assign is the only item worth brief human confirmation (intentional deferral vs oversight), but given the plan silence on flash rendering, it's likely out of scope. Recommend **accept and merge**.