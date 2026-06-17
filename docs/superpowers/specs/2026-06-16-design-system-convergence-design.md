# Design-system ↔ app convergence

**Date:** 2026-06-16
**Status:** Approved (decomposition + Phase 1). Phases 2–4 get their own detailed specs when reached.
**Roles:** Claude = project manager (specs, task breakdown, review, integration, DS pushes). Codex = implementation (`codex exec -s workspace-write`).

## Problem

The claude.ai/design "Memba" project and the `web/` app share **design tokens** but have **divergent component layers**, today running as three incompatible styling systems:

1. **DS:** bespoke `memba.css` (`.btn--primary`, `.pill`, `.av`, `.field`, `.spill`, `.m-*`, `.staff-*`).
2. **App core:** daisyUI (`btn-primary`, `input`, `table table-zebra`).
3. **App admin:** ~370 hardcoded hex values as arbitrary Tailwind classes (`bg-[#15201c]`), off-token.

The DS also ships `MembaWeb.Components.{Button,Badge,Avatar,FormField}` `.ex` files using the bespoke classes; the app imports none of them.

## Goal (end state)

Bidirectional convergence around a single truth — **the app, expressed in daisyUI + the `app.css` theme**:

- **DS reflects reality:** previews use daisyUI + the app's real theme (no parallel `memba.css`).
- **App absorbs DS's best ideas:** the clean component taxonomy (button variants/sizes, status badge vocabulary, avatar tint cycle) and proper token usage (no hardcoded hex drift).

Verified earlier by spike: the **prebuilt-daisyUI-CSS + theme-as-`:root`-vars** approach renders the app theme faithfully in static claude.ai previews (the Tailwind browser build cannot load the daisyUI plugin, so that path is dead).

## Decomposition & sequence

| Phase | Sub-project | Rationale |
|---|---|---|
| **1** | App foundation: tokens + components | Defines the truth everything mirrors; the "app adopts DS ideas" half |
| **2** | DS member + marketing previews → daisyUI | Mirrors the settled app theme/components |
| **3** | Email alignment: app templates ↔ DS email-system spec | Real-user-facing, large, semi-independent |
| **4** | DS staff previews → daisyUI + app admin hex→token cleanup | Lowest priority (staff), biggest mechanical cleanup |

Each phase is implemented by Codex in discrete tasks with TDD; Claude reviews diffs + runs the suite before integrating.

---

## Phase 1 — App foundation (detailed)

Source of truth: `web/assets/css/app.css` (`@theme` + daisyUI `light` theme). Components live in `web/lib/memba_web/components/`.

### 1A. Semantic tokens
Add to the `@theme` block in `app.css` the semantic colors currently absent as utilities, so `bg-warning-soft` / `text-info` / `bg-error-soft` become real classes (today only `success` + `success-soft` exist):

- `--color-warning`, `--color-error`, `--color-info` (values already in the daisyUI theme block — reuse identically).
- `-soft` variants for all four: `success-soft` (exists), `warning-soft`, `error-soft`, `info-soft`. Values from `tokens.css`:
  `warning-soft #f3ecd8`, `error-soft #f1ddd3`, `info-soft #e3e9ec`.

**Acceptance:** `mix compile` clean; a HEEx snippet using `bg-warning-soft text-warning` produces the expected CSS (assets build succeeds). No visual regressions.

### 1B. Button
Expand `CoreComponents.button/1` to the DS `Button.ex` API while staying daisyUI-based:

- `attr :variant` ∈ `primary | secondary | ghost | danger` (default `primary`).
- `attr :size` ∈ `nil | sm | lg`.
- `attr :disabled` (boolean), existing `:rest`/navigation behavior preserved.
- Mapping: primary→`btn btn-primary`, secondary→`btn btn-soft`, ghost→`btn btn-ghost`, danger→`btn btn-error`; size→`btn-sm`/`btn-lg`.

**Acceptance:** component test asserting class output per variant/size/disabled and that `navigate`/`href` still render `<.link>`. All ~10 existing `<.button>` callers compile and render unchanged or better (default = primary).

### 1C. Status badge (consolidation — approved)
New `CoreComponents.status_badge/1` carrying the DS taxonomy, daisyUI `badge`-based:

- `attr :status` ∈ `active | trial | paused | bounced` → success / info / warning / error (soft), with a leading dot.
- Replace `AdminComponents.admin_status_chip` (tones good/info/warn/bad) — provide a tone→status shim or migrate the 9 call sites to the new status vocabulary. One status vocabulary survives.

**Acceptance:** component test for each status; all 9 admin call sites migrated; admin pages compile and render equivalent status pills; `status_chip_class/1` removed.

### 1D. Avatar (consolidation — approved)
New `CoreComponents.avatar/1`, daisyUI `avatar`-based, porting DS `Avatar.ex` logic:

- `attr :initials` (required), `attr :size` ∈ `sm | md | lg`, optional `attr :bg`.
- Background cycles deterministically through sage tints by `:erlang.phash2(initials)` (port the DS cycle).
- Migrate the 6 `AdminComponents.admin_identity_cell` avatar usages to use the shared avatar internally (`admin_identity_cell` may remain as a layout wrapper but its avatar tile uses `avatar/1` + tokens, not hardcoded hex).

**Acceptance:** component test (initials render, size classes, deterministic bg); 6 call sites migrated; `avatar_class/1` hardcoded-hex helper removed.

### Cross-cutting
- **TDD:** test first for 1B/1C/1D. Tests in `web/test/memba_web/components/`.
- **No hardcoded hex** introduced; use tokens/daisyUI classes only.
- **Validation per task:** `cd web && mix compile --warnings-as-errors` and `mix test test/memba_web/components/` (plus affected LiveView tests).
- Do **not** commit; Claude reviews and commits per task.

## Out of scope (Phase 1)
- DS preview/`.ex` changes (Phase 2).
- Email templates (Phase 3).
- The broad admin hex cleanup beyond the status/avatar consolidation (Phase 4).

## Risks
- daisyUI `btn-soft`/`badge-soft` availability — verify against the vendored daisyUI version; fall back to `btn-outline`/explicit soft classes if absent.
- LiveView tests may assert on old admin classes — update assertions as part of the migrating task.
