# Code Health

Judgement-worthy, non-blocking review findings that were intentionally allowed to merge. Clean reviews and silently auto-fixed issues are not recorded here.

## 2026-06-19 — Iteration 037: Design-system catch-up onboarding requests and refresh

Plan: `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/plan.md`

Note: the final review synthesis omitted the independent reviewers' code-health findings (the synthesis response contained only routing JSON). The findings below are recorded from the final Claude, Codex/GPT, and Gemini reviewer reports, excluding earlier synthesized blockers that were rejected as unsupported or non-blocking by the final review cycle.

1. **Static design-system preview class conventions remain implicit.**
   - Evidence: the new/changed `design-system/**/*.html` previews rely on a convention that daisyUI component/theme classes (for example `btn`, `card`, `badge`, `bg-base-100`, `shadow-xl`) are allowed, while Tailwind layout/spacing/sizing/typography/flex/grid utilities (for example `mx-auto`, `max-w-*`, `px-*`, `gap-*`, `text-sm`, `flex`, `grid`) are avoided because the previews load prebuilt daisyUI CSS rather than the compiled Tailwind bundle. This boundary is described in iteration/review context but is not durably documented in the `design-system/` directory.
   - Risk: future design-system contributors and reviewers may repeatedly debate safe class usage, produce false-positive review findings, or accidentally introduce Tailwind utility dependencies that silently fail in static previews.
   - Suggested next action: add a concise `design-system/README.md` or lightweight lint/check documenting that static previews use daisyUI CDN component/theme classes plus preview-local semantic CSS for layout, while Tailwind utilities requiring compilation/JIT are disallowed.

2. **Headless render-verification evidence is not visible in review artifacts.**
   - Evidence: the plan explicitly required headless-Chrome render verification for each new/changed preview, and the final review context shows successful `dev check` and plan-conformance evidence, but no screenshots, render logs, or per-file visual verification checklist were available in the collected review artifacts.
   - Risk: static design-system previews are primarily validated visually and receive little meaningful coverage from normal Phoenix tests, so visual regressions or broken static rendering can be hard to audit after merge.
   - Suggested next action: for future design-system preview iterations, persist render screenshots, render logs, or a short checked-off validation note when plans require browser/headless render verification.

## 2026-06-18 — Iteration 034: Member page design-system alignment

Plan: `docs/iterations/034-member-page-design-system-alignment/plan.md`

Note: the final review synthesis omitted the independent reviewers' code-health findings (the synthesis response contained only routing JSON). The findings below are recorded from the final Claude, Codex/GPT, and Gemini reviewer reports, excluding the source-scanning-test documentation issue that was fixed during the review run.

1. **Source-scanning design-system guardrail is intentionally brittle.**
   - Evidence: `web/test/memba_web/member_page_design_system_alignment_test.exs` uses source string/regex checks for hardcoded hex colours, legacy `--club-site-*` theming, legacy palette utilities, and required component call strings.
   - Risk: formatting changes, helper extraction, or semantically equivalent component usage can fail the test, while string presence does not prove correct variants, accessibility, or final rendered layout.
   - Suggested next action: keep the guardrail while it remains useful; if it becomes noisy or design-system governance grows, replace or supplement it with rendered assertions, HEEx/AST-aware checks, or visual-regression coverage.

2. **The member-page source list can drift as member surfaces grow.**
   - Evidence: `web/test/memba_web/member_page_design_system_alignment_test.exs` hardcodes `@member_page_files` instead of discovering member-facing templates/views by convention.
   - Risk: newly added member pages will not automatically inherit the no-hex/no-legacy-theme/shared-component checks unless the list is updated manually.
   - Suggested next action: leave the explicit list while the surface is small and reviewable; consider pattern-based discovery or a shared registration helper if member-facing pages expand.

3. **Member and staff delivery-status presentation mappings are intentionally separate.**
   - Evidence: member delivery styling is mapped in `web/lib/memba_web/member_email_delivery_presentation.ex`, while staff delivery/status styling remains separately mapped in staff views such as `web/lib/memba_web/live/admin/deliveries_live/index.ex` and `web/lib/memba_web/live/admin/messages_live/show.ex`.
   - Risk: the separation correctly prevents member colour changes from leaking into staff surfaces, but duplicated status/presentation shape can diverge if shared non-visual delivery semantics accumulate in multiple places.
   - Suggested next action: keep the separation for the current member-vs-staff palette boundary; revisit only if both paths start duplicating domain/status semantics rather than surface-specific presentation choices.

4. **Visual correctness is still process-sensitive for member UI alignment.**
   - Evidence: automated coverage includes source scans and rendered/behaviour tests, while the plan relies on `./bin/dev gallery-walk` for desktop/mobile visual review of spacing, hierarchy, responsiveness, and overall design-system feel.
   - Risk: visual regressions can pass structural and behavioural tests if gallery-walk review is skipped or not compared consistently.
   - Suggested next action: continue treating gallery-walk review as required for design-system polish; consider durable screenshot/visual-regression checks if member design-system migrations become frequent.

## 2026-06-19 — Iteration 036: Design-system catch-up: member management & auth check-email

Plan: `docs/iterations/036-ds-catchup-member-management-and-auth/plan.md`

Note: no reviewer-report or review-synthesis artifact files were visible in this checkout; the finding below is recorded from independent inspection of the merged iteration artifacts.

1. **The auth check-email preview path mapping drifted from the delivered file name.**
   - Evidence: `docs/iterations/036-ds-catchup-member-management-and-auth/preview-conventions.md` maps the auth preview as `design-system/wireframes/auth-check-email.html` → `wireframes/auth-check-email.html`, but the delivered preview file is `design-system/wireframes/check-email-delivery-progress.html` and labels itself as `repo: wireframes/check-email-delivery-progress.html`.
   - Risk: the manual post-merge DesignSync push can miss the auth preview or push it under an unexpected cloud path, leaving the cloud design system out of sync even though the repo artifact exists.
   - Suggested next action: reconcile the preview-conventions mapping with the shipped file name before the cloud DS push, and consider a small manifest/card-index check if future DS catch-up iterations add more repo-to-cloud preview paths.
