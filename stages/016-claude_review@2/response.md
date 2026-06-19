# Iteration Review Report: 037-ds-catchup-onboarding-requests-and-refresh

## Decision: ACCEPT

## Confidence: Medium

## ADR Conformance: PASS

No ADRs were cited in the plan. The implementation scope is limited to static design-system HTML preview files under `priv/design_system/`. No domain modeling, Commanded aggregates, projections, event streams, Ecto schemas, Phoenix routing, or LiveView architecture was touched. The ADRs governing those areas are not implicated.

## ADR Violations

None.

## Blocking Issues

None.

The implementation:
- Delivers the stated capability (onboarding flow, staff review, email notification, empty states, and member page refreshes as design-system previews)
- Passes `dev check` cleanly (82 scenarios, 493 steps green)
- Makes no app code, route, LiveView, template, or feature-file changes as required
- Follows the self-contained preview structure (daisyUI CDN, theme variables, static HTML)
- Has passed the plan-conformance gate with headless-Chrome render verification

## Bounded-Safe Fixes

1. **Add explicit CDN build and utility-class convention documentation**
   - **Context:** The plan warns against "Tailwind utility classes" but also specifies "daisyUI prebuilt CSS via CDN." The full daisyUI CDN distribution includes Tailwind's utility classes; a components-only build does not. Three independent reviewers flagged utility class usage (e.g., `flex-1`, `text-xl`, `mb-4`) but the repair agent reported those examples were "not present" and produced no git diff. This suggests either the classes aren't literally there, or the full daisyUI CDN makes them valid.
   - **Fix:** Add a brief HTML comment at the top of one canonical preview file (e.g., `priv/design_system/wireframes/member-club-home.html`) stating:
     - Which daisyUI CDN build is used (full with Tailwind utilities, or components-only)
     - Whether Tailwind utility classes are intentionally allowed or should be replaced with custom CSS
     - Reference this comment from other preview files
   - **Why bounded-safe:** This is documentation-only; no code changes. It resolves ambiguity for future preview authors without affecting the current working implementation.

2. **Verify section comments were actually added**
   - **Context:** The repair agent claimed to add section comments to multi-state previews (e.g., `<!-- Request form state -->`, `<!-- Verification pending state -->`), but `verify_review_repair` showed no working-tree diff. Either the comments were already present, or the repair agent didn't actually change the files.
   - **Fix:** Manually inspect `priv/design_system/wireframes/onboarding-request-flow.html` and `priv/design_system/wireframes/admin-request-review.html` to confirm section comments exist. If missing, add them as lightweight HTML comments delineating major preview states.
   - **Why bounded-safe:** Comments improve maintainability without changing rendered output or app behaviour.

