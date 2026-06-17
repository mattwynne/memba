# Homepage staff bar

Date: 2026-06-13
Status: done

## Goal

Bring the signed-in homepage into line with the Memba design system's staff mode by replacing the small "Memba staff" navigation button with the design's full-width staff bar, so Memba staff get a clear, branded operator-access banner that links to the staff console.

## Background / Context

Designs are iterated on the web at claude.ai/design (project `bc97cfc3-436c-471e-a939-7ba222859282`) and pulled down for implementation (see `CLAUDE.md`). A review of the current homepage against the design's homepage wireframe (`wireframes/home.html`) surfaced three inconsistencies; this iteration addresses the second:

- The design defines a **staff mode**: a signed-in member of staff sees a full-width staff bar pinned above the navigation, announcing operator access and linking to the staff console (the `.m-staffbar` component in `memba.css`).
- The current app instead shows a small "Memba staff" button in the signed-in nav (`#admin-home-link`) that links to `/admin/clubs`.

Staff detection is already solved: `@current_identity_staff?` is assigned for the homepage (`MembaWeb.IdentityAuth`), and `/admin/clubs` is the app's real staff area (iteration 021).

## Related Problems

No problem note is captured for this. It comes from the 2026-06-13 homepage/design-consistency review; this is inconsistency #2 of 3. The other two are recorded as follow-ups below.

## Scope

### In scope

- Render the design's staff bar at the top of the signed-in homepage (above `<header>`) when `@current_identity_staff?` is true.
- Show it to staff whether or not they also belong to clubs.
- Remove the existing "Memba staff" nav button (`#admin-home-link`) from the signed-in nav.
- Point the staff bar's "Open the staff console" link at `/admin/clubs`.
- Update acceptance step support so the staff-access assertion targets the new staff bar.

### Out of scope

- The design's "Staff" role chip in the nav — it depends on the avatar/name nav (inconsistency #1), which the app does not have yet.
- A site-wide staff bar (this is homepage-only).
- The unreachable duplicate `#admin-home-link` in the signed-out/visitor branch (dead code under an `if @current_identity` that is always false there) — left untouched.
- The other two homepage inconsistencies (richer signed-in club cards; request-access modal vs. separate page).

## Iteration Type

UI-facing (presentation only).

The business rule — "Memba staff can reach staff operations" — does not change. Only how the homepage presents that affordance changes: from a small nav button to the design's staff bar.

## Acceptance Scenarios / Feature Files

BDD decision: **Not required** (no new scenarios).

`acceptance-tests/features/homepage.feature` already covers the rule with two scenarios that remain unchanged:

- Rule "Memba staff can reach staff operations" → "Pat is Memba staff"
- Rule "Memba staff who are also club members can choose either path" → "Pat is staff and a club member"

Both assert "should be offered Memba staff access". Because the rule is unchanged and only the UI presentation moves, no `.feature` edits are needed — only the step support that decides how "offered staff access" is detected in the browser.

## Allowed acceptance feature changes

- No changes to any `.feature` file.
- `acceptance-tests/features/support/homepage.js` → update `assertHomepageStaffAccess` to assert the staff bar instead of the old nav button.

## Acceptance Criteria

- A signed-in member of staff sees the staff bar at the top of the homepage, above the header.
- The bar shows the "Memba staff" tag and a visible "Open the staff console" link to `/admin/clubs`.
- The bar appears for staff who have no clubs and for staff who are also club members.
- Signed-in non-staff users and signed-out visitors never see the bar.
- The old "Memba staff" nav button (`#admin-home-link`) no longer appears in the signed-in nav.
- The bar does not introduce horizontal overflow on narrow (phone) screens.
- Both `homepage.feature` staff scenarios pass with the updated step support.
- `dev check` passes.

## Product / UX Decisions

Binding for this iteration:

- Placement: first child inside `#signed-in-home`, above `<header>`.
- Copy (verbatim from the design):
  - Tag: "Memba staff"
  - Description: "You have operator access across every group on Memba."
  - Link: "Open the staff console"
- Colours follow the design: sage-700 bar with cream text; translucent-white tag and link surfaces.
- The descriptive text is hidden below the `sm` breakpoint so the bar stays tidy and does not overflow on phones; the tag and console link remain visible at all widths.
- The console link carries a trailing external-link icon (`hero-arrow-top-right-on-square-mini`).

## Implementation Plan

1. Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the existing staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
2. Update `assertHomepageStaffAccess` to assert the staff bar: `a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag. Watch the two `homepage.feature` staff scenarios fail against the current button.
3. Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
4. Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
5. Run the homepage Cucumber scenarios; confirm they pass.
6. Run `dev check`; fix any issues.
7. Visual check against the design (pull `wireframes/home.html` staff mode; confirm tag/text/link and narrow-screen behaviour).

## Technical Decisions

Binding for this iteration:

- Translate the design's `.m-staffbar` CSS to the app's existing Tailwind tokens rather than adding new CSS:
  - Bar: `bg-sage-700 text-cream`.
  - Inner: `mx-auto flex max-w-7xl items-center gap-3.5 px-6 py-2.5 lg:px-8`.
  - Tag: `rounded-full bg-white/10 px-2 py-0.5 font-mono text-[10px] font-semibold uppercase tracking-[0.06em]`.
  - Text: `hidden text-sm text-cream/80 sm:inline`.
  - Link (`id="staff-console-link"`, `href={~p"/admin/clubs"}`): `ml-auto inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/5 px-3.5 py-1.5 text-sm font-semibold transition hover:border-white/40 hover:bg-white/15`, trailing `<.icon name="hero-arrow-top-right-on-square-mini" class="size-3.5 bg-cream" />`.
- Two deliberate adaptations from the wireframe (raw-CSS standalone → routed Tailwind app):
  1. The bar's inner uses the homepage's own container width (`max-w-7xl`, `px-6`/`lg:px-8`) instead of the wireframe's `max-w-[1000px]`, so the bar aligns with the header and content below it.
  2. The console link points to `/admin/clubs` (the app's staff area) rather than the wireframe's `staff-console.html`.
- Keep the link id stable as `#staff-console-link` so the acceptance assertion has a durable selector.

## New Capability

Memba staff get a clear, on-brand operator-access banner on the homepage that matches the design, replacing the easily-missed nav button and giving a prominent path to the staff console.

## Validation Plan

- Update and run the `homepage.feature` staff scenarios (red before implementation, green after).
- Run `dev check` before completion.
- Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass to confirm no horizontal overflow.

## Risks / Follow-ups

- The design's "Staff" role chip is deferred; a later iteration should add the avatar/name nav (inconsistency #1) and then the chip.
- The other homepage inconsistencies remain as future iterations: richer signed-in club cards (latest-message preview, stats, per-group branding) and the inline request-access modal vs. the separate `/get-started` page.
- If staff mode is later wanted across the whole app, the bar should move into a shared layout rather than the homepage template.
