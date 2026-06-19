# Iteration 037 Implementation Review

## Decision: ACCEPT

## Confidence: Medium-High

## ADR conformance: PASS

The implementation appears limited to static design-system HTML preview files under `docs/design-system/`. It does not touch domain modeling, Commanded/CQRS/event-sourcing infrastructure, projections, read models, Phoenix routes, LiveViews, templates, schemas, migrations, or acceptance feature files.

No ADR-governed architecture appears to be affected by this iteration.

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

   These previews reportedly still use Tailwind layout utilities such as:

   - `max-w-2xl`
   - `max-w-4xl`
   - `mx-auto`

   The iteration plan explicitly calls for self-contained previews using daisyUI prebuilt CSS plus app theme variables and plain CSS for layout, and warns against accidental Tailwind utility reliance.

   This is low-risk to fix without changing product behaviour: replace those utility classes with file-local CSS classes such as:

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

   Then update the affected markup to use those classes instead of `max-w-* mx-auto`.

   This keeps the same visual layout while better matching the preview convention and the plan’s Tailwind-utility avoidance requirement.

## Judgement-worthy non-blocking code-health findings

1. **Design-system preview class boundary is still implicit**

   Files:

   - New and refreshed `docs/design-system/**/*.html` previews

   Smell:

   The previews appear to intentionally use daisyUI component/theming classes such as `card`, `btn`, `bg-base-100`, and `shadow-xl`, while avoiding Tailwind layout/spacing utilities. That distinction is reasonable, but it is not especially obvious from the plan wording alone.

   Why it may need human judgement:

   The plan says “daisyUI components + plain CSS only” and “does not rely on Tailwind utility classes.” In practice, daisyUI examples often mix component classes with theme/helper classes that look utility-like. A short design-system convention note could prevent future reviewers and implementers from debating whether `bg-base-100` or `shadow-xl` are acceptable while `mx-auto` is not.

2. **Headless Chrome render verification evidence is not visible in the collected review context**

   Files:

   - All new/changed `docs/design-system/**/*.html` previews

   Smell:

   The plan specifically calls for headless-Chrome render verification of each new/changed preview. The collected evidence confirms `dev check` passed and the implementation was considered plan-conforming, but it does not show screenshot artifacts, a render log, or a checklist entry proving each preview was visually rendered.

   Why it may need human judgement:

   For static design-system HTML, visual/render verification is the meaningful feedback loop. If the team wants this to be auditable, future DS iterations may need to persist screenshots or a short verification note. I would not block this iteration on that absence because the implementation workflow already passed and app behaviour is unaffected.

## Suggested fixes

Apply the bounded-safe Tailwind utility cleanup:

1. Add local CSS centering/max-width classes to the three affected files.
2. Replace `max-w-2xl mx-auto` and `max-w-4xl mx-auto` with those local classes.
3. Re-run the same lightweight render check used during implementation if available.
4. Because this is a static-doc-only polish change, `dev check` is not strictly necessary under the project workflow unless the team chooses to rerun it.

## Validation notes

- `dev ci` / `dev check` passed successfully.
- Acceptance run passed: 82 scenarios, 493 steps.
- No app code, Phoenix routes, LiveViews, templates, schemas, migrations, contexts, background jobs, integrations, or `.feature` files appear to have changed.
- The implementation appears aligned with the iteration’s intended scope: static design-system previews for onboarding requests, request review/convert, related emails, empty states, and refreshed member previews.
- Remaining concerns are polish/convention issues in static preview markup, not behavioural or ADR-level defects.