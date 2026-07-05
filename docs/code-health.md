# Code Health

Judgement-worthy, non-blocking review findings that were intentionally allowed to merge. Clean reviews and silently auto-fixed issues are not recorded here.

## 2026-07-05 — Iteration 044: Shared member app-shell: app-bar + app-card frame

Plan: `docs/iterations/044-shared-app-shell/plan.md`

Note: no reviewer-report or review-synthesis artifact files were visible in this checkout; the findings below are recorded from independent inspection of the merged iteration artifacts.

1. **The app-shell CSS source-of-truth is not durably reviewable against the design mirror.**
   - Evidence: the plan required porting `app-frame`, `app-card`, `app-bar`, `app-menu`, and `app-foot` CSS verbatim from `design-system/` (`memba.css` / `styles.css`) into `web/assets/css/app.css`, but this checkout has no tracked `design-system/styles.css` or `design-system/memba.css` source file. The shipped wireframes such as `design-system/wireframes/club-home.html` still link `../../styles.css`, while `web/test/memba_web/app_shell_css_test.exs` only asserts that selector names exist in `app.css`, not that the rules stay 1:1 with a design-system source.
   - Risk: future shell polish can drift between the Phoenix app and design mirror without an obvious diff or failing check, and reviewers cannot verify the intended "ported verbatim" contract from repository artifacts alone.
   - Suggested next action: establish a tracked app-shell CSS source/manifest for the design mirror or update the mirror conventions so the canonical shell rules are explicit, then add a lightweight comparison or checklist that verifies the Phoenix rules against that source when app-shell CSS changes.

2. **One `Layouts.club_site` render path remains a stale, unplumbed fallback.**
   - Evidence: `web/lib/memba_web/live/member_message_live/show.ex` still contains a fallback `render/1` clause that calls `<Layouts.club_site flash={@flash}>` without `club_name`, `current_identity`, or `member_name`, while the iteration updated the primary loaded message template (`web/lib/memba_web/controllers/page_html/message.html.heex`) and other signed-in surfaces to pass those assigns. `web/test/memba_web/club_site_shell_surfaces_test.exs` covers the loaded conversation view but not this fallback call site.
   - Risk: if that fallback is reachable through a future route/test/refactor, signed-in member chrome will render with the default "Club" label and no identity dropdown, and the stale path can keep drifting because the "every club_site surface" regression test does not enumerate every `Layouts.club_site` usage.
   - Suggested next action: decide whether the fallback render path is intentionally unreachable; if so, remove it or make it fail explicitly. If it should remain, plumb the same club/identity/member assigns through it and add a small regression check that every `Layouts.club_site` call site is either covered or documented as unreachable.

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
