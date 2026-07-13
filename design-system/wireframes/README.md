# Wireframes

Low-fidelity, phone-form-factor screens only. In Claude Design, "Wireframe" is a
distinct fidelity level from "High Fidelity": rough sketches for exploring an idea
fast, without the design system's real brand assets applied. "Templates" (see
`../templates/`) are the High Fidelity counterpart — built on the real tokens,
meant to be handed to a dev as a spec.

## What's actually here

Only the mobile-viewport screens, mirroring the cloud project's `wireframes/`
folder exactly (`claude.ai/design`, project `bc97cfc3-436c-471e-a939-7ba222859282`):

- `mobile-club-home.html`, `mobile-compose.html`, `mobile-message-detail.html`
- `mobile.css` — the shared stylesheet every mobile file above links

That's it — four files. The cloud folder also lists a fifth, `image-slot.js`, but
that's generic Claude Design canvas-runtime scaffolding (an image-drop-placeholder
web component, tagged `@ds-adherence-ignore -- omelette starter scaffold`) — not
Memba design content, and none of these three wireframes reference it. Not worth
mirroring locally.

## Why so little

This folder isn't a general "drafts" staging area — don't drop new full-page
work here just because it feels early-stage. Historically this project's cloud
`wireframes/` folder held much more (staff console, member messaging screens)
before those were rebuilt as proper `templates/` entries; what's left is
specifically the not-yet-promoted mobile set. New full-page mockups, even rough
first passes, belong in `../templates/` — that's where "most of the new stuff"
in the cloud project actually lives.

## Local vs cloud layout

Unlike `templates/`, these files are flat in the cloud too (no per-screen
subfolder), so the local and cloud paths already match 1:1 — no flattening
translation needed here.
