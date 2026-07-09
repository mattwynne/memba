# Problems

## The club home design has an "About" tab; the app has no club description data or panel at all

Observed: 2026-07-09

Status: Unresolved. No iteration yet.

`design-system/wireframes/club-home.html` shows three club-home tabs — Conversations, Members,
and **About** — with the About panel showing free-text club description copy ("We're a group of
142 folks based out of Nelson, BC, who love getting into the Selkirks and Purcells together...").
The design's comment notes this is "club identity that used to hide inside the club-name
dropdown."

The app (`club.html.heex`, `router.ex`) only has two tabs — Conversations and Members. There is no
About route, panel, or data: `Membership.Projections.Club` has no description/about field
anywhere. This isn't a rendering gap that a template change could close; the data doesn't exist.

Why it matters:

- It's a checked-in tab in the canonical design that doesn't exist in the app at all — the kind of
  gap a design-vs-app comparison should catch and a casual glance at the running app would miss,
  since nothing today claims to show it.
- Closing it needs product decisions first: where the description copy comes from (staff-entered?
  club-admin-entered? migrated from onboarding request notes?), who can edit it, and whether it's
  club-facing only or also shown on the public club page.

Expected:

- A product decision on the copy's source and editing permissions.
- A description/about field on the club (or membership-admin-owned) data model.
- An About tab/panel in the club-home section-tabs matching the design, added as its own iteration
  once the above is decided.
