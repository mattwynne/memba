# Code Health

Judgement-worthy, non-blocking review findings that were intentionally allowed to merge. Clean reviews and silently auto-fixed issues are not recorded here.

## 2026-07-05 — Iteration 044: Shared member app-shell: app-bar + app-card frame

Plan: `docs/iterations/044-shared-app-shell/plan.md`

Note: no reviewer-report or review-synthesis artifact files were visible in this checkout; the finding below is recorded from independent inspection of the merged iteration artifacts, excluding app-shell issues fixed by the review follow-up commit.

1. **The repo-root design-system app-shell stylesheet depends on tokens it does not define.**
   - Evidence: the shared static-preview source `styles.css` now defines `.app-frame`, `.app-card`, `.app-bar`, `.app-menu`, and `.app-foot` using variables such as `--color-sage-700`, `--color-sage-800`, `--color-paper`, `--color-ink`, `--color-line`, `--color-sage-50`, and `--color-sage-300`. Member-app previews such as `design-system/wireframes/club-home.html` and `design-system/wireframes/member-conversation.html` link `../../styles.css`, but their local `:root` blocks copy daisyUI tokens (`--color-base-*`, `--color-primary`, etc.) rather than the `--color-sage-*`/`--color-paper` tokens consumed by that stylesheet. The current `web/test/memba_web/app_shell_css_test.exs` sync check compares app-shell rules, but it does not prove the design-system preview pages define the variables required to render those rules.
   - Risk: static member-app previews can silently render the shared shell with missing backgrounds, text colours, borders, and accent states even while the Phoenix app and CSS sync test pass, making future visual review of the design mirror unreliable.
   - Suggested next action: add the required Memba design tokens to the repo-root `styles.css` or to each preview root block that links it, then add a lightweight static preview/token check or render checklist so shared design-system CSS changes cannot leave unresolved variables.

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

## 2026-06-21 — Iteration 038: Async email delivery dispatch

Plan: `docs/iterations/038-email-delivery-handoff-boundary/plan.md`

Note: no reviewer-report or review-synthesis artifact files were visible in this checkout; the finding below is recorded from independent inspection of the merged iteration artifacts.

1. **Projector replay can still nudge the supervised dispatcher if it is running.**
   - Evidence: `web/lib/memba/messaging/projectors/email_delivery.ex` publishes every committed `EmailDeliveryCreated` projection change from `after_update/3`, and `web/lib/memba/messaging/email_delivery_dispatcher.ex` subscribes to `Memba.ReadModelChanges.topic()` and dispatches pending deliveries for those events. The replay-safety test in `web/test/memba/messaging/send_club_message_test.exs` stops the supervised dispatcher in setup before rebuilding projections, so it proves projections themselves do not call the provider but does not cover a rebuild while the dispatcher is subscribed.
   - Risk: an operator/projector rebuild or replay performed with the dispatcher enabled could hand historical pending deliveries to the configured provider, resend email, or mutate rebuilt dispatch rows to `sent`/`failed`, violating the intended replay/side-effect boundary.
   - Suggested next action: add an explicit replay/maintenance suppression guard for dispatcher nudges (for example, ignore projection-rebuild metadata or require replay tooling to disable the dispatcher) and cover the running-dispatcher replay scenario with an automated test.

## 2026-06-21 — Iteration 039: Club message conversations and replies

Plan: `docs/iterations/039-club-message-threads-and-in-app-replies/plan.md`

Note: no reviewer-report or review-synthesis artifact files were visible in this checkout; the findings below are recorded from independent inspection of the merged iteration artifacts, excluding the conversation-reference centralization issue that was fixed during the review run.

1. **Dashboard message loading still treats replies as top-level club messages.**
   - Evidence: `web/lib/memba_web/member_dashboard_presentation.ex` loads dashboard messages through `Messaging.list_messages_for_club/1`, while `web/lib/memba/messaging.ex` filters that query only by `club_id` and orders all `messaging_messages` rows without excluding rows whose `reply_to_message_id` is set or grouping by `conversation_id`. The iteration plan says the message-detail screen becomes a conversation and the club-home row gains a reply-count signal, but no dashboard query/presentation path aggregates replies into the root conversation row.
   - Risk: member club home can show each reply as its own recent message row, duplicating subjects and competing with the intended single conversation entry; iteration 040 follower/reply-count work may have to unwind that presentation drift.
   - Suggested next action: decide whether member dashboards should list only root messages/conversations; if so, add a root-conversation query/presenter with reply counts and a regression test that posting a reply updates the root row instead of adding a second top-level row.

2. **The reply command boundary does not verify that `conversation_id` points at a root conversation.**
   - Evidence: `post_message_reply_command/1` in `web/lib/memba/messaging.ex` accepts any existing `MessageProjection` returned by `fetch_conversation_root/1`; that helper only casts the ID and calls `Repo.get(MessageProjection, conversation_id)`. Read APIs later assume a valid root shape (`fetch_conversation_root_projection/1` requires `message_id == conversation_id`), but `PostMessageReply` can be built against a reply projection if a caller supplies a reply message ID as the `conversation_id`.
   - Risk: future non-LiveView callers, especially iteration 041 inbound reply handling, could create orphaned or malformed reply chains whose projections cannot be loaded as a normal conversation, making delivery records and conversation UI inconsistent.
   - Suggested next action: enforce the root-conversation invariant at the application-service boundary (for example, require `message_id == conversation_id` and `reply_to_message_id == nil` in `fetch_conversation_root/1`) and add a regression test that posting with a reply message ID as `conversation_id` is rejected.
