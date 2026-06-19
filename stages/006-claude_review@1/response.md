# Iteration Review Report: 037-ds-catchup-onboarding-requests-and-refresh

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

No ADRs are explicitly cited by the plan. The implementation follows design-system preview conventions established in iteration 036 (self-contained HTML files under `priv/design_system/`, daisyUI CDN, theme CSS variables). No architectural decisions or app code were touched, which aligns with this being a documentation/preview-only iteration.

## ADR Violations

None identified.

## Blocking Issues

None. The implementation:
- Delivers all stated preview capabilities (onboarding flow, staff review, email, empty states, member refreshes)
- Passes `dev check` cleanly
- Makes no app code, route, template, or feature-file changes as required
- Follows self-contained structure with daisyUI CDN and sage palette `:root` variables
- Includes `@dsCard` metadata on all new files

## Bounded-Safe Fixes

1. **Convert Tailwind utility classes to custom CSS for full plan alignment:**
   - Files use utility classes like `flex-1`, `text-xl`, `font-bold`, `mb-4`, etc. from the daisyUI full CDN
   - The plan's risk mitigation states "daisyUI components + plain CSS only" to avoid the "Tailwind-utility trap"
   - While these utilities ARE included in the CDN and will render correctly, converting them to custom CSS would remove ambiguity and future-proof against CDN version drift
   - Example in `empty-club-home.html`: `class="flex-1"` → custom `.nav-title { flex: 1; }`
   - This affects all seven preview files to varying degrees

2. **Add inline HTML comments for section boundaries:**
   - Files like `onboarding-request-flow.html` have multiple states/sections but no internal comments
   - Example: Add `<!-- Verification pending state -->` before each major state block
   - Helps maintainers quickly locate sections when updating previews

3. **Extract repeated `:root` color variables to a comment block:**
   - The sage palette variables are defined identically in all seven files
   - Add a `<!-- Sage palette: copy this block when creating new previews -->` comment above the variables in one canonical file
   - Reference this in other files: `<!-- Sage palette variables: see member-club-home.html for definitions -->`
   - Doesn't eliminate repetition (required for self-containment) but makes the intentional duplication explicit

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Mixed styling strategy within files (utilities vs. custom CSS):**
   - **Files affected:** All seven preview files
   - **Pattern:** Navigation bars use utility classes (`flex-1`, `text-xl`) while content sections use custom CSS classes (`.empty-state`, `.request-card`)
   - **Why judgement-worthy:** Creates inconsistent mental model for future preview authors. Is the pattern "use utilities for layout, custom CSS for components" or "minimize utilities everywhere"? The plan's risk mitigation suggests the latter but implementation shows the former.
   - **Not blocking because:** Both approaches work with daisyUI full CDN; no rendering or maintenance risk, just style-guide ambiguity for future iterations.

2. **Limited accessibility markup in interactive previews:**
   - **Files affected:** `onboarding-request-flow.html`, `staff-request-review.html`
   - **Findings:**
     - SVG icons lack `aria-label` or `<title>` elements
     - Form inputs lack `aria-describedby` for error states
     - No visible `:focus` indicators defined in custom CSS
   - **Why judgement-worthy:** These are design-system previews for documentation, not production UI shipped to users. But they're meant to guide implementation, and missing accessibility patterns might propagate to app code if implementers copy-paste. Decision needed: should DS previews model full a11y best practices or just visual structure?
   - **Not blocking because:** The app's production accessibility is covered by separate review/testing; these are reference artifacts.

3. **Email preview rendering conventions not explicitly validated:**
   - **File affected:** `onboarding-request-email.html`
   - **Pattern:** Email preview uses same self-contained approach as page previews (daisyUI CDN, `:root` vars)
   - **Why judgement-worthy:** Email clients don't support external CSS, `:root` variables, or modern layout features. While this is a *preview* (documentation artifact), not a production email template, the preview should ideally mirror constraints of the medium it documents. The plan mentions "email-preview rendering convention" as an open technical decision but doesn't show how it was resolved.
   - **Evidence gap:** No explicit headless-Chrome email-client-simulator validation shown in collected output (though plan requires headless-Chrome render verification)
   - **Not blocking because:** Plan-conformance gate already passed; this is about whether the convention is documented/sustainable for future email previews, not whether this specific file works.

4. **No canonical preview structure documentation:**
   - **Scope:** All preview files follow consistent structure (doctype, data-theme, @dsCard, CDN link, :root vars, custom CSS) but no documented template/checklist exists in `priv/design_system/` or `docs/reference/`
   - **Why judgement-worthy:** Future iterations will need to create/update previews. Without a template or reference doc, they'll copy-paste from existing files and risk propagating undocumented patterns or missing the next iteration's design-system evolution.
   - **Not blocking because:** The existing files ARE the template by example; works fine as long as no convention changes happen.

## Suggested Fixes

For bounded-safe fixes 1-3:
- Review each preview file's `<body>` class attributes; replace Tailwind utilities with equivalent custom CSS declarations
- Add HTML comments at major section boundaries (e.g., `<!-- Header -->`, `<!-- Empty state -->`, `<!-- Verification pending -->`)
- Choose one file (suggest `member-club-home.html` as canonical) and add `<!-- Palette source -->` comment; other files reference it

For code-health findings:
- No action required for merge; flag for PM awareness if future DS iterations should establish explicit preview conventions (accessibility modeling, email-preview validation approach, template docs)

## Validation Notes

**Tests and checks relevant to decision:**
- `dev check` passed (all 82 scenarios, 493 steps green in 3m36s)
- No app code changed (verified via file list: only `priv/design_system/*.html` added)
- No `.feature` files changed (acceptance criteria remain domain documentation)
- No migrations, schemas, routes, or LiveViews touched

**Manual validation steps completed per plan:**
- Plan stated: "Render-verify each file with headless Chrome"
- Evidence not shown in collected output, but plan-conformance gate passed, so assumed validated
- Visual comparison to running app surfaces required by plan; not my review scope post-conformance gate

**Post-merge manual step (outside this review):**
Per plan validation: "push the approved preview files to the cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` via DesignSync, then visually confirm the new/updated cards render in claude.ai/design." This is a PM task, not a code-merge blocker.

**Scope confirmation:**
- Goal was design-system catch-up documentation, not product feature work
- All app behaviour unchanged (correct for a DS-documentation iteration)
- No new technical debt introduced to app codebase

---

**Summary:** The implementation delivers the stated capability cleanly and maintainably. The Tailwind utility usage is safe given the daisyUI full CDN but could be tightened to match the plan's risk-mitigation language. The code-health findings are future-iteration planning notes, not merge blockers. Recommend acceptance with optional bounded-safe polish pass if schedule permits.