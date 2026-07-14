# Architectural review — 2026-07-14

A comprehensive review of the Memba codebase against its own ADRs (docs/adr/) and long-term goals, conducted overnight 2026-07-13/14. Method: six parallel deep-dive investigations (domain/CQRS layer, web layer, test architecture, ops/config/security, verification of every docs/code-health.md item, cross-cutting quality), each producing evidence-backed findings that were then cross-checked and synthesized. Where scouts disagreed (e.g. Postmark webhook auth), the code was re-read directly to resolve the conflict.

Companion slide deck: published as an Artifact ("Memba architecture review").

---

## Overall evaluation

**This is a healthy, unusually disciplined codebase.** The ADRs are real (every claim spot-checked matched the code), the write model genuinely enforces invariants, the web layer respects context boundaries almost perfectly, quality gates are strict (`compile --warnings-as-errors`, format, unused-deps all clean; zero TODO/FIXME markers in `lib/`), and the shared Cucumber feature files actually run at two layers (~97 of 122 scenarios) rather than aspirationally. The release process (ADR 0017 schema-drift verification wired into the deploy path) and the token/auth crypto are better than most production systems.

**The central tension:** the care is unevenly distributed. The interior of the system (aggregates, projections, release path, tokens) is built like it will last decades, while the HTTP boundary (webhooks, rate limiting) and production operability (health checks, error tracking) are built like a prototype. Both Postmark webhook endpoints are completely unauthenticated; there is no rate limiting anywhere; production has no health check, no error tracker, and no metrics sink. None of these is hard to fix, and the codebase's own kaizen log flagged the webhook gap in June.

**The second theme:** long-horizon event-sourcing practices haven't been established yet. There is no event versioning/upcasting strategy (schema evolution is handled by shims scattered through aggregates and projectors), domain events carry no business timestamps (so "member since" is projection-commit time — already known to be wrong for the planned club-history imports), and the email-delivery table is a projection/operational-state hybrid whose naive rebuild would re-send historical email. These don't hurt today; they compound with every event written.

**Maintainability grade: strong (B+/A-).** The structure, documentation, boundary discipline, and test coverage put this well above typical for its age. The prioritized list below is mostly about closing the gap between the weakest parts and the (very high) standard the rest of the code sets, before real clubs and real data arrive.

---

## What's genuinely good (calibration)

- **ADR discipline is real.** 23 ADRs, and every implementation claim checked (0003, 0009, 0010, 0013, 0017, 0020, 0021, 0022) matched code. ADR 0021's `after_update/3` publish pattern is implemented in **all 11 projectors** without exception.
- **Release-state verification (ADR 0017)** — `Memba.Release.verify_repo_schema!` compares live `information_schema` against Ecto schemas and fails the deploy on drift (`web/lib/memba/release.ex:24-133`). Rarely seen; excellent.
- **Token security**: 32-byte `strong_rand_bytes`, SHA-256-only storage, 15-min TTLs, single-use via `SELECT … FOR UPDATE` (`accounts.ex:141-152`); session renewal on login/logout (`identity_auth.ex:358-364`); enumeration-resistant sign-in; open-redirect defense (`auth_controller.ex:69-78`).
- **The Resend/Svix signature implementation** (`resend_webhook_signature.ex`): HMAC-SHA256, constant-time compare, replay window, raw-body capture via `CacheBodyReader`. The model the Postmark endpoints should copy.
- **Aggregate quality**: `Message` owns a real delivery-status state machine; `InboundEmailReceipt` is an exemplary idempotency aggregate; `Memba.ID` typed IDs validated at every boundary.
- **Dispatch idempotency**: claim-based `UPDATE … WHERE status = 'pending'` prevents double-send even multi-node (`email_delivery_dispatcher.ex:44-90`).
- **Boundary discipline**: essentially no web-layer `Repo` access outside dev/test support; Messaging reaches Membership only through its public API (ADR 0007 holds).
- **Test architecture**: ~80% of scenarios genuinely dual-run; tag discipline documented and self-tested; **zero sleeps** in Elixir tests (strong-consistency projectors designed the flakiness out); webhook parsers/signatures/dispatcher failure modes all covered; browser suite has excellent failure forensics; smoke tests match ADR 0020 exactly.
- **Hygiene**: modern stack (Elixir 1.18/OTP 27, Phoenix 1.8.7, LiveView 1.1.30, all deps recent), clean compile, no TODO/FIXME debt markers, plain-text-only inbound email policy side-stepping stored-XSS, dev/test routes compile-gated out of prod.

