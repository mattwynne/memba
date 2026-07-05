# 044 — Shared member app-shell: app-bar + app-card frame

Date: 2026-07-04
Status: implementing

> This plan **replaces** the earlier 044 draft (and is decided independently of the 044/045/046
> drafts). It is written against the **2026-07-04 refreshed** design mirror, in which the in-club
> app-bar was simplified: it no longer carries a Memba mark or a club dropdown — just the plain
> club name on the left and the member identity dropdown on the right. Prior 044 drafts are in git
> history.

## Goal

Replace the plain shared club-site header with the app-like **app-bar** inside an **app-card**
frame, matching the refreshed design system, so every member-facing club surface reads as one
consistent application shell. This is the foundation the tabbed club home and the aligned
conversation page build on.

## Background / Context

The refreshed designs converged the member surfaces onto a shared shell — `app-frame` /
`app-card` / `app-bar` — visible in both `design-system/wireframes/club-home.html` and
`design-system/wireframes/member-conversation.html`. Today the app renders every club surface
inside `Layouts.club_site`, whose header is a plain bar: a club-name link on the left and
"Signed in as {email}" + a Sign out button on the right (`web/lib/memba_web/components/layouts.ex`).
There is no app-bar, no app-card frame, and none of the shell CSS exists in the app yet
(`grep` for `app-bar`/`app-card` in `web/assets` and `web/lib` returns nothing).

Building the shell **once** in the shared layout lands it on all six `club_site` surfaces at
once (club home, conversation/message detail, compose, member invitation, and the public club
page) and is the prerequisite for the club-home tabs and the conversation-page content alignment.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** Establishes the simple, consistent, app-like shell across member
  surfaces. The full app-like treatment (tabs, mobile) remains later slices.
- [`docs/problems/2026-06-07-club-homepage-no-cross-site-navigation.md`](../../problems/2026-06-07-club-homepage-no-cross-site-navigation.md)
  — **leaves unresolved.** The refreshed design removed the club dropdown entirely, so there is no
  club switcher in this slice; cross-club navigation stays deferred.

## Scope

Changes the shared `Layouts.club_site` header + content frame, so the shell lands on every
`club_site` page.

### In scope

- Replace the header with the **app-bar**: the **plain club name** on the left, and a **member
  identity dropdown** (avatar initials + member name, opening to **Sign out**) on the right.
- Wrap page content in the **app-card** frame (`app-frame` / `app-card`) per the design.
- Port the needed app-shell component CSS (`app-frame`, `app-card`, `app-bar`, `app-menu`, and the
  identity dropdown pieces) from the design system into the app stylesheet, so app and design stay
  1:1. daisyUI `dropdown` is already available in the app.
- Preserve existing behaviour exactly: the "Powered by Memba" footer link, sign-out (same
  `DELETE /auth` form/action), and identity gating (identity dropdown only when signed in).

### Out of scope

- The Conversations / Members / **About** tab spine on the club home (later slice).
- The conversation-page **content** alignment (compact delivery, follow toggle, replies-first,
  timestamps — later slice).
- Any club dropdown / club switcher / Memba mark in the app-bar (removed by the refreshed design;
  cross-site-navigation problem stays unresolved).
- Membership-status detail in the identity dropdown (the refreshed club-home shows Sign out only;
  status is deferred).
- Staff/admin layouts and the marketing/public marketing layouts.
- Any change to compose, invitation, conversation, or sign-out **behaviour**.

## Iteration Type

**Technical / UI restructure (shared layout chrome).** User-observable (new header + framed
content), but **no new business rule**: sign-out, identity display, and navigation behaviour are
unchanged.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule, permission, or lifecycle state
is introduced. Sign-out and identity behaviour are unchanged and already covered by the
authentication scenarios. The header/frame restructure is verified by LiveView/layout tests
(app-bar renders with the club name; the identity dropdown appears only when signed in and
contains a Sign out control that posts to `DELETE /auth`; content renders inside the app-card;
every `club_site` surface still renders). No `.feature` files change; mainline stays green.

## Designs

