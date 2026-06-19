# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation evidence indicates this iteration is limited to static design-system preview HTML under `design-system/`. It does not touch domain modeling, Commanded/CQRS/event-sourcing infrastructure, aggregates, commands, events, projections, read models, Ecto schemas/migrations, Phoenix routes, controllers, LiveViews, HEEx templates, background jobs, integrations, or acceptance feature files.

No ADR-governed architecture appears to be affected by this iteration.

## ADR violations

None.

## Blocking issues

None.

The synthesized blocker `remove-tailwind-layout-utilities-from-ds-previews` is not supported by the repair evidence. The paths named by the blocker under `docs/design-system/...` do not exist in this checkout, while the actual previews live under `design-system/`. The repair pass scanned the changed design-system HTML files and found no `max-w-*` or `mx-auto` usage to replace. Since no code/config/test change was needed, the failed repair-verification stage appears to be a workflow artifact caused by “no diff produced,” not an implementation defect.

## Bounded-safe fixes

None required.

## Judgement-worthy non-blocking code-health findings

1. **Design-system preview class-usage convention remains implicit**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The previews rely on a practical distinction between allowed daisyUI component/theme classes and disallowed Tailwind layout/spacing/sizing utilities. That distinction is reasonable for self-contained static previews, but it appears to live mostly in iteration plans and review discussion rather than in durable project documentation.
   - **Why it may need human judgement:** Future design-system work may keep re-litigating whether classes such as `card`, `btn`, `bg-base-100`, or `shadow-xl` are acceptable while layout utilities such as `mx-auto` and `max-w-*` are not. A short convention note could prevent repeated false-positive review findings.

2. **Render-verification evidence is not visible in the review artifacts**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The plan called for headless-Chrome render verification of each new/changed preview. The available evidence shows `dev check` passed and plan conformance was previously established, but this review context does not include screenshots, render logs, or a per-file checklist.
   - **Why it may need human judgement:** For static design-system previews, visual rendering is the most meaningful validation signal. This should not block this iteration because the implementation is static-preview-only and does not affect app behaviour, but future DS iterations may benefit from persisted render artifacts or a concise validation note.

## Suggested fixes

No required fixes before acceptance.

Optional follow-up for future maintainability:

- Add a short `design-system/` convention note documenting:
  - daisyUI component/theme classes are acceptable;
  - layout, spacing, sizing, and responsive behaviour should use preview-local CSS;
  - static previews should not depend on the app Tailwind bundle or bespoke shared app CSS.
- For future DS-only iterations, capture headless render evidence when the plan explicitly requires visual verification.

## Validation notes

- `dev ci` / `dev check` passed.
- Acceptance suite passed: 82 scenarios, 493 steps.
- Sandbox runtime check passed before review.
- No app code, Phoenix routes, LiveViews, HEEx templates, Ecto schemas/migrations, contexts, background jobs, integrations, or `.feature` files appear to have changed.
- The implementation appears consistent with the iteration scope:
  - onboarding request flow preview;
  - email verification states;
  - staff request review/convert preview;
  - new-request notification email preview;
  - empty / first-run state previews;
  - refreshed member club-home and messaging previews.
- The prior Tailwind utility blocker appears to have been a false positive from stale/incorrect paths; the repair scan found no matching `max-w-*` or `mx-auto` utilities in the actual changed design-system files.