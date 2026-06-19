# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: Medium-High

## ADR conformance: PASS

This iteration appears limited to static design-system preview HTML under `docs/design-system/`. It does not touch domain modeling, Commanded/CQRS/event-sourcing infrastructure, event streams, projections/read models, Ecto schemas/migrations, Phoenix routes, LiveViews, templates, background jobs, integrations, or acceptance feature files.

No ADR-governed architecture is affected by the implementation evidence reviewed.

## ADR violations

None.

## Blocking issues

None.

## Bounded-safe fixes

1. **Replace remaining Tailwind layout utilities with local CSS classes**

   Files:

   - `docs/design-system/empty-states/club-home-empty.html`
   - `docs/design-system/empty-states/member-messaging-empty.html`
   - `docs/design-system/staff/review-and-convert-request.html`

   The implementation reportedly still uses Tailwind layout utilities such as:

   - `max-w-2xl`
   - `max-w-4xl`
   - `mx-auto`

   The iteration plan explicitly requires the previews to be self-contained using daisyUI prebuilt CSS plus app theme variables and plain CSS for layout, and it calls out Tailwind utility reliance as a risk.

   This is not a behavioural blocker because these are static previews and the visual output likely still renders through the CDN. However, it is a small plan-convention drift and easy to correct safely.

   Suggested replacement pattern:

   ```css
   .card-centered-narrow {
     max-width: 42rem;
     margin-left: auto;
     margin-right: auto;
   }

   .card-centered-wide {
     max-width: 56rem;
     margin-left: auto;
     margin-right: auto;
   }
   ```

   Then replace markup such as:

   ```html
   <div class="card bg-base-100 shadow-xl max-w-2xl mx-auto">
   ```

   with:

   ```html
   <div class="card bg-base-100 shadow-xl card-centered-narrow">
   ```

   and use the wide variant for the staff review page.

## Judgement-worthy non-blocking code-health findings

1. **Design-system preview class boundary remains implicit**

   Files:

   - New and refreshed `docs/design-system/**/*.html` previews

   Smell:

   The previews appear to intentionally allow daisyUI component/theming classes such as `card`, `btn`, `bg-base-100`, and `shadow-xl`, while discouraging Tailwind layout/spacing utilities such as `mx-auto`, `max-w-*`, `flex`, `grid`, `px-*`, etc.

   Why it may need human judgement:

   The plan says “daisyUI components + plain CSS only” and “does not rely on Tailwind utility classes,” but daisyUI examples commonly mix component classes with utility-like theme helpers. The current boundary is understandable but implicit. Future DS iterations may repeat this debate unless the repo documents a short convention such as:

   - daisyUI component/theme classes are acceptable;
   - layout, spacing, sizing, and responsive behaviour should be expressed with preview-local CSS.

2. **Headless Chrome render-verification evidence is not visible in the review context**

   Files:

   - All new/changed `docs/design-system/**/*.html` previews

   Smell:

   The plan called for headless-Chrome render verification of each new/changed preview. The collected evidence shows `dev check` passed and that the implementation was accepted by the plan-conformance workflow, but the review context does not include screenshot artifacts, render logs, or a checklist proving each static preview was opened and visually checked.

   Why it may need human judgement:

   For these static design-system files, visual rendering is the most relevant validation. I would not block this iteration because the implementation is docs/static-preview-only and the plan-conformance gate has already passed, but future DS catch-up work may benefit from persisted screenshots or a short validation note when render verification is part of the plan.

## Suggested fixes

If applying polish before final merge/follow-up:

1. Add local CSS centering/max-width classes to the three affected preview files.
2. Replace `max-w-2xl mx-auto` and `max-w-4xl mx-auto` with those local classes.
3. Re-run the lightweight headless/browser render check used for design-system previews, if available.
4. Because this is static documentation/preview markup only, a full `dev check` is not inherently necessary under the project workflow unless the team wants to re-confirm the exact final state. If reporting `dev check` for the final state, it must be run after the polish diff is applied.

## Validation notes

- `dev ci` / `dev check` passed successfully.
- Acceptance suite passed: 82 scenarios, 493 steps.
- Sandbox runtime check passed before review.
- No app code, routes, LiveViews, HEEx templates, migrations, schemas, contexts, background jobs, integrations, or `.feature` files appear to have changed.
- The implementation appears consistent with the iteration scope:
  - onboarding request flow previews;
  - staff review/convert preview;
  - new-request notification email preview;
  - empty-state previews;
  - refreshed member club-home and message-read previews.
- Remaining findings are static-preview convention/polish issues, not ADR or product-behaviour defects.