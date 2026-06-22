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