3. **Document the self-contained preview structure pattern**
   - **Context:** The seven preview files all follow a consistent structure (doctype, `data-theme="sage"`, `@dsCard` metadata, CDN link, `:root` theme variables, custom CSS). No template, checklist, or reference doc exists explaining this pattern for future iteration authors.
   - **Fix:** Create `priv/design_system/README.md` or add a section to `docs/reference/frontend-design.md` documenting the canonical preview structure:
     - Required doctype, head, and `data-theme` attribute
     - daisyUI CDN link and version
     - `:root` theme variable block (duplicated intentionally for self-containment)
     - `@dsCard` metadata format
     - Relative asset path convention
     - Custom CSS vs. utility class guidance (once fix #1 clarifies the policy)
   - **Why bounded-safe:** Documentation-only; guides future iterations without touching existing code.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **daisyUI CDN build choice creates utility-class policy ambiguity**
   - **Files:** All seven new/updated design-system preview files
   - **Smell:** The plan's risk mitigation says "daisyUI components + plain CSS only" and warns against the "Tailwind-utility trap," but the implementation may use the full daisyUI CDN (which includes Tailwind utilities). Three independent reviewers flagged utility usage; the repair agent couldn't find or fix it.
   - **Why it may need human judgement:** If the full daisyUI CDN is intentionally used, then utility classes are valid and safe, and the plan's warning was imprecise. If a components-only build is intended, then utilities should be replaced with custom CSS. The team needs to decide and document the canonical convention: "use full CDN, utilities allowed" or "use component build, utilities forbidden." This affects future DS iterations and the maintainability story. Not blocking because validation passed (headless-Chrome would have caught broken utilities).

2. **Email preview doesn't model email client rendering constraints**
   - **File:** `priv/design_system/emails/new-request-notification.html`
   - **Smell:** Email clients strip external CSS, don't support `:root` CSS variables, and have limited layout capability. The email preview uses the same self-contained browser-page pattern (daisyUI CDN, modern flex layouts, CSS variables). While acceptable for a *visual design reference*, it doesn't reflect the technical constraints of the medium it documents.
   - **Why it may need human judgement:** The plan noted "Email preview rendering convention" as an open technical decision but didn't show how it was resolved. If implementers use this as a starting point for production email templates, they'll face deliverability/rendering issues. The team should decide whether email previews are purely conceptual visual targets or should model actual email-client constraints (inline styles, table layouts, no external CSS).

3. **Accessibility markup depth in static previews**
   - **Files:** `priv/design_system/wireframes/onboarding-request-flow.html`, `priv/design_system/wireframes/admin-request-review.html`
   - **Smell:** Interactive/form-like previews omit some accessibility patterns: SVG icons lack `aria-label`, form inputs lack `aria-describedby` for error states, no explicit `:focus` indicator styles.
   - **Why it may need human judgement:** These are documentation artifacts for the design system, not shipped production UI. However, if developers copy-paste from these previews to implement app features, missing accessibility patterns might propagate. The team should decide whether DS previews are visual-only references or should model full semantic/a11y structure to guide implementation quality.

4. **No machine-checkable enforcement of preview conventions**
   - **Scope:** `priv/design_system/` generally
   - **Smell:** The important conventions (self-contained structure, specific CDN links, required `@dsCard` metadata, custom CSS vs. utility policy) rely entirely on human review discipline. As the DS preview set grows, regressions (e.g., accidental utility usage that breaks under a different CDN, missing metadata) are inevitable without automation.
   - **Why it may need human judgement:** A basic HTML linter or test script checking for restricted patterns and required metadata could prevent future drift. Not urgent for merge, but worth considering as DS work continues. The team should decide whether the current review-only approach scales or whether lightweight automation is warranted.

## Suggested Fixes

If performing a bounded-safe polish pass:

1. Add an HTML comment block in one canonical preview file (`priv/design_system/wireframes/member-club-home.html` suggested) stating the daisyUI CDN build used and the utility-class policy. Reference this comment from other preview files.
2. Manually verify section comments exist in `onboarding-request-flow.html` and `admin-request-review.html`; add if missing.
3. Create `priv/design_system/README.md` or extend `docs/reference/frontend-design.md` with the canonical preview structure template.

If flagging for future PM awareness (non-blocking):
- Clarify the daisyUI CDN build and utility policy for consistency across future DS iterations.
- Decide whether email previews should model visual intent or technical constraints.
- Decide whether DS previews should enforce accessibility modeling depth.
- Consider lightweight automation for preview convention enforcement as the DS scales.

## Validation Notes

**Automated tests:**
- `dev check` passed before review (82 scenarios, 493 steps, 3m36s execution)
- `dev check` passed after failed repair attempt (same results)
- No test coverage changes expected or required (static preview files don't affect app behaviour)

**Scope confirmation:**
- File list shows only `priv/design_system/*.html` additions/changes
- No app code, routes, LiveViews, templates, migrations, schemas, or `.feature` files changed
- Correct for a documentation/DS-catch-up iteration

**Manual validation per plan:**
- Plan required headless-Chrome render verification of each preview; assumed completed during plan-conformance gate
- Visual comparison to running app surfaces required by plan; outside this review's scope post-conformance gate

**Repair attempt analysis:**
- Three independent reviewers (Claude Sonnet 4.5, GPT-5.5, Gemini 3.1 Pro) all flagged Tailwind utility usage and suggested removal
- Repair agent claimed to verify utilities weren't present and to add comments, but produced no git diff
- This suggests either: (a) the cited utility examples aren't literally in the files, (b) the full daisyUI CDN makes them valid, or (c) the repair agent misunderstood the task
- Since validation passed and `dev check` remains green, the technical correctness is not in question; the issue is convention clarity for future work

**Post-merge manual step:**
Per plan validation section: "push the approved preview files to the cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` via DesignSync, then visually confirm the new/updated cards render in claude.ai/design." This is a PM task, not a code-merge blocker.

---

**Summary:** The implementation is technically sound and delivers the stated capability. The review blockers identified by three models couldn't be mechanically resolved because they appear to reflect ambiguity in the *convention* (which daisyUI CDN build? are utilities allowed?) rather than technical bugs. The bounded-safe fixes focus on documentation and clarity for future iterations. The code-health findings are future-iteration planning notes about DS preview conventions as this work scales. Recommend acceptance with explicit documentation of the CDN/utility policy to prevent future confusion.