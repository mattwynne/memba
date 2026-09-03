# dev gallery-walk — visual walkthrough of the app + emails

**Date:** 2026-06-17
**Roles:** Claude = PM (spec, task breakdown, review, validation). Codex = implementation (`codex exec -s workspace-write … < /dev/null`).
**Goal:** A repeatable `./bin/dev gallery-walk` that boots the dev app with realistic seeded data, screenshots the key member + marketing pages (desktop + mobile) and the transactional emails (via `/dev/mailbox`), and emits a static HTML/JS gallery for eyeballing the real UI — the feedback loop for polishing pages to match the design system.

## Context (verified)
- App is **Commanded CQRS/ES** (`Commanded.EventStore`). State is built by dispatching **domain commands** (`Memba.*.Commands.*`) → events → projections. Seeds MUST dispatch commands, not raw Ecto inserts, or read models won't reflect them.
- Mailer is **`Swoosh.Adapters.Local`**; **`/dev/mailbox`** (`Plug.Swoosh.MailboxPreview`) is already mounted under `dev_routes` in `router.ex`. No mailbox to build — just use it.
- An existing **`priv/repo/seeds.exs`** (~15K) exists — **review and extend it**, don't replace wholesale.
- A **`/dev/test-support`** route scope exists (`MembaWeb`, dev-only) — investigate for a session/login helper the walker can use; prefer it over scripted magic-link if it cleanly establishes a member/staff session.
- Playwright is already a dependency in `acceptance-tests/` (`@playwright/test` 1.59.1) — reuse it as the screenshotting driver.

## Components (build in this order)

### A. Realistic dev seeds
Extend `priv/repo/seeds.exs` (or a `Memba.DevSeeds` module it calls) to build realistic state by dispatching domain commands:
- 2–3 clubs with distinct names + initials (e.g. Kootenay Alpine Club, Wessex Chamber Choir, Rideau Park Sailing).
- Several members per club (varied names → varied initials/avatar tints), at least one with a management role.
- Multiple club messages per club with **mixed delivery receipts** (delivered / opened / bounced) so receipt mini-bars and status badges render with real variety.
- One pending club-member invitation and one pending account request (for the staff/empty surfaces later).
- Trigger the representative transactional emails so they land in `/dev/mailbox`: welcome, sign-in link, member message, renewal reminder, inbound rejection.
- **Repeatable:** safe to run against a freshly reset dev DB. Document the reset+seed path (e.g. `dev seed` drops/recreates dev data then seeds, or relies on `mix ecto.reset`).

**Acceptance:** running the seed against a clean dev DB produces ≥2 clubs, members with roles, messages with varied receipts, and ≥5 distinct emails visible at `/dev/mailbox`. `mix compile` clean. Seeds are deterministic enough to screenshot (stable names/subjects).

### B. Scene manifest + Playwright walker
A declarative manifest (data, e.g. a JS/JSON array in `acceptance-tests/gallery/scenes.*` or similar) of scenes for **member + marketing** (v1):
- Marketing home (`/`), member club home, member message read, member message compose, public club page.
- Each scene: `{ id, area, label, authContext, navigate }`.
- **Auth context:** establish a signed-in member (and where needed staff) session. Prefer the `/dev/test-support` helper if it supports this; otherwise dogfood the magic-link flow (request sign-in → read link from `/dev/mailbox` → follow it).
- Walker (Node + Playwright, reusing the acceptance harness's browser/server knowledge) visits each scene and captures **desktop (1280×800)** and **mobile (390×844)** screenshots into the output dir.
- Also enumerates `/dev/mailbox` messages and screenshots each email preview (label by subject), into an "Emails" area.

**Acceptance:** running the walker against a seeded, running dev server writes 2 PNGs per app scene + 1 per email into the output dir, named predictably (`<area>__<id>__<viewport>.png`). Missing scenes fail loudly, not silently.

### C. `./bin/dev gallery-walk` + HTML/JS gallery
- Add a `# @cmd` `gallery_walk` function to `bin/dev` (follow the existing argc pattern, e.g. `up`, `check`, `acceptance`). It: ensures the dev server + Postgres are up (reuse existing helpers), runs the seed, runs the walker, generates the gallery, and opens it.
- **Gallery:** a single static `gallery.html` + small JS (no build step) that indexes the PNGs, groups by area (App / Emails), shows a **desktop⇄mobile toggle** per scene, and labels each. Self-contained (reads a generated `manifest.json` of captured shots, or inlines the list).
- **Output dir:** `tmp/gallery/` (gitignored — add to `.gitignore`). Opens via the platform opener (`open` on macOS).

**Acceptance:** `./bin/dev gallery-walk` on a clean checkout (after `dev setup`) produces `tmp/gallery/gallery.html` showing member + marketing pages at both viewports and the seeded emails, and opens it. Re-running is idempotent (overwrites).

## Out of scope (v1)
- Staff/auth scenes (extend the manifest later), side-by-side DS-design comparison (future — would map scenes → DS previews), white-label theming (backtracked for now), CI integration.

## Codex task breakdown (PM hands these out)
1. **Seeds** (Component A) — extend `seeds.exs`; validate via `mix run priv/repo/seeds.exs` + check `/dev/mailbox`.
2. **Walker + scenes** (Component B) — Node/Playwright + manifest + auth.
3. **`dev gallery-walk` + gallery** (Component C) — argc command + HTML/JS gallery + `.gitignore`.

Codex cannot run `mix`/the server in its sandbox; **Claude validates** each by booting the dev server via `devenv shell` and running the seed/walker, and by opening the gallery. TDD where it fits (seeds: a small test asserting seeded read models exist; walker/gallery: validated by running + visual check).

## Risks
- Walker auth: if neither `/dev/test-support` nor magic-link is workable cleanly, fall back to a documented dev-only login helper. Decide during Component B.
- Seed → email timing: ensure emails are actually delivered to the local mailbox synchronously (or wait) before the walker reads `/dev/mailbox`.
- Event-sourced seeds may need to await projections before read models are queryable — seed step should wait for projection catch-up.
