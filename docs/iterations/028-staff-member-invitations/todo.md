# Implementation TODO

- [x] 001 Inspect current Staff club/person routes and forms, especially any club-scoped create-person/add-member path and `/admin/clubs/:club_id/people/:person_id/edit`.
- [x] 002 Inspect the existing auth sign-in token and staff onboarding flow to decide how to reuse or extend it for invitation acceptance without mixing ordinary short-lived sign-in links with membership-granting invitation links.
- [ ] 003 Add a minimal club invitation model in the Membership boundary, event-sourced if consistent with nearby Membership aggregates:
- [ ] 004 Add public Membership APIs/commands for Staff/system use:
- [ ] 005 Ensure duplicate checks use normalized email:
- [ ] 006 Add an invitation email module with clear club context and a one-use invitation link.
- [ ] 007 Add the Staff club-scoped invite route and form. Exact route name is implementation detail, but it should sit under `/admin/clubs/:club_id/...` and not replace the existing person edit route.
- [ ] 008 Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.
- [ ] 009 Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.
- [ ] 010 Generalize the current staff onboarding/profile completion enough that invited unknown members can enter their name before membership activation. For this slice, profile-completion state can live in the invitation/session journey; do not create an incomplete person before the name is submitted, and avoid overbuilding date-of-birth or configurable detail schemas.
- [ ] 011 Preserve existing staff onboarding: new Memba staff with no person record still enter a name and continue to the Staff area.
- [ ] 012 Add domain/application tests for pending invitation creation, duplicate active block, duplicate pending resend, existing-person acceptance, unknown-person profile completion, abandoned profile completion, and accepted-link reuse.
- [ ] 013 Add browser/LiveView/controller tests for the Staff invite page, invitation email link, profile completion page, and final redirect to the club.
- [ ] 014 Implement or update Cucumber step definitions only as needed to exercise `club_member_invitations.feature`.
- [ ] 015 Remove or narrow `@todo-domain`/`@todo-ui` from `club_member_invitations.feature` once implemented.
- [ ] 016 Run targeted tests for affected auth/membership/onboarding surfaces, then run `dev check`.
