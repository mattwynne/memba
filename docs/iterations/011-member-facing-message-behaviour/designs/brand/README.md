# Memba brand — engineering handoff

The finalised **sprig** mark, plus everything to wire it into a Phoenix + Tailwind app.

## Files in this folder

- `sprig-line.svg` — the line mark (display sizes, 28px+). Fixed sage + apricot bud; works as `<img>`.
- `sprig-solid.svg` — the solid mark (small sizes, ≤24px). Fixed sage + apricot bud.
- `favicon.svg` — solid sprig reversed on a sage rounded square. For the browser tab / app icon.
- `memba_brand.ex` — `MembaWeb.Brand` HEEx component (`sprig/1` + `logo/1`). Foliage uses `currentColor` so you colour it with a Tailwind text class; the bud stays apricot.
- `tailwind.memba.js` — the brand colour + font + radius tokens to merge into `theme.extend`.

## The responsive rule

One mark, two weights — same silhouette, so the swap is invisible:

- **Line** sprig at **28px and up** — nav, marketing, headers, large lockups.
- **Solid** sprig at **24px and down** — favicon, app icon, dense table rows, browser tab.

## Integration (Phoenix 1.7, Tailwind v3)

1. **Tokens** — merge `tailwind.memba.js` into `assets/tailwind.config.js` under `theme.extend`. You get `sage-50…800`, `cream`, `paper`, `apricot`, `ink`/`ink-2`/`ink-3`, `line`/`line-strong`, `success`, plus `font-sans: Figtree` and `rounded-btn/card/modal`.

2. **Font** — add Figtree in `root.html.heex` `<head>`:
   ```heex
   <link rel="preconnect" href="https://fonts.googleapis.com" />
   <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
   <link href="https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700&display=swap" rel="stylesheet" />
   ```
   (Or self-host into `priv/static/fonts` and `@font-face` it.)

3. **Component** — drop `memba_brand.ex` at `lib/memba_web/components/brand.ex`. `import MembaWeb.Brand` in the `html_helpers/0` block of `lib/memba_web.ex` to use `<.logo />` and `<.sprig />` anywhere.

4. **Favicon** — copy `favicon.svg` to `priv/static/images/favicon.svg`, then in `root.html.heex`:
   ```heex
   <link rel="icon" href={~p"/images/favicon.svg"} type="image/svg+xml" />
   ```
   Make sure `images` is in `static_paths/0` (`lib/memba_web.ex`) — it is by default.

## Usage

```heex
<.logo />                                       <%# nav lockup: line sprig + “memba” %>
<.sprig variant={:solid} class="h-5 w-5 text-cream" />   <%# dense / reversed %>
<.sprig class="h-8 w-8 text-sage-600" />        <%# any display size %>
```

## Tailwind v4 (Phoenix 1.8)

If you're on the CSS-first build, skip `tailwind.config.js` and put the tokens in `assets/css/app.css`:

```css
@import "tailwindcss";
@theme {
  --color-sage-500: #5a7050;
  --color-sage-600: #475a40;
  --color-cream: #f6f5ea;
  --color-paper: #fffef9;
  --color-apricot: #d2925a;
  --color-ink: #25291d;
  --color-line: #e8e6d4;
  --font-sans: "Figtree", ui-sans-serif, system-ui, sans-serif;
}
```