**Design of record:**
[`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html) and
[`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
(refreshed 2026-07-04) — both show the simplified `app-bar` (plain club name + member identity
dropdown) inside the `app-card` frame, with the "Powered by Memba" `app-foot`.

**No new design needed.** This slice builds the shared shell those screens already specify; the
tabs and the conversation content fill it in later slices. Fast-follow: none — the design already
reflects the target shell.

## Acceptance Criteria

- Signed-in club pages render the **app-bar**: the plain **club name** on the left, and a **member
  identity dropdown** (avatar initials + member name) on the right.
- The identity dropdown opens to a **Sign out** control that still posts to `DELETE /auth` (same
  form/action as today).
- Signed-out club pages (e.g. the public club page) render the app-bar **without** the identity
  dropdown (same gating as today's `:if={@current_identity}` nav).
- Page content renders inside the **app-card** frame, and the **"Powered by Memba"** footer link
  is preserved (same href/behaviour).
- All six `club_site` surfaces still render correctly under the new shell: club home,
  conversation/message detail, compose, member invitation, and the public club page.
- No club dropdown, club switcher, or Memba mark appears in the app-bar (matches the refreshed
  design).

## Open Business Decisions

None known. The refreshed design resolved the earlier open questions: the app-bar carries no club
dropdown or mark (removed), and the club-home identity dropdown is Sign out only (membership-status
detail deferred).

## Implementation Plan

1. Port the app-shell CSS classes (`app-frame`, `app-card`, `app-bar` and its children, `app-menu`,
   `app-foot`) verbatim from `design-system/` (`memba.css` / `styles.css`) into
   `web/assets/css/app.css`, keeping names 1:1 with the mirror (daisyUI `dropdown` already exists).
2. In `Layouts.club_site/1` (`web/lib/memba_web/components/layouts.ex`), replace the header's
   left side with the app-bar showing the plain `@club_name`.
3. In the same app-bar, add the right-side member identity dropdown (avatar initials + member
   name), gated with `:if={@current_identity}` so it only renders when signed in.
4. Make the identity dropdown open to a **Sign out** control that posts to the same `DELETE /auth`
   form/action as today (unchanged behaviour).
5. Wrap `@inner_block` in the `app-frame` / `app-card` frame; keep the existing "Powered by Memba"
   `app-foot` footer and the `flash_group`.
6. Add an optional `member_name` assign (default `nil`) to `club_site`, and a private
   `Layouts.initials/1` helper that derives avatar initials from a name.
7. Render the identity dropdown's avatar + label from `member_name`, falling back to the
   `current_identity` email local-part (label and initials) when `member_name` is `nil`.
8. Pass `member_name` (current member display name) into `club_site` from `page_html/club.html.heex`
   and `page_html/message.html.heex`.
9. Pass `member_name` into `club_site` from `member_message_live/new.ex` (compose) and
   `member_invitation_live/new.ex` (invitation).
10. Leave `public_club_page_live.ex` passing neither `current_identity` nor `member_name`, so the
    signed-out public page keeps the identity dropdown gated off.
11. Update LiveView/layout tests: app-bar renders `@club_name`; identity dropdown gated on
    `@current_identity`; Sign out posts to `DELETE /auth`; content sits in the app-card.
12. Add/adjust a test that every `club_site` surface still renders under the new shell (club home,
    conversation, compose, invitation, public club page).
13. Run `./bin/dev gallery-walk` and compare the club-home and conversation screenshots to
    `design-system/wireframes/club-home.html` / `member-conversation.html`.
14. Run `dev check` and confirm it is green (no feature-file changes).

## Open Technical Decisions

None open — both prior technical questions are decided in the Implementation Plan:

- **CSS source: decided — port the DS component classes** (`app-frame`, `app-card`, `app-bar` &
  children, `app-menu`, `app-foot`, identity-dropdown pieces) verbatim from `design-system/`
  (`memba.css` / `styles.css`) into `web/assets/css/app.css`, keeping class names 1:1 with the
  design mirror rather than re-expressing the shell in Tailwind utilities. This keeps the design
  mirror authoritative and the app pixel-faithful.
- **Identity name/initials plumbing: decided — a new optional `member_name` assign** on
  `club_site`, passed by the four signed-in member surfaces, with an email-local-part fallback and
  a `Layouts.initials/1` helper for the avatar. The signed-out public page supplies neither
  identity nor name (dropdown gated off).

## New Capability

A shared, app-like **shell** (app-bar + app-card) across every member surface — built once in the
shared layout — so the club-home tabs and the aligned conversation page can be built inside a
consistent frame instead of each screen re-inventing its own header.

## Validation Plan

- **Automated:** LiveView/layout tests (app-bar renders the club name; identity dropdown gated on
  identity; Sign out posts to `DELETE /auth`; app-card wraps content; every `club_site` surface
  renders). `dev check` green (no feature-file changes).
- **Visual:** `./bin/dev gallery-walk`, then compare the club-home and conversation screenshots to
  `design-system/wireframes/club-home.html` / `member-conversation.html` (app-bar + app-card + the
  "Powered by Memba" foot).
- **Manual:** signed-in club home + conversation show the app-bar; the identity dropdown opens and
  Sign out works; the public club page shows the app-bar with no identity dropdown.

## Risks / Follow-ups

- **Shared-layout blast radius:** changing `club_site` touches all six surfaces — verify the public
  club page (signed out), compose, invitation, and message detail all still render.
- **CSS porting:** the app-shell component classes must be added to the app stylesheet; keep them
  named 1:1 with the design mirror.
- **Follow-on slices (my own sequencing, not bound to the old 044/045/046 drafts):** (1) club-home
  Conversations / Members / **About** tabs inside this shell; (2) conversation-page content
  alignment (compact delivery, follow toggle, replies-first + "Replies · N", message timestamps);
  (3) member names + role badges (needs role data in the read model). Each is its own later slice.
- **Numbering:** delivered as iteration 044 so Fabro's "earlier iterations merged first" rule is
  satisfied (001–043 are merged). The unmerged 045/046 drafts are left untouched and will be
  re-decided when their turn comes.
