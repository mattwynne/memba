# 048 — Club home Members: named member rows

Date: 2026-07-04
Status: validated

> Written 2026-07-04 against the refreshed `club-home.html` Members panel. Delivers after 044–047 in
> number order; builds inside the 045 Members tab.

## Goal

Replace the club-home Members panel's avatar-stack card with **named member rows** (avatar + name +
meta, current member marked "You"), matching the Members tab in `design-system/wireframes/club-home.html`.
Role badges are a separate slice (**049**) that needs a product decision on which roles display.

## Background / Context

Today the club home shows members as an avatar stack + count ("142 members"); names live only in
avatar tooltips. The refreshed design's Members tab shows a `member-list` of named `member-row`s.
Iteration 045 introduced the Members tab/panel; this slice fills it with named rows. The member
names/initials already flow to the view via `MemberDashboardPresentation` (`@members`).

The design's rows also carry **role badges** (Chair / Secretary / Treasurer / Trip organizer). The
domain has a roles framework (`Membership.Roles`, role assignments, `membership_roles`), but the
only seeded role today is the internal "Membership Administrator" permission role — so **which roles
surface as public member badges is a product decision**, split out to **049**. This slice ships the
named rows only.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** The Members tab becomes a real, legible list ("people, not avatars").

## Scope

The club home Members panel (`page_html/club.html.heex` / `MemberDashboardPresentation`) only.

### In scope

- Replace the avatar-stack card with a **`member-list` of named `member-row`s** (avatar initials +
  name + meta), matching the design.
- Mark the **current member's** row (a "You" indicator in the meta).
- Keep the existing **Invite member** action (from 045) and the members empty state.

### Out of scope

- **Role badges** (Chair / Secretary / … ) — the later **049** slice, pending the product decision
  on which roles display.
- A "member since {date}" meta value, unless that date already flows to the view (see Open
  Technical Decisions).
- Conversation/club-message content, permissions, and the other tabs.

## Iteration Type

**Technical / UI restructure (presentation).** User-observable (avatar stack → named rows), but
**no new business rule**: same members, same data, same permissions.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule or permission — this re-presents
the existing member list, already covered by the membership/invitation scenarios. Verified by
LiveView/controller tests. No `.feature` files change; mainline stays green.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
Members panel (`member-list` / `member-row`). This slice implements the named rows and omits the
**role badges** (deferred to 049). **No new design needed.**

## Acceptance Criteria

- The Members tab shows a **list of named member rows** (avatar initials + name), one per member,
  instead of the avatar-stack card.
- The **current member's** row is marked (e.g. "You" in the meta).
- The **Invite member** action (gated as today) and the members empty state are preserved.
- **No change** to who appears in the member list or who can invite.

## Open Business Decisions

None open. Role badges are deferred to 049 (which resolves which roles display).

## Implementation Plan

1. In the Members `section-panel` of `web/lib/memba_web/controllers/page_html/club.html.heex`
   (added in 045), replace the avatar-stack card with a `member-list` container.
2. Render each of `@members` as a `member-row`: avatar initials + the member's name.
3. Add a meta line per row and mark the **current member** with a "You" indicator.
4. Preserve the existing members **empty state** and the **Invite member** action from 045.
5. Port the `member-list` and `member-row` CSS (and its children) from `design-system/`
   (`memba.css` / `styles.css`) into `web/assets/css/app.css`, names 1:1 with the mirror.
6. Update the LiveView/controller test: members render as named rows; the current member's row is
   marked "You"; the Invite action and empty state still behave as before.
7. Run `./bin/dev gallery-walk` and compare the Members tab to `club-home.html` (named rows).
8. Run `dev check` and confirm it is green (no feature-file changes).

## Open Technical Decisions

- **"Member since" date:** include the date in the row meta **only if** a membership-since date
  already flows to `@members` via `MemberDashboardPresentation`; if it does not, omit the date this
  slice (name + "You" marker only) rather than adding a new read-model field. Sourcing a
  membership-since date is a separate concern.

## New Capability

The Members tab lists members by **name** (people, not avatars) — the base the role-badges slice
(049) extends.

## Validation Plan

- **Automated:** LiveView/controller test (named rows; "You" marker; invite gating; empty state);
  `dev check` green.
- **Visual:** `./bin/dev gallery-walk`; compare the Members tab to `club-home.html`.
- **Manual:** open the club home Members tab; see named rows with your own row marked "You".

## Risks / Follow-ups

- Depends on 044 (shell) and 045 (Members tab) being merged first.
- **049 role badges** adds per-member role badges once the product decision on which roles display
  is made (all assigned roles? committee roles only? exclude internal permission roles?).
- Long member lists (e.g. 142 rows) render as a simple list; virtualisation/pagination is not in
  scope and can be a later concern if needed.
