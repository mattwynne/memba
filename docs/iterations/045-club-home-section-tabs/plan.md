# 045 — Club home: Conversations / Members section tabs

Date: 2026-07-04
Status: implementing

> Independently decided (not bound to the prior 045/046 drafts). This repurposes the 045 slot —
> which previously held the low-value "stop-following page header" tweak — so the club-home tabs
> deliver as the next slice after the 044 app-shell. Written against the 2026-07-04 refreshed
> `club-home.html`. Prior 045 content is in git history.

## Goal

Reorganise the member club home — inside the 044 app-shell — into an app-like **section-tab
spine**: a **Conversations** tab (default) and a **Members** tab, with **one primary action per
tab**. This matches the information architecture of the refreshed `design-system/wireframes/club-home.html`.

## Background / Context

The refreshed club home is an app-like tabbed screen; the running app
(`page_html/club.html.heex` via `MemberDashboardLive`) is still a single scrolling column — a
hero greeting, a "Send a message to the club?" affordance, a club-messages list, then a members
section. Iteration 044 lands the shared **app-bar + app-card shell** around this content; this
slice fills that shell with the tab spine.

The design's third tab — **About** — shows a prose club description. **The app has no club
description field** (a grep across the club/messaging domain finds none), so the About tab is
**deferred** to a later slice that first adds a club-description capability. Because the app never
had a description, 044 removing the old club dropdown lost no real data.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** Establishes the simple, app-like tabbed IA on the club home.
- [`docs/problems/2026-06-07-club-homepage-no-cross-site-navigation.md`](../../problems/2026-06-07-club-homepage-no-cross-site-navigation.md)
  — **leaves unresolved.** No club switcher; the design's app-bar switcher was already removed in 044.

## Scope

The member club home (`MemberDashboardLive` / `PageHTML.club`) only, rendered inside the 044 shell.

### In scope

- A **section-tab spine** with two tabs: **Conversations** (selected by default) and **Members**.
- A per-tab **action slot** with one primary action each: **New message** on Conversations, and
  **Invite member** on Members (shown only when the viewer can manage members — current gating).
- **Conversations panel:** today's conversation rows and existing empty state, plus the preserved
  "Prefer email? → everyone@<club>…" inbound-email affordance.
- **Members panel:** today's members content (the avatar-stack card), unchanged.
- Client-side tab switching (`Phoenix.LiveView.JS`, no server round-trip), accessible
  (`role="tablist"`/`"tab"`, `aria-selected`), defaulting to Conversations.
- Drop the single-scroll hero greeting ("Hello, {first name}.") — member/club identity now lives
  in the 044 app-bar, matching the design (which has no in-card greeting).

### Out of scope

- The **About** tab (deferred — needs a club-description field the app does not yet have).
- The app-bar / identity dropdown (delivered by 044).
- Named member rows + role badges (the later member-roles slice; needs role read-model data).
- Any change to conversation-row content, member content, compose behaviour, or permissions.
- A mobile-specific redesign, and an Events tab (design keeps it commented as future).

## Iteration Type

**Technical / UI restructure (information architecture).** User-observable (content moves into
tabs; one primary action per section), but **no new business rule**: same content, same actions,
same permissions.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule, permission, lifecycle, or
eligibility is introduced — this is a presentational IA reorganisation of existing behaviour,
already covered by existing shared scenarios (club messaging/replies; member invitations and
manage-members gating). The tab reorganisation is verified by LiveView/controller tests, not by a
new stakeholder-readable rule. No `.feature` files change; mainline stays green.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
(refreshed 2026-07-04). This slice implements a **subset**: the `section-tabs` spine
(Conversations / Members), the `section-tabs__action` per-tab action slot, and the two
`section-panel`s reusing existing content. **Intentionally omitted:** the **About** tab (deferred)
and named member rows + role badges (later slice). **No new design needed.**

## Acceptance Criteria

- The club home shows a tab spine with **Conversations** and **Members**; **Conversations is
  selected by default**.
- Selecting a tab shows that panel and hides the other **without a full page navigation**, and
  updates the active-tab styling and `aria-selected`.