---

## Findings

Severity: **MAJOR** = architectural/security concern that gets worse or bites hard; **MODERATE** = worth fixing in the next few iterations; **NIGGLE** = small annoyance, batchable.

### A. Security at the HTTP boundary

**A1. MAJOR — Postmark inbound webhook is completely unauthenticated, and inbound sender identity is From-header trust.**
`PostmarkInboundWebhookController.create/2` (`web/lib/memba_web/controllers/postmark_inbound_webhook_controller.ex:9-28`) does no signature/basic-auth/IP verification before calling `Messaging.receive_inbound_club_email/2`. Sender identity is resolved purely from the parsed `From` address (`inbound_club_sender.ex:36-71` → `Membership.get_verified_person_by_email/1`). Anyone who can POST to `/webhooks/postmark/inbound` can forge a member reply or club-wide broadcast (which then emails every member) by setting `From:` to a member's address. This was flagged in `docs/kaizen/2026-06-02-provider-webhook-authentication-gap.md` and in ADR 0016's consequences; it remains open. Fix: shared-secret/basic-auth in the webhook URL plus Postmark IP allow-listing, to the same standard as the Resend/Svix path.

**A2. MAJOR — Postmark outbound status webhook is also unauthenticated.**
`postmark_webhook_controller.ex:11-23` accepts forged delivered/bounced/spam events and auth-email progress records with attacker-supplied correlation IDs — corrupting delivery projections shown to members and staff, and writing forged events into the event store.

