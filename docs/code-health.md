# Code Health

Judgement-worthy, non-blocking review findings that were intentionally allowed to merge. Clean reviews and silently auto-fixed issues are not recorded here.

## 2026-07-09 — Design gap pass: club-home and conversation templates don't reuse the design system's own CSS classes

Plan: `docs/design-gaps-2026-07-09.md` (gap #5); fixed content-wise by [iteration 050](iterations/050-club-home-conversation-and-member-row-fidelity/plan.md), but the underlying class-reuse gap itself was intentionally left open.

Note: comparing the shipped app against the design system's own CSS found a systemic, one-directional pattern rather than a single bug. `web/assets/css/app.css` already carries faithful, exact-name ports of several design-system component classes — `.app-frame`, `.app-card`, `.app-bar*`, `.section-tab*`, `.member-row*`, `.detail-head*`, `.follow-toggle*`, and the full `.delivery-*` family — and those surfaces (top shell, tabs, member list, follow toggle, delivery details) match the design closely as a direct result.

1. **Club-home conversation rows and the conversation/message page don't use the matching design-system classes at all.**
   - Evidence: the design system defines `.conversation` / `.conversation__*` / `.avatar-stack` (club-home conversation rows) and `.message` / `.message__*` / `.composer*` / `.page-title` (the conversation page and its composer) in `memba.css`. None of these class names exist anywhere in `web/assets/css/app.css`. `web/lib/memba_web/controllers/page_html/club.html.heex`'s conversation list and `message.html.heex` are hand-rolled with Tailwind utility classes directly in the `.heex` templates instead.
   - Risk: this is why the two most visible fidelity gaps in the 2026-07-09 pass existed in the first place (an oversized hero-scale subject heading, and no structural home for the message preview/avatar-stack) — without the shared classes, there's no natural place for those elements to slot into. It also means future spacing/color/typography tweaks to `.message`/`.conversation` in the design system won't propagate to the app; these two surfaces are the most likely to silently drift again.
   - Suggested next action: port `.conversation`/`.conversation__*`/`.avatar-stack` and `.message`/`.message__*`/`.composer*`/`.page-title` into `app.css` (mechanical, same pattern already used for `.member-row*`/`.follow-toggle*`), then rewrite the club-home conversation list and the conversation page to use them instead of ad hoc Tailwind. Iteration 050 fixed the visible symptoms (oversized title, stray badge/meta line, missing headings) directly in the existing Tailwind markup rather than doing this port, so the underlying gap remains; the conversation-participant avatar-stack work (next iteration) is a natural place to do it, since it touches the same templates and needs `.avatar-stack`/`.conversation__participants` either way.

## 2026-07-07 — ADR 0023 architectural review: URL-addressable LiveView state

ADRs: `docs/adr/0015-use-liveview-for-member-application-pages.md`, `docs/adr/0023-use-url-addressable-liveview-state.md`

Note: after iteration 045 changed the club-home Conversations/Members tabs to LiveView patch routes (`/conversations` and `/members`), an ensemble architectural review checked whether the rest of the codebase follows ADR 0015 and ADR 0023. Codex and Gemini completed independent reports and both returned **PASS WITH FINDINGS**. Claude could not run because the Anthropic API key was unavailable. The findings below record agreed or high-signal follow-ups; transient menus, dropdowns, and form validation feedback are not treated as ADR 0023 violations.

1. **Member message receipt-group expansion is visible state that is not URL-addressable.**
   - Evidence: `web/lib/memba_web/live/member_message_live/show.ex` stores `:expanded_receipt_groups` in LiveView assigns and toggles it through `handle_event("toggle_receipt_group", ...)`; `web/lib/memba_web/controllers/page_html/message.html.heex` renders receipt-group controls with `phx-click="toggle_receipt_group"`, `aria-expanded`, and conditional recipient rows; `web/test/memba_web/live/member_message_live/show_test.exs` expands groups with `render_click()` rather than asserting a patch URL.
   - Risk: a member can reveal a delivery-status group, but refresh, share, and browser Back/Forward lose that visible state. This conflicts with ADR 0023's rule that expandable modes users may expect to bookmark, share, refresh, or navigate back to should be represented in the URL where practical.
   - Suggested next action: add `handle_params/3` to `MemberMessageLive.Show`, encode expanded receipt groups in query params (for example `?receipts=delivered,sent` or `?receipt_group=delivered`), replace the toggle event with LiveView patch links or `push_patch/2`, and add tests for direct URLs, refresh-equivalent render state, and `assert_patch`.

2. **Club invitation profile completion remains a controller-rendered interactive member-facing form.**
   - Evidence: `web/lib/memba_web/controllers/club_member_invitation_controller.ex` renders and submits the invited-member profile completion flow through controller actions; the route remains outside the club-member LiveView session.
   - Risk: the flow is identity/member-facing and form-based, so it may drift from ADR 0015's default that member application pages should be LiveViews. The current controller may be acceptable as a pre-member invitation boundary, but that exception is not explicit.
   - Suggested next action: either document this as a deliberate pre-member/controller exception, or migrate the profile completion flow to LiveView before adding richer interaction or validation.

3. **The public get-started request flow is an interactive controller flow.**
   - Evidence: `web/lib/memba_web/controllers/page_controller.ex` handles `get_started/2`, `submit_get_started/2`, signed-out verification, and signed-in request submission as controller actions.
   - Risk: this is not an authenticated club-member app page, so ADR 0015 applies less directly than it does to club-member surfaces. Still, it is a multi-step user-facing form with visible states, and it may become a source of controller/LiveView inconsistency as onboarding grows.
   - Suggested next action: consider a later LiveView migration for the get-started flow if it gains more interactive state; otherwise document it as a public onboarding exception to the member-app LiveView default.

4. **Compose success state may deserve a URL-backed destination.**
   - Evidence: `web/lib/memba_web/live/member_message_live/new.ex` keeps `:compose_state`, `:sent_message_id`, and failure/success feedback in assigns at `/messages/new` after submit.
   - Risk: post-submit success is visible and useful, but refresh loses it. This is probably transient form feedback, not a strict ADR 0023 violation, yet it sits near the boundary because the success state names a durable message.
   - Suggested next action: decide whether successful compose should navigate to `/messages/:message_id` after send. Leave validation errors and retryable failure feedback as transient form state unless users need share/refresh semantics.

5. **Admin request rejection state is server-only while conversion state is URL-backed.**
   - Evidence: `web/lib/memba_web/live/admin/requests_live/index.ex` uses URL-backed patch state for request conversion but uses `phx-click` / assigns for starting and cancelling rejection.
   - Risk: ADR 0023 is focused on member application pages, so this is not a member-surface violation. However, the same principle would make staff workflows more refresh-safe and testable if rejection panels become meaningful page modes.
   - Suggested next action: leave as-is unless staff operators need Back/Forward/share semantics for rejection state; if they do, align rejection with the existing conversion patch pattern.

## 2026-07-07 — Iteration 047: Conversation delivery details

Plan: `docs/iterations/047-conversation-delivery-details/plan.md`

Note: no durable reviewer-report or synthesis artifact files were visible in this checkout. The finding below is recorded from independent inspection of the merged iteration artifacts. The previous ADR 0023 review recorded the old inline message-page receipt-group expansion; iteration 047 removed that surface, but the new delivery details page still has expandable delivery groups.

1. **Delivery-details receipt-group expansion is still client-local rather than URL-addressable.**
   - Evidence: `web/lib/memba_web/live/member_message_delivery_live/show.ex` renders each delivery status group as native `<details>` with its initial `open` state from `delivery_group_open?/1`; there is no `handle_params/3`, patch link, or `push_patch/2` state for an opened delivered/sending group. `web/test/memba_web/live/member_message_delivery_live/show_test.exs` asserts only the default expanded/collapsed state (`delivery problem` open, `delivered` collapsed) and has no direct-URL or patch assertions for expanded groups.
   - Risk: a member can expand a delivery group to inspect recipients, but refresh, sharing/bookmarking, and browser Back/Forward lose that visible state. This preserves the current page-mode gap against ADR 0023's guidance for expandable member-app modes where URL state is practical.
   - Suggested next action: decide whether delivery-group expansion should be treated as durable page state. If yes, model expanded status groups in query params (for example `?groups=delivered,sent`) via `handle_params/3` and LiveView patch transitions, then add tests for direct URLs and patch/back-forward behaviour; if not, document the delivery details accordions as a deliberate transient exception.

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

## 2026-09-04 — Iteration 056: Group audience foundation

Plan: `docs/iterations/056-group-audience-foundation/plan.md`

Note: the final review synthesis omitted the independent reviewers' code-health findings (the synthesis response contained only routing JSON). The findings below consolidate the supported, overlapping findings from the Sol, Claude, and Gemini reports. Claude's review-evidence visibility note was process-only rather than an implementation code-health finding. Its conditional legacy-audience-path concern was also not recorded: direct inspection confirmed that root-message recipient resolution, inbound sender authorisation, reply authorisation, and member compose access use the new group APIs; follower-only reply delivery intentionally remains on the existing active-club-member path.

1. **The event-sourced replay test harness has a hand-maintained subscriber manifest coupled to supervision and Commanded internals.**
   - Evidence: `web/test/support/event_sourced_case.ex` separately enumerates `@projectors`, `@event_handlers`, and `@commanded_apps`, inspects `Memba.Supervisor` children to terminate and restart matching workers, constructs Commanded aggregate-supervisor names, resets Commanded subscription acknowledgements, and deletes EventStore subscriptions by inspected module name. `web/lib/memba/application.ex` maintains a separate list of the supervised projectors and policy.
   - Risk: a new subscriber can be added to the application but omitted from the test manifest, making reset/replay tests incomplete or leaving a live subscriber racing a rebuild. Changes to Commanded names or supervision structure can also break the helper even when application behaviour is otherwise valid.
   - Suggested next action: introduce one discoverable subscriber registry or explicit projection-reset contract shared by application supervision and replay support. As a smaller guardrail, add a test that the replay manifest covers every supervised event-sourced subscriber.

2. **System-group convergence depends on a durable idempotency contract shared across two independently invoked fact-producing paths.**
   - Evidence: `web/lib/memba/membership/policies/system_group_membership.ex` replays lifecycle events from `:origin` and dispatches group-membership commands, while `web/lib/memba/membership/system_groups/backfill.ex` independently dispatches missing system-group and membership facts for historic data. Duplicate safety lives in the Club and Message aggregate decisions, which return no events when the requested fact is already satisfied. Current redelivery, rerun, and interrupted-backfill tests prove that contract.
   - Risk: a future change to policy subscriptions, backfill queries, or aggregate no-op decisions could make redelivery append duplicate events or allow the live policy and release backfill to diverge. The existing correctness guarantee crosses several modules rather than being local to either producer.
   - Suggested next action: treat aggregate no-op semantics as a named compatibility contract when these commands evolve. Preserve the existing duplicate-delivery and interrupted-backfill tests, and consider extracting a reusable idempotency contract test before adding custom groups or another producer.

3. **The event-sourced backfill is operationally coupled to the synchronous release migration lifecycle.**
   - Evidence: `web/lib/memba/release.ex` starts the application, waits on an explicit source-projector list, and runs `Memba.Membership.SystemGroups.Backfill.run!/0` before release migration can finish. The backfill pages current projections, dispatches commands phase by phase, keeps cursors only in process memory, and restarts from the first phase after a failure while relying on idempotency. It logs phase/page counts, and tests cover ordering, failure propagation, retry, and duplicate safety.
   - Risk: deployment completion now depends on projector catch-up and the duration of a synchronous application-level backfill. As data volume grows, or if future backfills use independently shaped barriers and retry behaviour, release failures and operational diagnosis can become harder.
   - Suggested next action: before introducing another event-sourced release backfill, define a reusable release-backfill runner or operational convention covering projector barriers, phase progress/telemetry, retry semantics, and timeout expectations, while continuing to create domain facts through aggregate commands.

## 2026-09-05 — Iteration 057: Admin group email conversations

Plan: `docs/iterations/057-admin-group-email-conversations/plan.md`

Note: no durable substantive reviewer-report or review-synthesis bodies were visible in
this checkout; the review checkpoint commits are metadata-only. The findings below
consolidate supported independent inspection of the final merged state. They exclude
the vision-policy alignment, test-pool rationale, and direct-projection fixture
documentation issues fixed during this review run.

1. **Email dispatch reconstructs an immutable originating audience from mutable access grants.**
   - Evidence: `web/lib/memba/messaging/message.ex` emits `MessageSent`, a separate `ConversationAccessGrantedToGroup`, and delivery events for a root message, but neither `web/lib/memba/messaging/events/message_sent.ex` nor `web/lib/memba/messaging/projections/message.ex` retains `audience_group_id`. `web/lib/memba/messaging/email_delivery_dispatcher.ex` later queries the conversation's access rows, sorts by opaque group ID, and takes the first grant. `web/lib/memba/messaging/member_message_email.ex` uses that inferred value to decide whether a root email's From identity is the member sender or the club group.
   - Risk: separate projectors can make a delivery visible before its access grant is visible, and future shared conversations can have several grants. In either case, presentation identity can depend on projection timing or UUID order rather than the audience that originated the conversation, potentially exposing a private-group sender's identity or producing inconsistent email branding.
   - Suggested next action: decide where the immutable originating audience belongs, preferably as an event fact projected with the message or delivery, and build provider requests from that fact. Include an explicit compatibility rule for historic `MessageSent` events.

2. **Sender-follow policy is coupled to root-email recipient selection.**
   - Evidence: `web/lib/memba/messaging/events/message_sent.ex` now carries `sender_follows_conversation`, but `web/lib/memba/messaging/message.ex` derives it solely by checking whether the sender appears in the resolved delivery recipients. `docs/problems/2026-09-03-sender-receives-own-group-email.md` already proposes suppressing a group-member sender's redundant root delivery.
   - Risk: delivery eligibility and follow intent coincide in iteration 057 but are separate decisions. Implementing the deferred own-copy suppression by removing the sender from recipients would also silently stop an Admin sender following the conversation and receiving later follower-only replies.
   - Suggested next action: before suppressing sender copies, make the follow decision explicit at the posting-policy/application-service boundary, or emit an explicit follow fact, so recipient filtering can evolve independently.

3. **The generalized send boundary does not enforce the club-scoped group invariant.**
   - Evidence: `send_club_message/2` in `web/lib/memba/messaging.ex` accepts `club_id` and `audience_group_id` independently and resolves recipients through `Membership.list_active_members_of_group/1`, which receives only the group ID. `web/lib/memba/messaging/message.ex` validates the two IDs' shapes but can emit a conversation-access grant combining the supplied club with an unrelated club's group. Current inbound routing is safe because `InboundClubDestination` resolves the group under the destination club, but that relationship is not part of the public send contract.
   - Risk: a future caller can accidentally create club-A-branded content delivered to club B's group members, with an incoherent cross-club access grant that reply authorization subsequently trusts.
   - Suggested next action: add a Membership public query that resolves recipients by both club and group, or expose a plain group summary whose `club_id` Messaging verifies. Fail closed on a mismatch before constructing `SendMessage`, and add a cross-club regression test.

4. **Admin reply emails advertise a web destination that is intentionally inaccessible.**
   - Evidence: `web/lib/memba/messaging/email_delivery_dispatcher.ex` adds a `/messages/:conversation_id` URL to every reply delivery, and `web/lib/memba/messaging/member_message_email.ex` renders it as a "View the conversation" action. `web/lib/memba_web/member_message_detail.ex` authorizes message detail only through Everyone, and `web/test/memba_web/controllers/member_message_detail_test.exs` explicitly proves that an Admin-only conversation URL returns 404.
   - Risk: Admin recipients receive a prominent dead link in otherwise valid reply notifications throughout the email-only phase. Removing it, adding a private-group web view, or replacing it with different guidance crosses the iteration's deliberate no-Admin-web-UI boundary.
   - Suggested next action: make an explicit product/presentation decision for email-only groups. The smallest follow-up is to omit the conversation URL for replies whose originating audience is not Everyone until a group-authorized web detail view exists.

5. **`CreateGroup` also serves as an implicit historical slug-repair command.**
   - Evidence: `web/lib/memba/membership/commands/create_group.ex` describes `email_slug` as optional and does not enforce it, while `web/lib/memba/membership/club.ex` rejects every genuinely new group without a slug. For an existing matching group, the same `CreateGroup` command can emit only `GroupEmailSlugAssigned`; `web/lib/memba/membership/system_groups/backfill.ex` relies on that dual behavior despite the dedicated `AssignGroupEmailSlug` command. The source query in `web/lib/memba/membership.ex` groups missing rows, unassigned slugs, and conflicting non-null slugs under one inequality check.
   - Risk: the command name and shape do not communicate all of its behavior, and future authorization, telemetry, custom-group, or idempotency changes must preserve the non-obvious fact that a creation command may instead repair an existing aggregate.
   - Suggested next action: classify backfill entries as missing group, unassigned slug, or conflicting immutable slug; dispatch `CreateGroup` only for missing groups and `AssignGroupEmailSlug` only for existing groups without the fact, while failing explicitly on conflicts. Then make `email_slug` required by `CreateGroup`. If convergence is intentionally one operation, model it as an explicitly named private command such as `EnsureSystemGroupDefinition`.
