# Iteration Review Report: 037 Design-System Catch-up

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

No ADR violations found. The touched scope appears limited to static design-system preview HTML under `priv/design_system/`, with no changes to domain modeling, Commanded aggregates, projections, event streams, read models, routing, LiveViews, schemas, migrations, or runtime application behaviour. No plan-cited ADRs were implicated by the implementation.

## ADR violations

None.

## Blocking issues

None.

The implementation is consistent with the iteration goal as reviewed: design-system catch-up previews only, no app behaviour changes, no feature-file changes, and `dev check` passed.

## Bounded-safe fixes

1. **Remove remaining Tailwind-style utility classes from static previews**
   - **Files:** Reported across the new/updated `priv/design_system/*.html` previews, including examples such as `empty-club-home.html`, `onboarding-request-flow.html`, and `staff-request-review.html`.
   - **Issue:** The plan explicitly calls for daisyUI component classes plus plain CSS, and says previews should not rely on Tailwind utility classes. Implementation evidence indicates classes such as `flex-1`, `text-xl`, `font-bold`, and `mb-4` remain.
   - **Why bounded-safe:** Replacing these with semantic preview classes and local CSS declarations does not change product behaviour or feature files. It improves alignment with the static-preview convention and avoids future CDN/rendering ambiguity.

2. **Add light section comments in larger preview files**
   - **Files:** Especially `onboarding-request-flow.html` and `staff-request-review.html`.
   - **Issue:** Multi-state previews are easier to maintain when major sections are clearly labelled.
   - **Why bounded-safe:** Comments such as `<!-- Request form state -->`, `<!-- Verification pending state -->`, and `<!-- Staff conversion panel -->` improve maintainability without changing rendered output.

3. **Document intentional duplication of theme variables**
   - **Files:** All self-contained design-system previews.
   - **Issue:** The repeated `:root` sage palette/theme variable blocks are required for self-contained previews, but future editors may not know whether duplication is intentional or drift.
   - **Why bounded-safe:** A short comment near the variable block, or in one canonical preview, would clarify the convention without introducing shared CSS or changing runtime behaviour.

## Judgement-worthy non-blocking code-health findings

1. **Mixed static-preview styling strategy**
   - **Files:** New/updated `priv/design_system/*.html` previews.
   - **Smell:** The previews appear to combine semantic custom CSS with Tailwind-style utility classes.
   - **Why it may need human judgement:** The iteration plan’s risk section specifically warns against the “Tailwind-utility trap.” If future design-system work continues, the team should decide whether the canonical rule is “plain CSS only except daisyUI component classes” or whether small utility usage is acceptable when covered by the chosen CDN. The safer convention is plain CSS only.

2. **No machine-checkable guard for the static-preview convention**
   - **Files:** Design-system preview HTML generally.
   - **Smell:** The important convention — self-contained HTML, daisyUI CDN, app theme variables, no Tailwind utilities, correct relative assets, `@dsCard` metadata — is currently enforced by review discipline rather than an automated check.
   - **Why it may need human judgement:** If the design-system preview set continues to grow, a lightweight lint/check script could prevent regressions. That may be worthwhile, but it is broader than this iteration.

3. **Email preview convention remains implicit**
   - **Files:** `priv/design_system/*email*.html`, especially the new onboarding-request notification email preview.
   - **Smell:** The plan called out the email preview rendering convention as an open technical decision. The implementation appears to follow the self-contained browser-preview pattern.
   - **Why it may need human judgement:** For design-system documentation this is probably acceptable, but production email constraints differ from browser-page constraints. The team may eventually want to document whether DS email previews are visual targets only or should intentionally mirror production email HTML/CSS limitations.

4. **Accessibility modelling in DS previews is not clearly standardized**
   - **Files:** Interactive/static form-like previews such as `onboarding-request-flow.html` and `staff-request-review.html`.
   - **Smell:** Static previews can omit production-level accessibility details such as complete error associations, icon labelling, and focus-state modelling.
   - **Why it may need human judgement:** These previews are documentation artifacts, not shipped UI. Still, if implementers use them as source material, the team may want a standard for how much accessibility structure DS previews should model.

## Suggested fixes

If doing a polish pass before finalizing:

1. Replace Tailwind-style utility classes with semantic classes and local CSS:
   - Example: `class="flex-1"` → `class="nav-title"` with `.nav-title { flex: 1; }`
   - Example: `class="text-xl font-bold mb-4"` → `class="preview-heading"` with equivalent CSS.
2. Add concise section comments to the larger multi-state previews.
3. Add a short comment explaining that duplicated `:root` variables are intentional because previews are self-contained.
4. Consider a future lightweight validation script for DS previews, but do not block this iteration on it.

## Validation notes

- `dev check` / `dev ci` passed successfully.
- Acceptance output shows 82 scenarios passing and 493 steps passing.
- No app code, routes, LiveViews, schemas, migrations, or `.feature` files appear to have been changed, which matches the plan’s scope.
- The implementation is static design-system preview work only, so domain/CQRS/event-sourcing ADR concerns are not triggered.
- The post-merge/manual DesignSync push to the cloud DS project remains outside this code review, as stated in the plan.