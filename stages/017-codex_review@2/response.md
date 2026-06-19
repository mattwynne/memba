# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation is limited to static design-system HTML preview files under `design-system/`. It does not touch domain modeling, Commanded/CQRS/event-sourcing infrastructure, aggregates, commands, events, projections, read models, Ecto schemas/migrations, Phoenix routes/controllers/LiveViews/templates, background jobs, integrations, or acceptance feature files.

No ADR-governed architecture appears to be affected by this iteration.

## ADR violations

None.

## Blocking issues

None.

The synthesized blocker `remove-tailwind-layout-utilities-from-ds-previews` is not supported by the collected repair evidence. The alleged paths under `docs/design-system/...` do not exist in this checkout, and the actual iteration files live under `design-system/`. The repair pass scanned the changed design-system HTML files and found no `max-w-*` or `mx-auto` usage to replace. No working-tree diff was produced because the reported issue was already absent.

## Bounded-safe fixes

None.

## Judgement-worthy non-blocking code-health findings

1. **Design-system preview class-usage convention remains implicit**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The previews intentionally distinguish between allowed daisyUI component/theme classes and disallowed Tailwind layout/spacing/sizing utilities. That boundary is reasonable for self-contained static previews, but it appears to be encoded mainly in iteration plans/conventions rather than in a durable design-system README or lintable rule.
   - **Why it may need human judgement:** Future DS work may repeatedly debate whether classes like `bg-base-100`, `shadow-xl`, or daisyUI helpers are acceptable while layout classes like `mx-auto`/`max-w-*` are not. A short convention note could prevent repeated false-positive review findings.

2. **Render-verification evidence is not visible in the review artifacts**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The plan called for headless-Chrome render verification of each new/changed preview. The available evidence confirms `dev check` and plan-conformance success, but does not include screenshots, render logs, or a checklist showing each static preview was opened and visually inspected.
   - **Why it may need human judgement:** For static design-system previews, visual rendering is the main validation signal. This is not blocking because the implementation workflow already proved plan conformance and the files do not affect app behaviour, but future DS iterations may benefit from persisted screenshots or a concise validation note.

## Suggested fixes

No required fixes for this iteration.

Optional follow-up: document the static DS preview convention, for example:

- daisyUI component/theme classes are acceptable;
- preview layout, spacing, sizing, and responsive behaviour should be expressed with local CSS;
- previews should remain self-contained and not rely on app Tailwind bundles or shared app CSS.

## Validation notes

- `dev ci` / `dev check` passed successfully.
- Acceptance suite passed: 82 scenarios, 493 steps.
- Sandbox runtime check passed before review.
- No app code, routes, LiveViews, HEEx templates, Ecto schemas/migrations, contexts, background jobs, integrations, or `.feature` files were changed according to the collected evidence.
- The iteration scope appears satisfied: onboarding request previews, staff review/convert preview, new-request notification email preview, empty-state previews, and refreshed member previews.
- The previously reported Tailwind utility blocker appears to have been a false positive from incorrect paths/stale assumptions; the repair scan found no matching `max-w-*` or `mx-auto` utilities in the actual changed design-system files.