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
