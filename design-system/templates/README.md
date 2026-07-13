# Templates

Full, polished, page-level reference screens — one per real Memba route or flow.

This mirrors the cloud project's `templates/` category exactly (`claude.ai/design`,
project `bc97cfc3-436c-471e-a939-7ba222859282`). In that tool, "Templates" are
**High Fidelity** starting points: built against the design system's real tokens
and brand assets, not rough sketches. The cloud project's own `CLAUDE.md` puts it
plainly:

> Templates (`templates/*`) are visual specs / reference — a dev reads them and
> builds the matching HEEx component. The HTML is the spec, not the delivered code.

## What belongs here

- A full page (or a small bundle of closely related states/variants of one page —
  see `check-email-delivery-progress.html`'s five progress states, or
  `profile-completion.html`'s success/validation-error pair) tied to a specific
  route.
- Built from the shared component vocabulary in `styles.css` (`.app-frame`,
  `.app-card`, `.app-bar`, `.app-menu`, `.app-foot`, etc.) plus page-local CSS for
  anything genuinely specific to that screen.
- Annotated `@dsCard` (preview-gallery card) and `@template` (this category) on
  the first two lines — see any existing file for the exact format.

## What doesn't

- A single reusable UI piece with no page context (a badge, a button, an avatar) —
  that's `../components/`.
- A rough, low-fidelity sketch exploring an idea before it's decided — that's
  `../wireframes/`, though in practice this project has stopped adding new work
  there (see that folder's README).
- Design tokens, brand voice, or spacing/motion standards — that's `../guidelines/`.

## Local vs cloud layout

The cloud stores each template in its own folder (`templates/<slug>/<file>.html`
plus a generated `.thumbnail`). Locally we flatten that to a single file per
template — `templates/<slug>.html` — since the per-screen folder and thumbnail
add nothing in git. When pushing to the cloud, map local `templates/<slug>.html`
→ cloud `templates/<slug>/<slug>.html` (or `index.html`, matching that screen's
existing cloud filename — check with `DesignSync get_file` if unsure).
