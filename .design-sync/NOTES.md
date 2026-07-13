# Design-sync notes — Memba

Memba's design system lives at claude.ai/design (project `bc97cfc3-436c-471e-a939-7ba222859282`,
"Memba") and is the **source of truth**. Locally, `design-system/` is a *partial* mirror of it.
The generic `/design-sync` converter does not apply here — see `.design-sync/config.json`.

## How to sync (hand-authored, surgical)

- **Push local → cloud:** `DesignSync finalize_plan` (writes = exact changed paths, deletes = `[]`)
  then `write_files` with `localDir: design-system` and `localPath` per file. Never use delete globs.
- **Pull cloud → local:** `DesignSync get_file` per path, write under `design-system/`. The tool has
  **no bulk download** — each file's content is fetched and re-written individually, so mirroring the
  whole project locally (50+ files) is impractical. The foundational layer is read on demand instead.

## 2026-07-12 local restructure: `wireframes/` → `templates/` (fixing a category collision)

**Problem found:** local `design-system/wireframes/` had been flattening *both* cloud
`templates/*` (14 full-page screens) and cloud `wireframes/*` (3 mobile screens + `mobile.css`)
into one same-named local folder. That's wrong — in the cloud project these are genuinely
different categories (Templates = High Fidelity, built on real tokens, meant as a dev spec;
Wireframes = low-fidelity sketches — confirmed via Anthropic's own Claude Design docs), and
the local naming collision made it look like there was no distinction at all.

**Fix:** moved every full-page screen out of `wireframes/` into a new `templates/` folder
(`git mv`, 13 files: `admin-request-review.html`, `check-email-delivery-progress.html`,
`club-home.html`, `conversation-stop-following.html`, `delivery-details.html`,
`invite-a-member.html`, `marketing-homepage.html`, `member-conversation.html`,
`member-empty-first-run-states.html`, `new-message.html`, `onboarding-request-flow.html`,
`profile-completion.html`, `staff-console.html`), plus the new `account-settings.html`
(iteration 053 mockup, was misfiled under the old convention when first authored).
`design-system/wireframes/` now holds only what the cloud actually has there:
`mobile-club-home.html`, `mobile-compose.html`, `mobile-message-detail.html`, `mobile.css`.

Added `templates/README.md` and `wireframes/README.md` explaining each folder, and a
"Folder map" section in the top-level `design-system/README.md` stating the rule going
forward: **local folder name must always match the cloud category name** — no more
flattening two cloud categories into one local folder, ever.

**Resolved (2026-07-13):** `wireframes/member-conversation-overview.html` and
`wireframes/member-messaging.html` were deleted (`git rm`), confirmed superseded rather
than just unreferenced:
- `member-messaging.html` was explicitly a "Post-034" screen; `templates/member-conversation.html`
  is commented `FINAL (post-040) version` — a later iteration that replaced it (receipt/delivery
  detail moved into the `Delivery details` kebab-menu flow, per the 2026-07-04 pull #2 entry above).
- `member-conversation-overview.html` (iteration 043) grouped conversation replies into one row
  per conversation on club home; `templates/club-home.html` already has that behaviour built in
  directly (`conversation__replies`, reply counts) — the separate overview screen's concept was
  merged into club-home itself, which is why the cloud dropped it.

Local `wireframes/` now matches the cloud's `wireframes/` exactly: `mobile-club-home.html`,
`mobile-compose.html`, `mobile-message-detail.html`, `mobile.css` (plus the new local
`README.md`). History for both deleted files remains in git if ever needed again.

**Checked, not an omission:** cloud `wireframes/image-slot.js` was never pulled down —
confirmed (2026-07-13) it's generic Claude Design canvas-runtime scaffolding (an
image-drop-placeholder web component, `@ds-adherence-ignore -- omelette starter scaffold`),
not Memba design content, and none of the three mobile wireframes reference it. Local
`wireframes/` is a complete mirror of the Memba-relevant content in cloud `wireframes/`.

This was purely a local rename — nothing was pushed to or deleted from the cloud project.

## 2026-07-13 push #3 (local → cloud, ADR note + resolved open questions)

Resolved the two open questions from the pull below with Matt directly:
- Primary row's simplified note ("This is the address we'll send emails to.", no "can't be
  removed" clause) is fine as-is — obvious from the missing Remove action, not lost information.
- App-bar showing "Kootenay Alpine Club" instead of "Account settings" is intentional for now —
  Matt went back and forth on it; a future iteration will bring in a Memba-level global app bar,
  but that's not this iteration. Leave as committed.

Added one thing Matt flagged that wasn't a design question but an implementation-architecture
risk: the canvas-authored Profile/Clubs/Emails tabs use plain client-side JS (`<script>` at the
bottom, toggling `.is-active`). That's fine for a static preview file but must not be copied
into the real page — added an HTML comment above the `<script>` block pointing implementers at
`docs/adr/0015-use-liveview-for-member-application-pages.md` (member app surfaces are LiveView
by default) and `docs/adr/0023-use-url-addressable-liveview-state.md` (visible state like a
selected tab must be URL-addressable via `handle_params/3` + `<.link patch>` / `push_patch/2`,
same pattern as club-home's Conversations/Members tabs) — not left as an implicit assumption.

Pushed (`finalize_plan` writes = 1 exact path, deletes = `[]`):
- `templates/account-settings/account-settings.html` ← local `templates/account-settings.html`

## 2026-07-13 pull (cloud → local, account-settings iterated in canvas)

Pulled **down** `templates/account-settings/account-settings.html` after Matt reviewed and
drew feedback on it directly in the Claude Design canvas. Notable changes from what was pushed:
- Profile / Clubs / Emails restructured from three stacked cards into a side-tab layout
  (`.settings-tabs` + `.settings-panels`, one panel visible at a time), with vanilla-JS
  tab switching added at the bottom of the file (same pattern as `club-home.html`'s
  `.section-tabs`).
- Added a "‹ Back to club" link above the page title.
- Profile panel gained an avatar circle next to the name; dropped the "Name changes aren't
  part of this page" note.
- Email rows restructured: address + Primary badge share a top line, verification badge is
  right-aligned on that same line, actions moved to their own line below. Verified badges
  now use a small checkmark icon instead of a plain dot. Rows are now one grouped list with
  dividers instead of separate boxes per row.
- Email-section meta copy rewritten: "Your primary address is the one we'll send emails to.
  We'll accept incoming emails from your other addresses." (was a plain "Primary, verified,
  and pending addresses." label).
- Primary row's note simplified to "This is the address we'll send emails to." — **this drops
  the earlier "Can't be removed" clarification**, worth deciding whether that explanation
  should live somewhere else (e.g. disabled-state styling on a would-be Remove action) rather
  than just being gone.
- The settings-page app-bar now shows "Kootenay Alpine Club" instead of "Account settings" —
  contradicts the earlier design decision that this page is deliberately global/cross-club and
  shouldn't read as club-scoped (see the 2026-07-12 design-review entry above). Carries a
  `data-comment-anchor="5301845616-span"` attribute, so this was likely a canvas comment
  Matt left there — worth checking what that comment actually said before treating the
  club-name swap as final.
- Confirmation pages (success/invalid) and the avatar-menu panel are untouched.
- The eyebrow-label fixes from the 2026-07-13 push survived the round-trip — none reappeared.

## 2026-07-13 push #2 (local → cloud, account-settings mockup)

Pushed **up**, additive only (`finalize_plan` writes = 1 exact path, deletes = `[]`):
- `templates/account-settings/account-settings.html` ← local `templates/account-settings.html`

The iteration-053 `/my/settings` mockup (page, avatar-menu entry, and the two email-verification
confirmation states), pushed at Matt's request so he can review and draw/annotate feedback
directly in the Claude Design canvas rather than over chat. First-line `@dsCard`/`@template`
comments are already present in the file, so no `register_assets` call was needed — the Design
System pane's card index picks it up automatically. Not yet finalized/approved; expect another
push once Matt's cloud-side feedback comes back.

## 2026-07-13 push (local → cloud, new folder docs)

Pushed **up**, additive only (`finalize_plan` writes = exact 2 paths, deletes = `[]`):
- `templates/README.md` (new in cloud)
- `wireframes/README.md` (new in cloud)

Deliberately did **not** push local `design-system/README.md` to cloud `README.md` —
they are different documents. Cloud `README.md` is the canonical Memba brand doc
(colors, type, tokens, full file listing); local `design-system/README.md` is
Claude-Code-specific authoring guidance for repo-side preview HTML. Pushing local
over cloud at that path would have destroyed the real brand doc. If the local
"Folder map" explanation should also reach the cloud's root README someday, that
needs to be merged into the existing cloud doc by hand, not overwritten wholesale.

## 2026-07-04 pull #2 (cloud → local, in-club refresh)

Second pull of the day, after Matt refreshed the **in-club member-app pages** in the cloud.
The refresh restructured the in-club app shell: the top bar dropped the Memba mark +
club-name dropdown and is now just the plain club name, with the club description/identity
moved into dedicated surfaces.

Refreshed (existing local files, updated from cloud):
- `wireframes/club-home.html` ← `templates/club-home/index.html`
  (simplified app-bar; new **About** tab absorbing the old club-name-dropdown description;
  wired "New message" action + footer; longer conversation subject/preview copy)
- `wireframes/member-conversation.html` ← `templates/member-conversation/member-conversation.html`
  (simplified app-bar; compact `follow-toggle` tucked beside the title in a `detail-head`;
  per-message **kebab → Delivery details** menus replacing the `Original message`/`Reply`
  badges; dropped the inline receipt-summary block; wired back-link + footer)
- `wireframes/mobile-message-detail.html`, `wireframes/mobile-compose.html`
  (back/cancel `href` wired from `#` to `mobile-club-home.html`)

Added (new local files, flattened `wireframes/<name>.html` convention):
- `wireframes/new-message.html` ← `templates/new-message/index.html`
  (the refreshed club-home "New message" action links here; carries the desktop/mobile switcher)
- `wireframes/delivery-details.html` ← `templates/delivery-details/index.html`
  (the refreshed member-conversation kebab menus link here)

Verified byte-identical to cloud, not touched this pass:
- `wireframes/mobile-club-home.html`, `wireframes/mobile.css`,
  `wireframes/conversation-stop-following.html`

## 2026-07-04 pull (cloud → local, refresh + new)

Pulled **down** from the cloud (source of truth) to refresh a stale mirror. Every refreshed
screen had drifted from the cloud since the 2026-06-22 push.

Refreshed (existing local files, updated from cloud):
- `wireframes/club-home.html` ← `templates/club-home/index.html`
- `wireframes/member-conversation.html` ← `templates/member-conversation/member-conversation.html`
- `wireframes/admin-request-review.html`, `check-email-delivery-progress.html`,
  `member-empty-first-run-states.html`, `invite-a-member.html`, `conversation-stop-following.html`
  ← their `templates/<name>/…` cloud paths
- `wireframes/mobile-message-detail.html` ← `wireframes/mobile-message-detail.html`
- `components/badges/badges.card.html` (unchanged content, re-verified)
- `emails/reply-notification.html`, `emails/inbound-rejection.html` (already in sync — no diff)

Added (new local files, following the existing flattened `wireframes/` convention):
- `wireframes/marketing-homepage.html` ← `templates/marketing-homepage/index.html` (NEW cloud screen)
- `wireframes/staff-console.html` ← `templates/staff-console/index.html` (NEW cloud screen)
- `wireframes/mobile-club-home.html` ← `wireframes/mobile-club-home.html` (NEW cloud screen)

Path mapping note: the cloud reorganised member/staff screens under `templates/<name>/…`
(with `index.html` or a named file). Local keeps the flattened `wireframes/<name>.html`
convention, so cloud `templates/X/index.html` → local `wireframes/X.html`.

Also pulled (follow-up, to complete the mobile set):
- `wireframes/mobile-compose.html` (refreshed — the current iOS-style grouped-inset compose form)
- `wireframes/mobile.css` (NEW locally — the shared mobile layer every mobile wireframe links;
  was missing, so the local mobile previews couldn't render before)

Not pulled this pass (still cloud-resident, read on demand — deferred to keep the pull
focused on the surfaces a design/app gap analysis needs):
- `templates/onboarding-request-flow/…`, `templates/profile-completion/…`
- `templates/new-request-email/new-request-notification.html` and the newer emails
  (`welcome`, `sign-in-link`, `event-confirmation`, `member-message`, `renewal-reminder`,
  `email-system-spec`, `index`)
- foundational layer: `styles.css`, `memba.css`, `tokens.css`, `brand/**`, `components/**`,
  `guidelines/**`, `design-system.html`, `brand-guidelines.html`, `index.html`

## 2026-06-22 sync

Pushed **up** (local → cloud), additive:
- `wireframes/member-conversation-overview.html` (new — replies-aware conversations overview)
- `wireframes/conversation-stop-following.html` (new — stop-following confirmation page)
- `wireframes/member-conversation.html` (merged: cloud canonical + reply-composer posted/error states)
- `wireframes/admin-request-review.html`, `check-email-delivery-progress.html`, `invite-a-member.html`,
  `member-empty-first-run-states.html`, `onboarding-request-flow.html`, `profile-completion.html`
  (were local-only, now in the cloud)
- `emails/new-request-notification.html` (was local-only)

Pulled **down** (cloud → local):
- `wireframes/mobile-message-detail.html`, `wireframes/mobile-compose.html` (reply-relevant mobile screens)

## Cloud-resident (in the cloud, not mirrored locally — read on demand)

Not a loss: the cloud holds the union of both sides after the push above.
- wireframes: `club-home-vision-with-events.html`, `home.html`, `image-slot.js`, `mobile-club-home.html`, `staff-console.html`
- emails: `email-system-spec.html`, `event-confirmation.html`, `inbound-rejection.html`, `index.html`, `member-message.html`, `renewal-reminder.html`, `reply-notification.html`, `sign-in-link.html`, `welcome.html`
- foundational layer: `components/**`, `guidelines/**`, `ui_kits/**`, `brand/**`, `assets/**`, `design-system.html`, `brand-guidelines.html`, `index.html`, `memba.css`, `styles.css`, `tokens.css`
- generated/build artifacts (intentionally never mirrored to git): `_ds_bundle.js`, `_ds_manifest.json`, `_adherence.oxlintrc.json`, `.thumbnail`, `screenshots/**`, `SKILL.md`

## In both, assumed in sync (not diffed this pass)

`wireframes/club-home.html`, `wireframes/member-messaging.html`,
`components/badges/badges.card.html`, `README.md`. Diff before editing if drift is suspected.
