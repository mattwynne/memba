# Implementation TODO

- [x] 001 Inspect the existing role projection schemas and queries (`Membership.Projections.RoleAssignment`, role projections, and role-assignment projector) to confirm field names and active flags.
- [x] 002 Extend `Membership.list_active_members_of_club/1` to include `roles: [...]` for each active member. Use active role assignments only and sort each member's role names alphabetically.
- [x] 003 Add or update Membership query tests covering: members with no roles, members with multiple roles sorted alphabetically, and removed members not appearing even when they had roles.
- [x] 004 Update `MemberDashboardPresentation` only as needed to pass through/prep `roles` for member rows; keep the HEEx template free of direct projection queries.
- [x] 005 Render each role as a `member-row__role badge badge-primary badge-soft` badge in `web/lib/memba_web/controllers/page_html/club.html.heex`.
- [x] 006 Add/update LiveView or presentation tests proving role badges render, no-role members show none, and removed members remain absent.
- [x] 007 Add browser and domain Cucumber step definitions/support for `list_members.feature`.
- [x] 008 Remove `@todo-domain @todo-ui` from the `@iteration-049` scenarios once both runners execute them successfully.
- [ ] 009 Run `./bin/dev gallery-walk` and compare the Members tab to `design-system/wireframes/club-home.html`.
- [ ] 010 Run `dev check` and confirm it is green.
