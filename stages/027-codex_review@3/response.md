# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation evidence shows this iteration is limited to static design-system preview HTML under `design-system/`. It does not touch domain modeling, Commanded/CQRS/event-sourcing infrastructure, aggregates, commands, events, projections, read models, Ecto schemas/migrations, Phoenix routes/controllers/LiveViews/templates, background jobs, integrations, or acceptance feature files.

No plan-cited or nearby accepted ADR appears to govern the touched artifacts directly, and no ADR-mandated architecture was replaced or bypassed.

## ADR violations

None.

## Blocking issues

None.

The synthesized blocker `document-static-ds-preview-class-conventions` is not a merge blocker for this iteration. All three prior review passes classified it as non-blocking maintainability documentation. The iteration plan required static previews to avoid Tailwind utility dependence, and the evidence indicates the changed preview files comply. A durable convention note would be useful, but the absence of that note does not violate an ADR, break app behaviour, or leave the planned capability incomplete.

## Bounded-safe fixes

None required before acceptance.

## Judgement-worthy non-blocking code-health findings

1. **Static design-system preview CSS/class conventions remain implicit**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The previews rely on an important convention: daisyUI component/theme classes are acceptable, but Tailwind layout/spacing/sizing/typography/flex/grid utilities should not be used because these previews load prebuilt daisyUI CSS rather than the app Tailwind bundle. The convention is demonstrated by the files and described in iteration planning/review context, but does not appear to be durably documented in the design-system directory.
   - **Why it may need human judgement:** Future DS contributors may repeatedly debate whether classes like `btn`, `card`, `badge`, `bg-base-100`, or `shadow-xl` are safe while classes like `mx-auto`, `max-w-*`, `px-*`, `gap-*`, `text-sm`, `flex`, and `grid` are not. A short `design-system/README.md` or lint/check rule could prevent future false positives and drift, but this is maintainability guidance rather than a correctness defect in this iteration.

2. **Headless render-verification evidence is not visible in the supplied artifacts**

   - **Files:** New/changed `design-system/**/*.html` previews.
   - **Smell:** The plan called for headless-Chrome render verification of each preview. The available review context shows successful `dev check` and plan-conformance evidence, but does not include screenshots, render logs, or a per-file visual verification checklist.
   - **Why it may need human judgement:** For static design-system previews, visual rendering is the primary quality signal because the files do not participate in normal Phoenix test coverage. This should not block acceptance because the implementation workflow already proved plan conformance and the work is static-preview-only, but future DS iterations would benefit from persisted visual evidence when the plan explicitly calls for render verification.

## Suggested fixes

No required fixes for this iteration.

Optional follow-up:

- Add a concise `design-system/README.md` documenting:
  - previews are self-contained static HTML;
  - daisyUI CDN component/theme classes are allowed;
  - Tailwind utilities that require compilation/JIT are disallowed;
  - layout/responsive behaviour should use preview-local semantic CSS;
  - email previews should use email-safe markup/inline styles;
  - changed previews should be visually/render-verified before cloud DS push.

## Validation notes

- `dev ci` / `dev check` passed.
- Acceptance suite passed: **82 scenarios, 493 steps**.
- Sandbox runtime check passed before review.
- Evidence indicates no app code changed:
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
- Previously reported Tailwind-utility concerns appear unsupported by the repair/review evidence; the actual changed files live under `design-system/`, not stale `docs/design-system/` paths, and scans found no matching problematic `max-w-*` / `mx-auto` usage.