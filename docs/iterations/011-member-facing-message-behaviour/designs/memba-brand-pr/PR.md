# Memba brand — Phoenix + Tailwind PR

Applies the finalised **sprig** brand (sage / cream / apricot, Figtree, the
responsive sprig mark) across the Phoenix app. Because the app is daisyUI-themed,
the core change is **remapping daisyUI's semantic tokens** in `app.css` — every
existing component (`btn`, `card`, `input`, `alert`, `badge`, `navbar` …) in
`core_components.ex` and the LiveViews re-skins automatically.

## How to apply

These files mirror the repo layout under `web/`. From the repo root:

```bash
git checkout -b memba-brand
# copy the files from this package over the matching paths in web/
cp -R memba-brand-pr/web/. web/
cd web && mix phx.server   # check it at localhost:4000
```

Then commit and open the PR.

## Files

| Path | Change |
|---|---|
| `web/assets/css/app.css` | **edit** — Figtree + JetBrains `@import`; `@theme` brand utilities (`sage-*`, `cream`, `paper`, `apricot`, `ink-*`, `line-*`, `success`); daisyUI `light`/`dark` themes remapped to the sage palette; cream page background + Figtree body. |
| `web/lib/memba_web.ex` | **edit** — add `import MembaWeb.Brand` to `html_helpers/0` so `<.logo />` / `<.sprig />` work everywhere. |
| `web/lib/memba_web/components/brand.ex` | **new** — `MembaWeb.Brand`: `sprig/1` (responsive line/solid) + `logo/1` lockup. |
| `web/lib/memba_web/components/layouts.ex` | **edit** — replaces the default Phoenix landing header (Website / GitHub / Get Started + Phoenix logo) with a Memba top bar using `<.logo />`. |
| `web/lib/memba_web/components/layouts/root.html.heex` | **edit** — Figtree + JetBrains font links; sprig `favicon.svg`. |
| `web/priv/static/images/favicon.svg` | **new** — solid sprig reversed on a sage rounded square. |
| `web/priv/static/images/sprig-line.svg`, `sprig-solid.svg` | **new** — optional standalone marks for `<img>` use. |

## What re-skins automatically vs. by hand

- **Automatic** (from the token remap): buttons, inputs, cards, alerts/flash,
  badges, the navbar surface, links, focus rings — anything using daisyUI
  semantic classes. Most of `core_components.ex` and the LiveViews.
- **By hand** (already done in this PR): the landing header markup, the logo,
  the favicon, fonts.
- **Watch for**: any hard-coded Phoenix-orange or `oklch(...)` literals left in
  templates, and keep `accent` (apricot) to status only — primary actions stay
  sage.

## Notes

- `priv/static/images/logo.svg` (the Phoenix bird) is no longer referenced and
  can be deleted.
- The brand sprig's foliage is `currentColor`; colour it with a text class
  (`text-sage-600`, or `text-cream` reversed on sage). The apricot bud is fixed.
- Memba is light-first; the `dark` theme is included so the existing toggle keeps
  working. Drop the `dark` block + the dark/system buttons in `theme_toggle/1` if
  you'd rather ship light-only.
- On Tailwind v4 (this app) the brand tokens live in `app.css` `@theme` — there's
  no `tailwind.config.js` to merge.
