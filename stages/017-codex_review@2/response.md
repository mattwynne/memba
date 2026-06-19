# Iteration Review Report: 037 — DS catch-up onboarding requests and refresh

## Decision: ACCEPT

## Confidence: Medium

## ADR conformance: PASS

No ADR-governed application architecture appears to be touched. The implementation scope is static design-system preview HTML under `priv/design_system/`, with no changes to domain modeling, Commanded aggregates, projections, event streams, Ecto schemas, Phoenix routes, LiveViews, runtime templates, migrations, or acceptance feature files.

The plan did not cite specific ADRs, and the touched scope does not implicate the domain/CQRS/event-sourcing/RDD ADR set.

## ADR violations

None.

## Blocking issues

None.

The previously synthesized Tailwind-utility concern is not strong enough to reject on the evidence available here. The plan-conformance gate had already passed, `dev check` passed, headless render verification was part of the implementation plan, and the repair attempt reported that the cited utility examples were not present in the changed previews. This leaves a convention-clarity smell rather than a demonstrated behavioural or plan-fidelity blocker.

## Bounded-safe fixes

1. **Document the static design-system preview convention**
   - **Files:** Prefer `priv/design_system/README.md`, or a short section in `docs/reference/frontend-design.md`.
   - **Fix:** Document the canonical static preview pattern:
     - self-contained HTML previews;
     - daisyUI CDN version/build;
     - `:root` theme-token duplication is intentional;
     - `@dsCard` metadata expectations;
     - relative asset path convention;
     - plain CSS vs. Tailwind utility policy.
   - **Why bounded-safe:** Documentation-only; no product behaviour or test changes.

2. **Add or verify local comments around duplicated token blocks**
   - **Files:** Changed preview files under `priv/design_system/wireframes/` and `priv/design_system/emails/`.
   - **Fix:** Add a concise comment above repeated `:root` theme variables explaining that duplication is intentional because cloud DS previews must be self-contained.
   - **Why bounded-safe:** Maintains the preview convention without altering rendered behaviour.

3. **Add or verify section comments in large multi-state previews**
   - **Files:** Especially `priv/design_system/wireframes/onboarding-request-flow.html` and `priv/design_system/wireframes/admin-request-review.html`.
   - **Fix:** Use lightweight comments such as `<!-- Request form state -->`, `<!-- Verification pending state -->`, and `<!-- Staff review / conversion state -->`.
   - **Why bounded-safe:** Improves maintainability of static previews without changing app behaviour.

## Judgement-worthy non-blocking code-health findings

1. **Static preview utility-class policy remains easy to misunderstand**
   - **Files:** `priv/design_system/**/*.html`
   - **Smell:** The plan explicitly says static previews should use daisyUI CDN plus app theme variables plus plain CSS, and should not rely on Tailwind utilities. Reviewers flagged possible utility-class usage, while repair evidence said the cited examples were not present.
   - **Why it may need human judgement:** The team should settle and document whether the CDN build intentionally includes Tailwind utilities but previews still avoid them by convention, or whether utilities are acceptable in DS previews. This is not blocking because no concrete broken render or plan violation is proven here.

2. **Email preview rendering convention is visual, not necessarily email-client-realistic**
   - **Files:** `priv/design_system/emails/new-request-notification.html` and related email previews.
   - **Smell:** Email previews appear to follow the same browser-oriented self-contained preview convention as page previews. Real email clients often strip external CSS, have limited CSS support, and do not reliably support modern layout/CSS-variable patterns.
   - **Why it may need human judgement:** This is acceptable if DS email previews are visual references only. If they are expected to seed production email implementation, the team should decide whether to model actual email constraints more closely.

3. **Design-system preview convention is not machine-enforced**
   - **Files:** `priv/design_system/**/*.html`
   - **Smell:** Important rules — self-contained head, daisyUI CDN, `@dsCard`, no bespoke shared CSS, correct relative assets, and no accidental forbidden utilities — rely on manual review.
   - **Why it may need human judgement:** As the DS grows, a lightweight validation script could prevent drift. Not necessary for this merge, but worth considering if more DS iterations are planned.

4. **Accessibility depth for static previews is not standardized**
   - **Files:** Form-like and interactive-looking previews such as `priv/design_system/wireframes/onboarding-request-flow.html` and `priv/design_system/wireframes/admin-request-review.html`.
   - **Smell:** Static previews can easily omit production-grade accessibility details such as complete error associations, icon labelling, and focus-state modelling.
   - **Why it may need human judgement:** These are documentation artifacts, not shipped UI. However, if future implementation work copies from them, the team may want a baseline a11y standard for DS HTML.

## Suggested fixes

Before or after merge, apply a documentation-only polish pass:

1. Add `priv/design_system/README.md` describing the preview convention.
2. Explicitly state the daisyUI CDN build/version and whether Tailwind utility classes are allowed or forbidden.
3. Explain that repeated `:root` token blocks are intentional for self-contained cloud DS previews.
4. Add lightweight section comments to the larger multi-state preview files if they are not already present.
5. Consider a future small validation script for DS previews, but do not block this iteration on it.

## Validation notes

- `dev check` / `dev ci` passed successfully.
- Acceptance output shows **82 scenarios passed** and **493 steps passed**.
- Scope appears limited to static design-system preview files under `priv/design_system/`.
- No app code, routes, LiveViews, schemas, migrations, or `.feature` files appear to have changed.
- The plan’s post-merge DesignSync push to cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` remains a manual PM step and is not a code-review blocker.
- The failed `verify_review_repair` stage indicates the attempted repair produced no working-tree diff, not that app validation failed. Given the implementation already passed plan conformance and `dev check`, this is best treated as convention/documentation follow-up rather than a merge blocker.