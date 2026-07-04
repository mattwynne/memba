# 046 — Club home: Conversations / Members section tabs

Date: 2026-07-04
Status: draft

> Draft pending Matt's confirmation of one open business decision (compose CTA + inbound-email
> note placement — see Open Business Decisions). Everything else is settled.

## Goal

Reorganise the member club home into an app-like **section-tab spine** — a **Conversations**
tab (default) and a **Members** tab — with **one primary action per tab**, matching the
information architecture of the refreshed design `wireframes/club-home.html`. This is the first
slice of the larger "app-like club home" direction; it establishes the tab pattern only.

## Background / Context

The refreshed design system moved the club home to an app-like tabbed interface (top app-bar
with a club switcher, a Conversations / Members tab spine, one primary action per section). The
running app is still a single scrolling page: hero greeting, a big "Send a message to the club?"
CTA card, a "Recent club messages" list, then a members card. See
`docs/design-gaps-2026-07-04.md` gap #1.

Because the full design is several slices, this iteration takes only the **tab structure**:
reorganise today's existing content into two tabs with a per-tab action slot. It deliberately
defers the top app-bar/club-switcher and the named member rows + role badges to later slices.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** Establishes the simple, app-like tabbed IA on the club home;
  mobile app-like treatment and the full desktop chrome remain future slices.
- [`docs/problems/2026-06-07-club-homepage-no-cross-site-navigation.md`](../../problems/2026-06-07-club-homepage-no-cross-site-navigation.md)
  — **leaves unresolved.** The design's top app-bar club-switcher (signed-in club switching) is
  explicitly deferred out of this slice.
- `docs/design-gaps-2026-07-04.md` gap #1 — **partially addresses** (tab structure only;
  app-bar/club-switcher and Members role badges deferred).

## Scope

### In scope

The member club home (`MemberDashboardLive` / `PageHTML.club`) only:

- A **section-tab spine** with two tabs: **Conversations** (selected by default) and **Members**.
- A consistent **action slot** with one primary action per tab: **New message** on Conversations,
  **Invite member** on Members (shown only when the viewer can manage members — current gating).
- **Conversations panel:** today's conversation rows and existing empty state, plus the preserved
  "Prefer email? → everyone@<club>…" inbound-email affordance.
- **Members panel:** today's members content (the avatar-stack card), unchanged.
- Client-side tab switching (no full page reload), accessible (`role="tablist"`/`"tab"`,
  `aria-selected`), defaulting to Conversations.

### Out of scope

- The top app-bar / club-switcher dropdown / member identity dropdown (later slice).
- Named member rows + role badges in the Members panel (member-roles slice; needs a role
  read-model join).
- Any change to conversation-row content, member content, compose behaviour, or permissions.
- A mobile-specific redesign (the mobile club-home design is itself stale — separate design-first
  work).
- An Events tab (the design keeps it commented out as future).

## Iteration Type

**Technical / UI restructure (information architecture).** The change is user-observable
(navigation moves to tabs; the members list now lives behind a Members tab; one primary action
per section), but it introduces **no new business rule**: the same content, the same actions,
and the same permissions. A club message still goes to all current members; the member list shows
the same people; invite is gated exactly as today.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule, permission, lifecycle, or
eligibility is introduced — this is a presentational IA reorganisation of existing behaviour.
The underlying behaviours are unchanged and already covered by existing shared scenarios:

- Sending a club message and replies — `club_message_replies.feature`,
  `member_message_deliverability.feature`.
- Inviting members and manage-members gating — `club_member_invitations.feature`,
  `club_membership_administration.feature`.

