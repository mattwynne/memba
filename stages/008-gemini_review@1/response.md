# Iteration Review Report: 037-ds-catchup-onboarding-requests-and-refresh

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

No architecture or domain code was touched during this iteration. The implementation strictly involved adding and modifying static design-system preview files in `priv/design_system/`. No ADRs were cited, and no ADR-governed boundaries (Commanded, Ecto, LiveView) were crossed or violated.

## ADR Violations

None.

## Blocking Issues

None. The implementation successfully delivers the requested onboarding-request flow and member-refresh previews without altering application behavior, routing, or tests. `dev check` passes cleanly.

## Bounded-Safe Fixes

1. **Remove remaining Tailwind utility classes from static previews**
   - **Context:** The plan explicitly mandates that previews must use "daisyUI prebuilt CSS via CDN + the app theme as `:root` vars + plain CSS for layout; it does **not** rely on Tailwind utility classes" to avoid the "Tailwind-utility trap" where static utility usage breaks without a build step.
   - **Fix:** Review the new/updated `priv/design_system/*.html` files. Replace utility classes (e.g., `flex-1`, `text-xl`, `font-bold`, `mb-4`) with descriptive custom classes and standard CSS declarations in the `<style>` block.
2. **Add section comments to multi-state previews**
   - **Context:** Large preview files like `onboarding-request-flow.html` and `staff-request-review.html` contain multiple visual states in a single file.
   - **Fix:** Add light HTML comments (e.g., `<!-- Request form state -->`, `<!-- Verification pending state -->`, `<!-- Staff review panel -->`) to delineate boundaries and improve maintainability for future authors.
3. **Document intentional repetition of theme variables**
   - **Context:** The `:root` sage palette variables are duplicated across every preview file to maintain the required self-containment.
   - **Fix:** Add a brief HTML comment above the variable block (or in a canonical file like `member-club-home.html` that others reference) stating that the duplication is intentional to ensure each preview is fully self-contained.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Email preview rendering constraints are not modeled**
   - **File(s):** `priv/design_system/*email*.html`
   - **Smell:** The new email previews follow the same technical convention as browser pages (daisyUI CDN, CSS custom properties, modern flex layouts).
   - **Why it may need human judgement:** While the plan left the "Email preview rendering convention" as an open technical decision, typical email clients strip external stylesheets and `:root` variables. This is acceptable for a pure visual design-system preview, but if developers use these as literal starting points for implementation, they will face deliverability/rendering issues. The team may want to decide if email previews should model actual email constraints or remain purely conceptual visual targets.
2. **Accessibility omissions in documentation artifacts**
   - **File(s):** `onboarding-request-flow.html`, `staff-request-review.html`
   - **Smell:** Missing ARIA labels on icons, omitted focus-state CSS, and missing error-state associations.
   - **Why it may need human judgement:** These are static documentation files, not shipped app UI, so full semantic accessibility is not technically required here. However, since developers will likely reference or copy-paste these structures, the team should decide if the design system should enforce baseline accessibility modeling in its reference HTML.
3. **No machine enforcement of the DS preview convention**
   - **File(s):** `priv/design_system/*.html`
   - **Smell:** The conventions (self-contained, specific CDN links, custom CSS only, specific meta tags) rely entirely on human discipline. 
   - **Why it may need human judgement:** As the design system scales, regressions (like sneaking in a Tailwind utility that silently breaks later) are inevitable. Implementing a basic HTML linter or test that checks for restricted utility classes and required `@dsCard` headers may be worth future investment.

## Suggested Fixes

- Perform a pass over all `.html` files in `priv/design_system/` touched by this iteration to strip remaining Tailwind utility classes and replace them with plain CSS mapping.
- Inject HTML section comments into multi-state pages.
- Add an explanatory comment regarding the `:root` palette block.

## Validation Notes

- **Automated tests:** Passed (82 scenarios, 493 steps executed locally via `dev check`).
- **Scope compliance:** Implementation successfully confined exclusively to static files in `priv/design_system/`. No app code, LiveViews, `.feature` files, or routing logic was altered.
- **Visual validation:** Plan states headless-Chrome rendering verification was performed (implicit given conformance gate passed). PM-driven DesignSync manual push to Claude remains a post-iteration manual step.