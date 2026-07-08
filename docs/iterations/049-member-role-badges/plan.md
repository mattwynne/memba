# 049 — Club home Members: role badges

Date: 2026-07-07
Status: validated

## Goal

Show each active member's assigned roles as badges in the club-home Members tab, so members can see
who holds which club roles directly in the member list.

## Background / Context

Iteration 048 replaced the Members tab avatar stack with named member rows and deliberately deferred
the role badges already shown in the club-home design. The Membership bounded context already has a
role framework and role assignments. This iteration presents assigned roles on the active-member list;
it does not create new role-management workflows.

Matt's product decisions for this slice:

- If a member has assigned roles, show them.
- Show all assigned roles; the UI should not distinguish system/internal/public roles.
- Sort a member's role badges alphabetically by role name.
- Do not defensively de-duplicate role names; duplicates are a data/model bug.
- Creating roles, assigning roles, and role-management UI are out of scope.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** The Members tab becomes a little more informative while preserving the
  simple app-like member-row treatment from the existing design.

## Scope

### In scope

- Extend the active-member read model returned by `Membership.list_active_members_of_club/1` so each
  member map includes `roles: [...]`.
- Include role names from active role assignments for active members in the selected club.
- Sort each member's `roles` list alphabetically by role name.
- Pass `roles` through `MemberDashboardPresentation` into the club-home Members row data.
- Render every role in `member.roles` as a `member-row__role` badge in the Members tab.
- Keep the Members tab an **active members only** list; removed members must not appear, even if they
  previously had roles.
- Add executable shared Cucumber scenarios for listing members and their roles.

### Out of scope

- Creating roles.
- Assigning roles.
- Removing roles or role-management UI.
- Hiding or styling roles differently because they are system/internal/public roles.
- Defensive de-duplication of duplicate role names.
- Member-since dates.
- Changing who can view the Members tab or who can invite members.

## Iteration Type

**Behaviour-facing.** This changes the member-observable rule for the Members tab: active member rows
show assigned roles, and removed members remain absent from the list even if they had a role.

## Acceptance Scenarios / Feature Files

**BDD decision: Required.** The slice changes visible member-list behaviour and includes business
rules about active members, assigned roles, and removed members. The acceptance examples are captured
in [`acceptance-tests/features/list_members.feature`](../../../acceptance-tests/features/list_members.feature).

Created scenarios:

- `@iteration-049` / `@todo-domain @todo-ui` — `A member sees assigned roles in the member list`:
  active members show all assigned roles, sorted alphabetically, and members without roles show none.
- `@iteration-049` / `@todo-domain @todo-ui` — `A removed member had a role`: removed members do not
  appear in the member list, even if they previously had a role.

The scenarios are tagged `@todo-domain @todo-ui` only to keep planning-time mainline green before
implementation adds the required step definitions and app behaviour. Implementation must remove both
TODO tags and make the scenarios executable in both the domain and browser runners under `dev check`.

## Allowed acceptance feature changes

- `acceptance-tests/features/list_members.feature`: implementation may remove `@todo-domain` and
  `@todo-ui` from the `@iteration-049` scenarios once it adds the matching domain and browser step
  definitions/support and makes the scenarios pass. It may refine scenario wording only to preserve
  the same rules and examples; it must not weaken coverage of role badges, alphabetical ordering, or
  removed-member exclusion.
- Matching Cucumber step definition/support files under the domain and browser acceptance test trees
  may be added or updated as needed to execute `list_members.feature`.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
Members panel. The checked-in design already shows `member-row__role` badges on named member rows
(e.g. Chair, Secretary, Treasurer, Trip organizer). `DesignSync` was not available in this Pi
session; the checked-in design source was inspected directly and is sufficient for this slice. **No
new design work needed.**

## Acceptance Criteria

- The Members tab still lists only active members of the selected club.
- Each active member row includes a `roles` presentation value, even when empty.
- Members with assigned active roles show one badge per role.
- Multiple badges for a member are sorted alphabetically by role name.
- Members with no roles show no role badges.
- Removed members do not appear in the member list, even if they previously had a role.
- The UI treats roles uniformly; it does not branch on system/internal/public role type.
- The `@iteration-049` scenarios in `acceptance-tests/features/list_members.feature` pass in both the
  domain and browser runners, with `@todo-domain` and `@todo-ui` removed by implementation.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Inspect the existing role projection schemas and queries (`Membership.Projections.RoleAssignment`,
   role projections, and role-assignment projector) to confirm field names and active flags.
2. Extend `Membership.list_active_members_of_club/1` to include `roles: [...]` for each active
   member. Use active role assignments only and sort each member's role names alphabetically.
3. Add or update Membership query tests covering: members with no roles, members with multiple roles
   sorted alphabetically, and removed members not appearing even when they had roles.
4. Update `MemberDashboardPresentation` only as needed to pass through/prep `roles` for member rows;
   keep the HEEx template free of direct projection queries.
5. Render each role as a `member-row__role badge badge-primary badge-soft` badge in
   `web/lib/memba_web/controllers/page_html/club.html.heex`.
6. Add/update LiveView or presentation tests proving role badges render, no-role members show none,
   and removed members remain absent.
7. Add browser and domain Cucumber step definitions/support for `list_members.feature`.
8. Remove `@todo-domain @todo-ui` from the `@iteration-049` scenarios once both runners execute them
   successfully.
9. Run `./bin/dev gallery-walk` and compare the Members tab to `design-system/wireframes/club-home.html`.
10. Run `dev check` and confirm it is green.

## Open Technical Decisions

None known. Badge style defaults to `badge badge-primary badge-soft` for all roles; the UI does not
encode role categories.

## New Capability

Members can see assigned club roles directly in the Members tab, while the list remains limited to
active members.

## Validation Plan

- **Acceptance:** `acceptance-tests/features/list_members.feature` scenarios pass in both domain and
  browser runners, with temporary TODO tags removed.
- **Automated:** Membership query tests; MemberDashboardPresentation/LiveView tests; `dev check`.
- **Visual:** `./bin/dev gallery-walk`; compare the Members tab role badges to
  `design-system/wireframes/club-home.html`.
- **Manual:** Open the club home Members tab as Alice; verify Bob's roles appear alphabetically,
  Carol's role appears, Alice has no role badges, and removed members are absent.

## Risks / Follow-ups

- The existing role framework may only expose Membership Administrator role helpers today; if generic
  role creation/assignment helpers are missing, implementation should use existing command/projection
  capabilities in tests/support without adding role-management UI.
- Long member lists with many roles remain a simple list; pagination/virtualisation is out of scope.