The tab reorganisation (both tabs render, Conversations is the default panel, one action per tab,
invite-action gating, both panels' content present) is verified by LiveView/controller tests, not
by a new stakeholder-readable rule. No `.feature` files are added or changed, so the mainline
stays green.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
(refreshed 2026-07-04), which specifies the full tabbed shell. This slice implements a **subset**
of that final design:

- Implemented now: the `section-tabs` spine (Conversations / Members), the `section-tabs__action`
  per-tab action slot, and the two `section-panel`s reusing existing content.
- **Intentionally omitted this slice** (later slices): the top app-bar with club-switcher +
  member identity dropdown, and the named member rows + role badges inside the Members panel.

**No new design needed.** The final design already exists; this slice references it and omits the
deferred elements. Fast-follow: reconcile the club home to the full design once the app-bar and
member-roles slices land.

## Acceptance Criteria

- The member club home shows a tab spine with **Conversations** and **Members**; **Conversations
  is selected by default**.
- Selecting a tab shows that panel and hides the other **without a full page navigation**, and
  updates the active-tab styling and `aria-selected`.
- The **Conversations** tab shows a single primary **New message** action that opens the existing
  compose flow (`member_compose_path`).
- The **Conversations** panel shows today's conversation rows (or the existing empty state) and
  preserves the **"Prefer email? → everyone@<club>…"** inbound-email affordance.
- The **Members** tab shows a single primary **Invite member** action, **visible only when the
  current member can manage members** (same gating as today), plus the existing members content.
- **No change** to who receives a club message, who appears in the member list, or who can invite.
- Tabs are keyboard- and screen-reader-operable (`role="tablist"`/`"tab"`, `aria-selected`),
  matching the design's markup intent.

## Open Business Decisions

- **Compose CTA + inbound-email note (recommended default, pending Matt).** Replace the big green
  "Send a message to the club?" CTA card with the compact **New message** tab action, while
  **preserving** the "Prefer email? → everyone@<club>…" note on the Conversations panel — removing
  it would regress the intentional, tested send-by-email path (problem 2026-06-02). Alternatives:
  (b) drop the email note to match the design exactly, or (c) keep the full CTA card inside the
  Conversations panel.
- **Hero greeting.** Keep "Hello, {first name}." above the tabs for now (the app-bar that would
  otherwise carry identity is deferred), or drop it. Default: **keep**.

## Implementation Plan

- `web/lib/memba_web/controllers/page_html/club.html.heex`: wrap the body in a section-tab spine
  (tablist: Conversations / Members) + an action slot + two `section-panel`s. Move the conversation
  list into the Conversations panel and the members card into the Members panel. Replace the CTA
  card with the compact **New message** action and relocate the inbound-email note onto the
  Conversations panel.
- Tab switching: use `Phoenix.LiveView.JS` client commands (`JS.show`/`JS.hide`/`JS.set_attribute`
  for `aria-selected` + active styling) so switching is instant and requires no server round-trip
  or new LiveView state — matching the design's client-side toggle.
- Reuse existing bindings/helpers: `member_compose_path`, `member_invitation_path`,
  `@current_member_can_manage_members?`, `@message_rows`, `@members`, `inbound_email_address`,
  and the existing empty states.
- Add/adjust a LiveView/controller test asserting: both tab controls render; Conversations panel
  is the default; the **New message** action is present on Conversations; the **Invite member**
  action is present on Members only when manage-members is allowed; both panels' content renders.
- **No** presentation-module, schema, event, or command changes.

## Open Technical Decisions

- **Tab switching mechanism:** `Phoenix.LiveView.JS` client commands (recommended — instant,
  stateless) vs a server-side active-tab assign. Confirm the JS approach fits the app's existing
  hooks/JS conventions; fall back to a LiveView assign if not.

## New Capability

The club home presents its content as an app-like **tabbed interface** (Conversations / Members)
with one primary action per section — the IA pattern the rest of the app-like redesign builds on.

## Validation Plan

- **Automated:** the LiveView/controller test above (tab controls, default panel, per-tab actions,
  invite gating, panel content). `dev check` stays green (no feature-file changes).
- **Visual:** `./bin/dev gallery-walk`, then compare the `member-club-home` screenshot against
  `design-system/wireframes/club-home.html` (tab spine + per-tab action + panels).
- **Manual:** load the club home; toggle Conversations/Members; confirm **New message** /
  **Invite member** actions, the preserved email affordance, and keyboard/`aria` behaviour.

## Risks / Follow-ups

- The Members panel still shows the avatar-stack (not named rows/badges) — intentional; reconciled
  in the **member-roles** slice (gap #2).
- No app-bar/club-switcher yet — the hero greeting is a temporary stand-in for club/member
  identity; reconciled in the **app-bar** slice (and ties to the cross-site-navigation problem).
- Long member lists (e.g. 142 rows) are avoided for now by deferring named rows.
- Keep existing acceptance scenarios green (no feature changes).