**A3. MAJOR — No rate limiting anywhere in the application.**
No Hammer/ExRated/PlugAttack dependency or equivalent. Unauthenticated `POST /get-started` (`page_controller.ex:114-130`) and the sign-in LiveView event (`auth_live/sign_in.ex:302-313`) each trigger a real provider email to any attacker-supplied address, unbounded — email-bombing and provider-spend abuse. Token endpoints and webhooks have no throttle either (tokens are 256-bit so brute force is infeasible, but there's no defense-in-depth).

**A4. MODERATE — Resend webhook verification fails open when the secret is unconfigured.**
`verify_signature/1` returns `:ok` if no secret is set (`resend_webhook_controller.ex:30-36`, `resend_inbound_webhook_controller.ex:39-45`). Prod is protected only by a boot-time raise in `runtime.exs`; the controller-level skip branch is a footgun. Fail closed in prod.

**A5. MODERATE — Invitation and stop-follow tokens never expire.**
Invitations get no `expires_at` (`membership.ex:1145-1158`); stop-follow tokens use `max_age: :infinity` (`conversation_stop_follow_token.ex:33,47`). Invitations grant club membership; an old inbox leak is a real exposure. Contrast the 15-minute sign-in/verification TTLs.

**A6. NIGGLE — No sweep for spent/expired sign-in tokens** (table grows unbounded); `auth_email_requests` has retention cleanup but `auth_sign_in_tokens` doesn't.

### B. Production operability

**B1. MAJOR — No health check, no error tracking, no metrics sink.**
`fly.toml` has no `[[http_service.checks]]`; a booted-but-broken app still receives traffic. No Sentry/AppSignal/Honeybadger; `telemetry.ex` defines metrics but attaches no reporter (`telemetry.ex:15` commented out) and LiveDashboard is dev-only. Today, "how would you know prod is broken" = the Fastmail smoke test plus manually tailing `fly logs`.

**B2. MODERATE — Dispatcher has no startup/recovery sweep and a black-hole state.**
Dispatch fires only on a projection-change nudge (`email_delivery_dispatcher.ex:181-197`); deliveries pending at deploy/crash time sit until an unrelated send. A crash between claim and provider call strands rows in `dispatching` forever — neither nudge nor manual retry (which targets `failed` only, `:234-258`) can touch them. The moduledoc admits no automatic sweeps.

**B3. MODERATE — Projection rebuild while the dispatcher runs would re-send email (code-health 2026-06-21/038, confirmed still open).**
`Projectors.EmailDelivery` publishes every committed change from `after_update/3` (`projectors/email_delivery.ex:32-33`); the dispatcher subscribes with no replay/rebuild guard (`email_delivery_dispatcher.ex:170,181-197`). The replay-safety test stops the dispatcher first, so the dangerous configuration is untested. See also D3 — the deeper modeling issue.

**B4. MODERATE — Not cluster-safe, but wired as if it might be.**
Commanded registry/PubSub are `:local` (`config.exs:38-47`) — two nodes would double-run every projector — yet DNSCluster is configured (`application.ex:32`, `runtime.exs:146`). The dispatcher itself is multi-node-safe via DB claims, but the event-sourcing side is not. Decide and document "single-node for now" (ADR) or make it cluster-safe before scaling `min_machines_running`.

**B5. MODERATE — Test scaffolding runs in the production supervision tree.**
`EmailDeliveryProviders.Fake` and `LocalDeliveryFacts` (an unbounded in-memory Agent whose docs say it exists for browser acceptance tests) start unconditionally (`application.ex:16-17`). `DevTestSupportController` (including an any-email sign-in bypass) compiles into the prod release, gated only by routes.

**B6. MODERATE — Production DB SSL is commented out** for the repo and both event stores (`runtime.exs:107-130`). Defensible on Fly private networking, but it reads as accidental; make it a documented choice.

**B7. NIGGLE — `PHX_HOST` defaults to `"example.com"`** in prod (`runtime.exs:144`) instead of raising like `DATABASE_URL`/`SECRET_KEY_BASE` — silent broken absolute URLs (sign-in links!) rather than fail-fast.

**B8. NIGGLE — No `bin/` wrapper for `Release.rollback/2`** (migrate has one); rollback under pressure is an ad-hoc `eval`. Release migrate also boots the full app (incl. dispatcher, DNSCluster) to ensure smoke fixtures (`release.ex:181-185`) — heavier than pure DDL.

**B9. NIGGLE — Supply chain**: `{:cucumber, github: "huddlz-hq/cucumber"}` unpinned (no `ref:`) (`web/mix.exs:54`); Dockerfile base images not digest-pinned. Test-only/low risk, but cheap to pin.

### C. Event-sourcing durability (long-horizon)

**C1. MAJOR — No event versioning/upcasting strategy.**
Zero `Commanded.Event.Upcaster` implementations; no version fields. Schema evolution so far is handled ad hoc inside domain code: no-op replay shims for the dead `EmailDeliveryOpened` event (`message.ex:142-147`, `projectors/member_email_delivery.ex:48-53`); dual-shape string/atom-key payload matching in `Person` and `EmailAddresses` (`person.ex:265-279,318-320`, `email_addresses.ex:206-285`); `@legacy_verified_at ~U[1970-01-01]` baked into aggregate apply (`person.ex:23,300-305`). Each is an upcaster written in the wrong place; every aggregate and projector must forever know every historical shape. Adopt upcasters (or a deserialization-boundary normalizer) and record the strategy in an ADR **before the next event-shape change**.

**C2. MAJOR — Events carry no occurred-at business time.**
Only `PersonEmailAddressVerified` has a timestamp. Projectors stamp rows at projection time (`projectors/role.ex:25`, `projectors/person.ex:36` uses `DateTime.utc_now()`), so rebuilds produce different data than the original run — defeating the core replay guarantee. Already user-visible: `member_since: membership.inserted_at` (`membership.ex:791`) is projection-commit time, and the club-data-import requirement means real clubs bring historical join dates this cannot represent. `metadata.created_at` is available in every `project/3` and unused. Fix before the first real club import.

**C3. MAJOR — The email-delivery table is a projection/operational-state hybrid.**
`Projectors.EmailDelivery` inserts rows as `pending` (`projectors/email_delivery.ex:17-29`); the dispatcher then mutates the same rows through pending→dispatching→sent/failed with attempt counts and diagnostics. Consequences: (a) rebuilding this projection recreates history as `pending` and the next nudge re-emails everyone (B3 is the acute symptom); (b) dispatch outcomes are unrecoverable state in a rebuildable table, while provider webhook statuses are events — an undocumented asymmetry. Either emit `EmailDeliveryDispatched/DispatchFailed` events or move dispatch state to a non-projection table; add rebuild tooling. ADR-level decision.

**C4. MODERATE — Message and ConversationFollowers aggregates share one event stream** (both identified by root `conversation_id == message_id`; `messaging/router.ex:25`). The code copes via mutual no-op applies and Commanded's retry-on-version-conflict, but `Message` has **no catch-all `apply`** — any future event type appended to the stream by another aggregate crashes Message rehydration on old streams. Undocumented; needs an ADR plus a guarded catch-all.

**C5. MODERATE — Two EventStore modules, one physical schema.**
`Memba.EventStore` and `Memba.Messaging.EventStore` get identical config in every env (same DB, same `schema: "event_store"` — `runtime.exs:121-130`); `config.exs:12` lists only one. The ADR 0007 context split is not reflected in storage; stream-name collisions are prevented only by typed-ID prefixes. Split schemas or delete the second module and document the shared store.

**C6. MODERATE — The event-sourced-vs-plain-Ecto boundary is principled but undocumented.**
Accounts (sign-in tokens, auth-email progress), Onboarding requests, and `EmailAddressVerificationToken` (a plain-Ecto table *inside* the otherwise event-sourced Membership context) are sensible ADR 0002 exceptions — but ADR 0002 requires exceptions to be explicit, and no ADR records them. The verification-token table inside `membership/` is exactly where the next contributor will guess wrong.

**C7. MODERATE — Read-model uniqueness checks race.**
Club-slug uniqueness (`membership.ex:1482-1495`), duplicate-active-membership (`:1249-1255`), email-ownership (`:1640-1655`) are check-then-dispatch against projections; two concurrent requests can both pass, with no compensation path. Low probability, permanent-corruption failure mode.

**C8. MODERATE — Multi-aggregate orchestrations have no compensation/resume.**
`complete_invited_club_member_profile` (CreatePerson → AddMember → AcceptInvitation, `membership.ex:364-392`), onboarding conversion (`onboarding.ex:184-205`), and the inbound accept flow (`messaging.ex:1037-1052`) all strand partial state on mid-sequence failure, and retries then fail (`:already_created` / `:slug_taken` / duplicate-receipt no-op that permanently swallows the rejection email). Individually unlikely; collectively they argue for idempotent-resume design or a process manager for the invitation saga.

**C9. MODERATE — Side-effect boundaries are inconsistent.**
The outbound path has the dispatcher; but inbound rejection email is sent synchronously inside the command path (`messaging.ex:1104-1139` — if the send fails after the event commits, the webhook retry hits the duplicate no-op and the rejection email is never sent), and invitation emails are sent from two LiveViews (`member_invitation_live/new.ex:261`, `admin/club_member_invitations_live/new.ex:227`) rather than from the context or a post-commit handler.

**C10. MODERATE — Inconsistent projector idempotency styles.** Role/ConversationFollow/person-email use `on_conflict` upserts; Message/EmailDelivery/MemberEmailDelivery/InboundEmailSource use bare inserts that crash on any checkpoint/table drift. Pick one convention. Also `MemberEmailDelivery.update_status` reads outside the Multi and silently no-ops on missing rows (`projectors/member_email_delivery.ex:55-58`).

**C11. NIGGLE — PII lives forever in immutable events** (recipient names/emails in `EmailDeliveryCreated`, full bodies in `MessageSent`). No crypto-shredding/deletion strategy; a membership product holding real people's data will eventually need an ADR (GDPR erasure).

**C12. NIGGLE — `ProjectionBarrier` (ADR 0022) is test-only** in practice (no production callers; `consistency: :strong` covers product flows) and carries raw-SQL knowledge of eventstore/projection internals (`projection_barrier.ex:61-105`). Fine — but annotate the ADR so the intent matches reality.

### D. Web layer and multi-tenancy

**D1. MAJOR (risk, not a live hole) — Tenancy enforcement on connected mounts is per-view convention; the centralized hook exists but is dead code.**
The `:club_member` live_session mounts only `mount_current_identity`, which never halts (`router.ex:67-69`). `IdentityAuth.on_mount(:require_active_club_member, …)` and `(:require_authenticated_identity, …)` (`identity_auth.ex:195-240`) have **no callers**. Every current LiveView independently re-verifies via loaders (audited: no cross-club access is possible today — `MemberMessageDetail.require_message_in_club` etc. all check club ∈ identity's active clubs AND record.club_id), but a future `live` route with a naive mount ships with no membership check on WebSocket mounts/live navigation. Wire the hook into the live_session; keep loaders as defense-in-depth. Also: `MySettingsLive.selected_club/1` checks only that the club *exists*, not membership (`my_settings_live.ex:411-418`) — data shown is self-scoped so nothing leaks, but it breaks the pattern.

**D2. MODERATE — Live-update wiring is inconsistent and over-broad.**
Everything subscribes to one global `ReadModelChanges.topic()`. The dashboard re-queries the *entire* club home on any `MemberEmailDelivery` change in *any* club, yet does **not** subscribe to `Projectors.Message` — so new conversations don't appear live at all (`member_dashboard_live.ex:47-51`), while the one projector it reacts to feeds data the dashboard no longer displays. The delivery-details page — whose whole purpose is live status — has **no subscription** (its empty state says "Check again in a moment"). `MemberMessageLive.Show` does it right (filters by message/conversation id, `show.ex:58-93`). Introduce per-club topics and align the three surfaces.

**D3. MODERATE — Member surfaces hold full collections in socket assigns; admin uses streams, member pages don't.**
Dashboard keeps all members + conversations + name maps per socket (`member_dashboard_presentation.ex:36-47`); no `temporary_assigns`. Linear per-socket memory growth; the club-history import will make lists big. Admin LiveViews already use streams consistently — port the pattern.

**D4. MODERATE — ~200 lines of copy-paste across the four member LiveViews.**
`put_session_club_id/2`, `ensure_identity_assigns/1`, `selected_club/2`, `forbidden!/1`, etc. near-identical in four modules; `MemberDashboardLive` privately re-implements IdentityAuth's identity derivation (`member_dashboard_live.ex:77-110` duplicates `identity_auth.ex:256-293`); five separate `initials/1` implementations with subtly different rules. A `MembaWeb.MemberScope` on_mount + one helpers module deletes it.

**D5. MODERATE — LiveView templates stranded in the controller namespace.**
`MemberDashboardLive` renders `PageHTML.club` and `MemberMessageLive.Show` renders `PageHTML.message`, with templates in `controllers/page_html/` that `PageController` never uses. Pre-ADR-0015 migration residue; move to `live/`.

**D6. MODERATE — Dead code from iteration 047.**
`MemberMessageLive.Show` still carries `:expanded_receipt_groups`, `handle_event("toggle_receipt_group", …)`, and helpers (`show.ex:39,97-100,170-181`) for UI that moved to the delivery page; no template references remain.

**D7. MODERATE — Webhook controllers do heavy work inline.**
All four dispatch with `consistency: :strong` in-request; Resend inbound additionally makes a synchronous outbound Resend API call before responding (`resend_inbound_webhook_controller.ex:34`). Slow projections → provider timeouts → retries (dedup exists, but ack-then-async is safer).

**D8. NIGGLE — Three different "forbidden" experiences** (plug bare `403` text, `ForbiddenError` rendered page, on_mount flash+redirect); connected-mount not-found raises a 500 "message detail not found" instead of 404 (`show.ex:352`, delivery `:330`).

**D9. NIGGLE — Assorted**: follow toggle binds both `phx-click` and `phx-change` to the same event (double dispatch, `page_html/message.html.heex:50-61`); `CanonicalHostRedirect` does a DB lookup in the endpoint and `String.contains?(query_string, "club_id=")` matches `other_club_id=`; the `?club_id=` fallback pipeline that ADR 0019 called temporary is now vestigial; every active member can see per-recipient delivery status and bounce reasons — if intentional, document it (privacy call); Google Fonts imported at runtime on member pages (`app.css:2`); admin shell styled with raw hex while member pages are guard-tested against exactly that; revoked members keep an open socket working until reconnect (acceptable, worth knowing).

### E. Contexts and code organization

**E1. MODERATE — The two context modules are becoming grab-bags.**
`membership.ex` 1,823 lines / 46 public functions (club CRUD + email-address/verification-token machinery + invitations + roles); `messaging.ex` 1,469 lines, of which ~1,000 are the inbound-email resolve→authorize→accept/reject pipeline. Both are still internally ordered, but extraction candidates are obvious: `Messaging.InboundEmailPipeline`, `Membership.EmailVerification`.

**E2. MODERATE — Domain→web dependency inversion.**
Domain code reaches into the web layer for URL/token building: `conversation_stop_follow_token.ex:11` (aliases `MembaWeb.Endpoint`), `onboarding/welcome_email.ex:15` and `email_delivery_dispatcher.ex:29` (alias `MembaWeb.ClubSite`), `onboarding/new_request_email.ex:138` (`MembaWeb.Endpoint.url()`). Invert with a URL-builder config/behaviour owned by the domain.

**E3. MODERATE — Reply command boundary root-conversation invariant still missing (code-health 2026-06-21/039 #2, confirmed open).**
`fetch_conversation_root/1` (`messaging.ex:1373-1382`) only casts + `Repo.get`; a caller passing a reply's ID as `conversation_id` builds a reply against a non-root projection. The read path enforces root shape separately — write/read asymmetry. One small guard away; also feeds follow/unfollow.

**E4. NIGGLE — Duplication batch**: `normalize_email`/`valid_email?` re-implemented 4× alongside the canonical `EmailAddresses.normalize_email`; `fetch_required/fetch_optional` copy-pasted between the two contexts; `validate_id/3` pasted into every aggregate; the 11-projector list duplicated between `event_sourced_case.ex:12-24` and `dev_test_support_controller.ex:14-26` (a new projector must be added in both or test resets silently miss it); member vs staff delivery-status presentation maps drifting toward duplicated semantics (`member_email_delivery_presentation.ex` vs `admin/deliveries_live/index.ex:237-252`, `admin/messages_live/show.ex:329-340`).

**E5. NIGGLE — Naming/vestigial**: `list_member_email_deliverys` typo in a public API (`messaging.ex:598`); "email email" doc typos; unreferenced `EmailDeliveryProviderConfig`; `list_messages_for_club/1` now used only by dev seeds; onboarding bypasses Membership's public API once for role assignment (`onboarding.ex:266-275`); the follow/unfollow "reconcile by dispatching a Follow before Unfollow" workaround (`messaging.ex:1415-1431`) is a smell pointing back at C4's shared-stream modeling.

### F. Test architecture

**F1. MAJOR (structural cost, deliberate) — The suite is predominantly serial with heavy per-test churn.**
86 files `async: false` vs 55 async; `EventSourcedCase` raises on async and each test stops all 11 projectors, truncates event store + projections, resets subscription acks, restarts projectors (`event_sourced_case.ex:47-58,118-160`) — used by 35 files + 15 FeatureCase files + ~101 generated domain-Cucumber tests. This is the honest price of a shared Postgres event store with strong-consistency projectors, but it is the suite's dominant and growing cost. Additionally the `mix test` alias drops and rebuilds the database on **every** invocation, even single-file runs (`web/mix.exs:105-112`).

**F2. MODERATE — ~14k lines of dual step-definition glue.**
7 Elixir step files (5,184 lines) + 12 JS step files + support (~8,900 lines) for 122 scenarios; `member_message.js` alone is 3,951 lines. The dual-layer value is real (~80% scenarios dual-run) but the glue cost curve needs watching. The domain runner is also a hand-rolled replacement for cucumber-lib internals (`domain_cucumber_runner.ex`) atop an unpinned GitHub fork.

**F3. MODERATE — The source-scanning guardrail-test family has grown to 4 files / ~540 lines** (`member_page_design_system_alignment_test.exs`, `app_css_test.exs`, `app_shell_css_test.exs`, `club_site_shell_surfaces_test.exs`) asserting literal CSS strings and regex-extracted HEEx. They churn with every design-sync pass and prove little about rendered behavior. The hardcoded `@member_page_files` list has **already drifted**: member surfaces from iterations 047–053 (message show, delivery show, settings) are absent, so the no-hex/no-legacy-theme checks don't cover them.

**F4. MODERATE — Browser-suite control channels are elaborate**: HTTP test-support endpoints *plus* distributed-Erlang RPC spawning `elixir --rpc-eval` with string-templated Elixir and a hardcoded cookie (`server_commands.js:558-585`). Defensively written with excellent forensics, but expensive to debug when the lifecycle breaks; parallelism remains blocked by global reset state (kaizen 2026-06-04).

**F5. MODERATE — Global-singleton fakes isolated by convention only.** The Fake provider is a named Agent in the app tree; isolation relies on `Fake.reset()` calls and everything staying `async: false` — nothing enforces it. `Application.put_env` provider switching leaks if teardown is skipped. Poll timeouts (`assert_eventually` 1s, barrier 1s) are tight for loaded CI.

**F6. GOOD to preserve**: dual-layer scenarios genuinely shared and self-tested; zero sleeps; failure-mode provider fakes; webhook/parser/signature coverage; meta-tests keeping both cucumber configs honest; gallery-walk rig; smoke tests per ADR 0020.

### G. docs/code-health.md reconciliation

Verified every numbered finding against current code:

| Entry | Status |
|---|---|
| 2026-07-09 design-gap: `.conversation`/`.message`/`.composer`/`.avatar-stack` classes never ported | **FIXED** — full family now in `app.css:234-823`, used by `club.html.heex`/`message.html.heex`; `app.css` `@import`s root `styles.css` (single source). Close this entry. |
| 2026-07-07 ADR-0023 #1: receipt-group expansion on message page | **OBSOLETE** (surface moved in iteration 047) — but dead code remains in `member_message_live/show.ex` (see D6) |
| 2026-07-07 #2: invitation profile completion controller-based | **STILL OPEN** — neither migrated nor documented as an exception |
| 2026-07-07 #3: get-started controller flow | **STILL OPEN** — same |
| 2026-07-07 #4: compose success assigns-only | **STILL OPEN** (now links to the message, but no navigate; decision never made) |
| 2026-07-07 #5: admin rejection phx-click vs URL-backed conversion | **STILL OPEN** (accepted-open per the log's own suggestion) |
| 2026-07-07 (047) delivery-details expansion not URL-addressable | **STILL OPEN** — `<details>` only, no `handle_params` (`member_message_delivery_live/show.ex:158-165`); decide or document as transient exception |
| 2026-06-19 (037) #1: preview class conventions undocumented | **FIXED** — `design-system/README.md` covers it and more |
| 2026-06-19 (037) #2: render-verification evidence not persisted | **STILL OPEN** (process) |
| 2026-06-18 (034) #1/#3/#4: brittle guardrail, separate presentations, gallery-walk reliance | **STILL OPEN, accepted** as the log intended |
| 2026-06-18 (034) #2: `@member_page_files` drift | **STILL OPEN and now real** — list misses all member surfaces added since (see F3) |
| 2026-06-19 (036) preview path mapping drift | **OBSOLETE** — superseded by the `.design-sync` workflow |
| 2026-06-21 (038) projector replay can nudge dispatcher | **STILL OPEN** — no guard; see B3/C3 |
| 2026-06-21 (039) #1: replies as top-level dashboard rows | **FIXED** — `list_conversations_for_club/1` (one row per root, reply counts) |
| 2026-06-21 (039) #2: reply root-conversation invariant | **STILL OPEN** — see E3 |

Suggested code-health.md hygiene: mark the three FIXED and two OBSOLETE entries, and fold B3/E3/F3-drift into whatever tracking follows this review.

---

## Prioritized recommendations

**P0 — Security at the boundary (days, do first):**
1. Authenticate both Postmark webhooks (shared secret in URL + Postmark IP allow-list), and make Resend verification fail closed in prod (A1, A2, A4). The inbound endpoint is a forge-a-member-broadcast hole.
2. Add rate limiting (Hammer or PlugAttack) to `/get-started`, the sign-in link request, token callbacks, and webhooks (A3).

**P1 — Know when production is broken (days):**
3. Health-check endpoint + `fly.toml` checks; add an error tracker (Sentry/AppSignal); attach a telemetry reporter; make `PHX_HOST` raise when unset (B1, B7).
4. Dispatcher hardening: boot-time pending sweep, `dispatching`-timeout recovery, and a replay/rebuild guard so projection rebuilds can't re-send email (B2, B3). Test the running-dispatcher replay scenario.

**P2 — Event-store durability, before real club data arrives (1–2 iterations):**
5. Adopt an event upcasting strategy + ADR; migrate the scattered dual-shape/legacy shims into it (C1).
6. Add occurred-at business timestamps (or project from `metadata.created_at`); fix `member_since` before the club-history import lands (C2).
7. Decide the email-delivery dispatch-state model (events vs separate operational table) + rebuild tooling + ADR (C3).
8. Small-but-load-bearing: root-conversation invariant guard (E3); catch-all `apply` in Message + shared-stream ADR (C4); ADR for the event-sourced-vs-Ecto boundary (C6) and the shared event-store schema (C5).

**P3 — Structural web hardening (1 iteration):**
9. Wire `on_mount :require_active_club_member` into the `:club_member` live_session; fix `MySettingsLive` club check; delete or use the dead hooks (D1).
10. Live-update pass: per-club PubSub topics, dashboard subscribes to Message changes, delivery page subscribes at all (D2). Streams for member/conversation lists (D3).
11. Cleanup batch: dead receipt-group code, shared member-scope helpers, move stranded templates, unify forbidden/404 UX (D4–D6, D8).

**P4 — Sustainability (ongoing, opportunistic):**
12. Extract `InboundEmailPipeline` and email-verification machinery from the context grab-bags (E1); invert the domain→web URL dependency (E2); move invitation/rejection emails behind a post-commit boundary (C9).
13. Token lifecycle: invitation/stop-follow expiry, spent-token sweep (A5, A6).
14. Test-suite cost curve: stop dropping the DB on every run (migrate-if-needed instead), regenerate the `@member_page_files` list or derive it, keep the step-glue growth visible, pin the cucumber fork (F1–F5, B9).
15. Niggle batch: typo'd public function, duplicated projector list, five `initials/1`s, follow-toggle double bind, Google Fonts self-hosting, etc. (E4, E5, D9).

**Decisions to make explicitly (cheap, high leverage):** single-node vs cluster (B4); recipient-level delivery visibility for all members (privacy, D9); ADR-0015 exceptions for invitation-profile and get-started flows; delivery-details expansion as documented transient exception or URL state; PII/erasure strategy for immutable events (C11).
