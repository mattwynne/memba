# 044 — Shared app-shell: app-bar + app-card frame

Date: 2026-07-04
Status: draft

> Iteration number 044 is **repurposed**. It previously held "Conversation page: align to the
> conversation wireframe", which was written against the older standalone conversation design and
> whose `fabro deliver` run failed on an infrastructure timeout (2026-06-23) and never merged. The
> design has since converged the member surfaces onto a shared app-shell, so 044 now delivers that
> shared shell. The conversation-page content alignment is re-planned as a later iteration against
> the new design (see Risks / Follow-ups). Prior plan is preserved in git history.

> Draft pending Matt's confirmation of the scope decisions under Open Business Decisions.

## Goal

Replace the shared club-site layout header with the app-like **app-bar** (club mark + club name /
club dropdown + member identity dropdown) inside an **app-card** frame, per the refreshed design
system. This is the foundation the tabbed club-home (046) and the aligned conversation page (future
iteration) both build on.

## Background / Context

The refreshed designs converged the member surfaces onto a shared app-shell — `app-frame` /
`app-card` / `app-bar` — visible in both `wireframes/club-home.html` and
`wireframes/member-conversation.html`. In the app, both the club home (`PageHTML.club`) and the
conversation page (`PageHTML.message`) render inside `Layouts.club_site`, whose current header is a
plain bar: club-name link on the left, "Signed in as {email}" + a Sign out button on the right.

Building the shell **once**, in the shared layout, is the prerequisite for gap #1 (tabbed
club-home) and gaps #4–7 (conversation-page alignment). See `docs/design-gaps-2026-07-04.md`.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** Establishes the simple, app-like shell on member surfaces.
- [`docs/problems/2026-06-07-club-homepage-no-cross-site-navigation.md`](../../problems/2026-06-07-club-homepage-no-cross-site-navigation.md)
  — **leaves unresolved.** The app-bar club dropdown is club-info, **not** a multi-club switcher;
  cross-club navigation stays deferred.
- `docs/design-gaps-2026-07-04.md` gap #1 (and a prerequisite for gaps #4–7).

## Scope

Changes the shared `Layouts.club_site` header + content frame, so the shell lands on every
club_site page (club home, conversation/message detail, empty states, member invitation, …).

### In scope

- Replace the header with the **app-bar**: club/Memba mark + club name; a **club dropdown**
  (club info); and a **member identity dropdown** (avatar + name) containing membership status +
  **Sign out**.
- Wrap page content in the **app-card** frame per the design (`app-frame` / `app-card`).
- Preserve existing behaviour: the "Powered by Memba" footer link, sign-out (same `DELETE /auth`
  form), and identity gating (member dropdown only when signed in).

### Out of scope

- Multi-club switching / navigating to other clubs from the club dropdown (cross-site-navigation
  problem stays unresolved) — the dropdown is club-info only.
- The Conversations / Members tabs (iteration 046) and the conversation-page **content** alignment
  (future iteration) — this slice only establishes the shell they sit in.
- Staff/admin layouts and the marketing/public layouts.

## Iteration Type

**Technical / UI restructure (shared layout chrome).** User-observable (new header + frame), but
**no new business rule**: sign-out, identity display, and navigation behaviour are unchanged.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule — sign-out and identity behaviour
are unchanged and already covered by the authentication scenarios. The header/frame restructure is
verified by LiveView/layout tests (app-bar renders when signed in; the sign-out control posts to
`DELETE /auth`; the member dropdown is gated on identity). No `.feature` files change; mainline
stays green.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
and [`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
— both show the `app-bar` (club mark + club dropdown + member identity dropdown) inside `app-card`.
**No new design needed.** This slice builds the shared shell; the tabs (046) and the conversation
content (future) fill it. Fast-follow: none — the design already reflects the target.

## Acceptance Criteria

- Signed-in club pages render the **app-bar**: club mark + club name, a **club dropdown**, and a
  **member identity dropdown** (avatar + name) with **Sign out**.
- **Sign out still works** from the identity dropdown (same `DELETE /auth` form/action).
- Page content renders inside the **app-card** frame; the "Powered by Memba" footer link is kept.
- Signed-out club pages do **not** show the member identity dropdown (same gating as today).
- Both the club home and the conversation/message-detail page pick up the new shell (shared layout).

## Open Business Decisions

- **Club dropdown content.** The design shows a club description + member count. Is a club
  description available to the layout? If not, scope the dropdown to member count only (or defer its
  content) for this slice.
- **Member identity dropdown content.** The design shows "Active member since {date}". If the
  membership-since date isn't readily available to the shared layout, show active-member status
  without the date.
- **Surfaces.** `club_site` is shared, so the shell lands on the club home + conversation + all
  other club_site pages at once (recommended, matches the design's consistency). Confirm that's
  intended vs scoping to specific pages.

## Implementation Plan

- `web/lib/memba_web/components/layouts.ex` → `club_site/1`: replace the header markup with the
  app-bar (mark + club name + club dropdown + member identity dropdown incl. sign-out) and wrap
  `@inner_block` in the app-card frame, using the design-system app-shell classes — mirroring
  `club-home.html` / `member-conversation.html`. Keep the footer and `flash_group`.
- Make the app-shell component CSS available to the app (the DS previews use `app-frame` /
  `app-card` / `app-bar` / `app-menu` from `memba.css`/`styles.css`; daisyUI `dropdown` is already
  available). Port the needed component classes into `web/assets/css/app.css`. [Open technical
  decision]
- Pass any needed data (member count / membership-since / club description) into the layout via the
  existing `club_site` assigns, or defer dropdown content that isn't readily available.
- Update LiveView/layout tests for the new header structure + sign-out; confirm every `club_site`
  page still renders (empty states, invitation, message detail).

## Open Technical Decisions

- **CSS source.** The DS previews use bespoke `app-bar` / `app-card` classes (plus daisyUI
  `dropdown`). Decide: port those component classes into `web/assets/css/app.css`, or re-express the
  shell with Tailwind utilities. Prefer porting the DS classes so app and design stay 1:1.

## New Capability

A shared, app-like **shell** (app-bar + app-card) across member surfaces — the foundation the
tabbed club-home and the aligned conversation page build on, so the header is built once, not per
screen.

## Validation Plan

- **Automated:** LiveView/layout tests (app-bar renders when signed in, sign-out posts to
  `DELETE /auth`, member dropdown gated on identity, every club_site page renders). `dev check`
  green (no feature changes).
- **Visual:** `./bin/dev gallery-walk`, then compare the club-home and conversation screenshots to
  `club-home.html` / `member-conversation.html` (app-bar + app-card).
- **Manual:** signed-in club home + conversation show the app-bar; dropdowns open; sign out works;
  signed-out pages hide the member dropdown.

## Risks / Follow-ups

- **Shared layout blast radius:** changing `club_site` touches every club_site page — verify empty
  states, invitation, and message-detail all still render.
- **CSS porting:** the app-shell component classes likely need adding to the app's stylesheet.
- **Iteration 046 (club-home tabs)** must be revised to build **inside** this shell (it currently
  defers the app-bar); update its plan once 044 is agreed.
- **Conversation-page content alignment** (the old 044 intent: follow toggle, collapsed delivery,
  replies-first + "Replies · N", per-reply timestamps, sent date — gaps #4–7) is **deferred to a
  future iteration**, rewritten against the new app-shell design. Those gaps remain open until then.
- **Sequencing:** 045 (stop-following) sits between 044 and 046 as `validated` (not merged); Fabro
  requires earlier-numbered iterations merged before implementing a later one.
