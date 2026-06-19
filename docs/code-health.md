# Code Health

Judgement-worthy, non-blocking review findings that were intentionally allowed to merge. Clean reviews and silently auto-fixed issues are not recorded here.

## 2026-06-19 — Iteration 036: DS catch-up member management and auth

Plan: `docs/iterations/036-ds-catchup-member-management-and-auth/plan.md`

Note: substantive reviewer report/synthesis artifacts for this run were not present in the worktree; these findings are recorded from inspection of the merged iteration files.

1. **Auth check-email preview path mapping is inconsistent.**
   - Evidence: `docs/iterations/036-ds-catchup-member-management-and-auth/preview-conventions.md` maps the auth preview as `design-system/wireframes/auth-check-email.html` → `wireframes/auth-check-email.html`, while the implemented file is `design-system/wireframes/check-email-delivery-progress.html` and the preview itself labels the repo path as `wireframes/check-email-delivery-progress.html`.
   - Risk: the manual DesignSync push can look for or create the wrong cloud file, leaving the intended auth delivery-progress preview unpublished or duplicated under two names.
   - Suggested next action: choose the canonical cloud path before the PM push, then either update the mapping to `check-email-delivery-progress.html` or rename the repo file to `auth-check-email.html` so the repo mirror and cloud target agree.

2. **Static DS preview theme/CSS scaffolding is now duplicated across the new preview files.**
   - Evidence: `design-system/wireframes/invite-a-member.html`, `design-system/wireframes/profile-completion.html`, `design-system/wireframes/check-email-delivery-progress.html`, and `design-system/components/badges/badges.card.html` each carry a full copied daisyUI CDN head, Memba raw token block, and light-theme `:root` variables, with the same shape also documented in `preview-conventions.md`.
   - Risk: future app-theme or token changes require manual edits in several static files; if one file is missed, the cloud design system can drift from the running app even though each preview remains self-contained and renderable.
   - Suggested next action: keep the self-contained files for the current DesignSync workflow, but if more DS catch-up previews are added, introduce a small generator/shared source for the repeated head/token block or a lightweight verification check against `web/assets/css/app.css` before pushing to the cloud DS.

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