- The **Conversations** tab shows a single primary **New message** action that opens the existing
  compose flow (`member_compose_path`).
- The **Conversations** panel shows today's conversation rows (or the existing empty state) and
  preserves the **"Prefer email? → everyone@<club>…"** inbound-email affordance.
- The **Members** tab shows a single primary **Invite member** action, **visible only when the
  current member can manage members** (same gating as today), plus the existing members content.
- **No change** to who receives a club message, who appears in the member list, or who can invite.
- Tabs are keyboard- and screen-reader-operable (`role="tablist"`/`"tab"`, `aria-selected`).

## Open Business Decisions

None open. **About tab deferred** (confirmed — no club-description data yet). **Hero greeting
dropped** (the 044 app-bar carries identity, matching the design).

## Implementation Plan

1. In `web/lib/memba_web/controllers/page_html/club.html.heex`, remove the `#member-dashboard-hero`
   greeting section; club/member identity now lives in the 044 app-bar.
2. Add a `section-tabs` spine with `role="tablist"` holding two `section-tab` controls:
   Conversations (default, `is-active`, `aria-selected="true"`) and Members.
3. Add a `section-tabs__action` slot with a per-tab primary **New message** action on Conversations,
   linking to `member_compose_path(@selected_club, club_id_source)`.
4. In the same action slot, add the **Invite member** action linking to `member_invitation_path`,
   rendered only when `@current_member_can_manage_members?` (hidden otherwise).
5. Wrap today's conversation list and its existing empty state in a Conversations `section-panel`
   that is visible by default; keep the `@message_rows` rows unchanged.
6. Move the "Prefer email? → `{inbound_email_address}`" note into the Conversations panel, keeping
   its `mailto:` affordance and `data-inbound-address` hook.
7. Wrap today's members content (avatar stack + count, invite gating) in a Members `section-panel`
   that is hidden by default.
8. Port the `section-tabs`, `section-tab`, `section-tabs__action`, and `section-panel` CSS from
   `design-system/` (`memba.css` / `styles.css`) into `web/assets/css/app.css`, names 1:1.
9. Wire client-side tab switching with `Phoenix.LiveView.JS` (`JS.show`/`JS.hide` panels; toggle
   `is-active` and `aria-selected`), defaulting to Conversations, with no server round-trip.
10. Update the LiveView/controller test: both tab controls render; Conversations is the default
    panel; the New message action is on Conversations; Invite member is on Members only when
    manage-members is allowed; both panels' content renders.
11. Run `./bin/dev gallery-walk` and compare `member-club-home` to
    `design-system/wireframes/club-home.html` (tab spine + per-tab action + panels).
12. Run `dev check` and confirm it is green (no feature-file changes).

## Open Technical Decisions

- **Tab switching mechanism: decided — `Phoenix.LiveView.JS`** client commands (instant, stateless),
  matching the design's client-side toggle. Fall back to a LiveView active-tab assign only if the
  JS approach conflicts with existing hooks.

## New Capability

The club home presents its content as an app-like **tabbed interface** (Conversations / Members)
with one primary action per section — the IA pattern the rest of the app-like redesign builds on.

## Validation Plan

- **Automated:** the LiveView/controller test above; `dev check` green (no feature-file changes).
- **Visual:** `./bin/dev gallery-walk`, then compare the `member-club-home` screenshot to
  `design-system/wireframes/club-home.html` (tab spine + per-tab action + panels).
- **Manual:** load the club home inside the 044 shell; toggle Conversations/Members; confirm the
  New message / Invite member actions, the preserved email affordance, and keyboard/`aria` behaviour.

## Risks / Follow-ups

- Depends on **044** (the app-shell) being merged first — this slice renders inside it.
- The Members panel shows the avatar-stack (not named rows/role badges) — intentional; reconciled
  in the **member-roles** slice (needs role read-model data).
- The **About** tab is deferred until a **club-description** capability exists (its own slice).
- Follow-on sequencing (my own): 046 conversation-page alignment → 047 delivery-details page +
  relocation → 048 member names + role badges.
