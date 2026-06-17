# Phase 2 — DS previews → daisyUI (member + marketing)

**Date:** 2026-06-17  **Depends on:** Phase 1 (app foundation, complete).

## Goal
Make the claude.ai/design previews render with **daisyUI + the app's real theme** instead of the bespoke `memba.css` component classes, so the DS mirrors the running app. Spike-proven approach: **prebuilt daisyUI CSS via CDN + the daisyUI theme as `:root` vars** (the Tailwind browser build can't load the daisyUI plugin — dead end).

## Approach: self-contained per page (incremental-safe)
Each converted preview carries its own `<head>` block (daisyUI CDN `<link>` + theme `:root` vars + `@import tokens.css` worth of raw tokens for the layout CSS) and **stops linking `styles.css`**. Page-specific layout CSS (`.m-*`, `.cl-*`) stays as plain CSS.

Why not edit the shared `styles.css`/`memba.css` now: `memba.css` defines its own `.btn` base, which collides with daisyUI's `.btn`. Removing bespoke component classes from the shared file would break every not-yet-converted page (incl. staff, Phase 4). So convert page-by-page self-contained; once ALL pages are converted (end of Phase 4), delete the dead bespoke component CSS and optionally factor a shared `ds-app.css`.

## Verification (every page, before pushing)
Render locally with headless Chrome against the live CDNs and visually compare to the original intent. Only push after a clean render.

## Push
Via DesignSync `finalize_plan` → `write_files` (user authorized direct pushes). Preserve each file's original `@dsCard` / `@startingPoint` header and relative asset paths.

## Scope & order (member/marketing first)
1. `ui_kits/member-app/index.html` (club home) — prototyped.
2. Component cards that showcase the Phase 1 components: `components/buttons|badges|avatars|forms|cards/*.card.html`.
3. `ui_kits/marketing/index.html`.
4. Member wireframes: `wireframes/club-home.html`, `club-home-vision-with-events.html`, `member-messaging.html`, `home.html`.
(Staff console previews are Phase 4.)

## Class-mapping cheat sheet (bespoke memba.css → daisyUI)
| Bespoke | daisyUI |
|---|---|
| `btn btn--primary` | `btn btn-primary` |
| `btn btn--secondary` | `btn btn-soft` |
| `btn btn--ghost` | `btn btn-ghost` |
| `btn btn--color-error` | `btn btn-error` |
| `btn--lg` / `btn--sm` | `btn-lg` / `btn-sm` |
| `pill p-ok` | `badge badge-success badge-soft` |
| `pill p-info` | `badge badge-info badge-soft` |
| `pill p-warn` | `badge badge-warning badge-soft` |
| `pill p-bad` | `badge badge-error badge-soft` |
| `statpill--ok` / `spill--active` | `badge badge-success badge-soft` |
| `statpill--bad` / `spill--paused` | `badge badge-warning badge-soft` |
| `spill--trial` | `badge badge-info badge-soft` |
| `spill--bounced` | `badge badge-error badge-soft` |
| `role role--lead/base/safe` | `badge` + sage/neutral/info soft (role chips) |
| `input` / `textarea` (bespoke) | daisyUI `input` / `textarea` |
| `field` / `field__label` / `field__hint` | daisyUI `fieldset` + `label` + `fieldset-label` |
| `av` / `av--sm` / `av--lg` | daisyUI `avatar avatar-placeholder` + `w-7/9/12 rounded-full bg-sage-* text-sage-800` |

Theme `:root` block to paste in each page head: the daisyUI `light` theme + sage/cream/ink token vars (copied verbatim from `web/assets/css/app.css`), plus the raw sage/ink/line tokens needed by the page's layout CSS.
