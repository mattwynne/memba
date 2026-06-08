# Implementation TODO

- [x] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.
- [x] 002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.
- [x] 003 Add a member-facing route/action for inviting club members, scoped to the current club.
- [x] 004 Authorize the route/action using the `club.manage_members` permission for the signed-in person in the current club.
- [x] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.
- [x] 006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.
- [x] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.
- [x] 008 Keep the Admin invitation form email-only.
- [x] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.
- [x] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.
- [ ] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.
- [ ] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new `@iteration-029` scenarios.
- [ ] 013 Remove or narrow `@todo-domain`/`@todo-ui` tags from the affected scenarios only when they pass in the relevant runner.
- [ ] 014 Run `dev check`.
