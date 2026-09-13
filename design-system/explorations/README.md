# Explorations

Interactive or exploratory design artefacts that are not a single route's spec.

This mirrors the cloud project's `explorations/` category (the cloud already holds
`explorations/global-app-bar.html`, read on demand — see `.design-sync/NOTES.md`,
2026-07-16). Locally this folder was created on 2026-09-12 for the custom-club-groups
prototype; it was **not** verified against the cloud's current `explorations/` listing
because DesignSync could not authenticate in that session. The reviewed local
HTML is sufficient for iterations 061–065; inspect cloud changes before any future sync.

## What belongs here

- Click-through prototypes stitched from the templates, with mocked in-page data and
  prototype-only JS (`custom-groups-prototype.html`). They exist so a flow can be *felt*
  end to end; the per-route specs stay in `../templates/`.
- Side-by-side option explorations for a design decision that hasn't been made.
- A local `index.html` map when a piece of work spans several files.

## What doesn't

- Anything tied to one real route and ready as a dev spec — `../templates/`.
- Reusable single pieces — `../components/`. Tokens and standards — `../guidelines/`.

Prototype scripts are never a reference for the app: member surfaces are LiveView with
URL-addressable state (ADR 0015 / 0023).
