# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation evidence indicates this iteration is limited to static design-system preview HTML under `design-system/`. It does not touch ADR-governed application architecture: domain models, Commanded/CQRS/event-sourcing infrastructure, aggregates, commands, events, projections, Ecto schemas/migrations, Phoenix routes/controllers/LiveViews/templates, integrations, background jobs, or acceptance feature files.

No accepted ADR appears to govern the static preview artifacts directly, and no ADR-mandated architecture was bypassed or replaced.

## ADR violations

None.

## Blocking issues

None.

The synthesized blocker `document-static-ds-preview-class-conventions` is not a merge blocker for this iteration. The preview class/CSS convention is useful maintainability documentation, but the absence of a committed convention document does not violate the iteration plan, an ADR, or app behavior. The implementation evidence shows the actual previews comply with the plan’s self-contained preview requirements and avoid the problematic Tailwind utility dependency.

## Bounded-safe fixes

None required before acceptance.

## Judgement-worthy non-blocking code-health findings

1. **Static design-system preview class conventions remain implicit**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The previews rely on an important convention: daisyUI component/theme classes are acceptable in static previews, while Tailwind layout/spacing/sizing/typography/flex/grid utilities should be avoided because these files load prebuilt daisyUI CSS rather than the compiled app Tailwind bundle.
   - **Why it may need human judgement:** This is likely to recur in future DS work and reviews. A durable `design-system/README.md` or similar convention note would reduce repeated debate around classes such as `btn`, `card`, `badge`, `bg-base-100`, and `shadow-xl` versus unsafe utilities such as `mx-auto`, `max-w-*`, `px-*`, `gap-*`, `text-sm`, `flex`, and `grid`.

2. **Headless render-verification evidence is not visible in review artifacts**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The plan called for headless-Chrome render verification of each new/changed preview. The available review evidence shows successful `dev check` and plan-conformance gating, but does not include screenshots, render logs, or a per-file visual checklist.
   - **Why it may need human judgement:** Static design-system previews are primarily validated visually, and they do not receive meaningful coverage from normal Phoenix tests. This should not block this already plan-conforming static-preview iteration, but future DS iterations may benefit from persisted screenshot artifacts or a short validation note when render verification is explicitly required.

## Suggested fixes

No required fixes for this iteration.

Optional follow-up:

- Add a concise `design-system/README.md` documenting:
  - previews are self-contained static HTML;
  - daisyUI CDN component/theme classes are allowed;
  - Tailwind utilities requiring compilation/JIT are disallowed;
  - layout and responsive behavior should use preview-local semantic CSS;
  - email previews should use email-safe markup/inline styles;
  - changed previews should be visually/render-verified before cloud DS push.

## Validation notes

- `dev ci` / `dev check` passed.
- Acceptance suite passed: **82 scenarios, 493 steps**.
- Sandbox runtime check passed before review.
- Evidence indicates no application code changed:
  - no Phoenix routes/controllers/LiveViews/templates;
  - no Ecto schemas/migrations/contexts;
  - no Commanded/domain/event-sourcing artifacts;
  - no background jobs or integrations;
  - no `.feature` files.
- The implementation appears consistent with the iteration scope:
  - public onboarding request flow preview;
  - email-verification states;
  - staff request review/convert preview;
  - new-request notification email preview;
  - empty / first-run state previews;
  - refreshed club-home and member messaging previews aligned to post-034 member pages.
- Prior Tailwind-utility concerns appear unsupported by the collected evidence; the actual changed files live under `design-system/`, and scans/review evidence found no matching problematic `max-w-*` / `mx-auto` style usage in those changed preview files.