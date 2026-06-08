# Staff member invitations with profile completion

Date: 2026-06-08
Status: implementing

## Goal

Make Staff add club members by invitation instead of by directly creating active people/members. An invited person controls the invited email by following a one-use invitation link, completes the required profile detail for this slice (their name), and only then becomes an active ordinary member of the club.

## Background / Context

Iteration 027 created the Admin / `club.manage_members` foundation but deliberately left invitations out of scope. Matt wants a fundamental pattern: when Memba needs to bring someone into the system, it invites them by email, then uses a shared onboarding/profile-completion step before letting them continue. This avoids trusting Staff- or Admin-entered identity details and creates a place to collect future required details such as date of birth or club-specific onboarding fields.

There is already a staff-only onboarding page at `/auth/onboard` that asks new Memba staff for their name after sign-in. This iteration should generalize that idea for invited club members while delivering the first usable Staff invitation route under a club.

## Related Problems

- [`docs/problems/2026-06-05-approved-club-owner-cannot-add-members.md`](../../problems/2026-06-05-approved-club-owner-cannot-add-members.md): partially addressed. This iteration proves the invitation and profile-completion pattern, but Staff are the only inviters in this slice; Membership Admin self-service remains unresolved.
- [`docs/problems/2026-06-01-staff-adds-person-with-unverified-email.md`](../../problems/2026-06-01-staff-adds-person-with-unverified-email.md): partially addressed. Staff club-member creation should no longer create active members from unverified typed email addresses. Membership Admin invitations and adding alternate email addresses remain unresolved.
- [`docs/problems/2026-06-08-onboarding-request-unvalidated-email.md`](../../problems/2026-06-08-onboarding-request-unvalidated-email.md): related but intentionally left unresolved. Public get-started requests still need their own email-control check.
- [`docs/problems/2026-06-08-membership-admins-cannot-invite-members.md`](../../problems/2026-06-08-membership-admins-cannot-invite-members.md): intentionally left unresolved. This slice creates the Staff invitation path first; club Admin invitation is the next user-facing permission slice.
- [`docs/problems/2026-06-08-pending-invitations-cannot-be-managed.md`](../../problems/2026-06-08-pending-invitations-cannot-be-managed.md): intentionally left unresolved. Duplicate pending invite submission may resend, but there is no pending-invitation management UI in this slice.
- [`docs/problems/2026-06-08-club-onboarding-details-not-collected.md`](../../problems/2026-06-08-club-onboarding-details-not-collected.md): intentionally left unresolved. This slice only requires a name.
- [`docs/problems/2026-06-08-invitation-links-do-not-expire.md`](../../problems/2026-06-08-invitation-links-do-not-expire.md): intentionally left unresolved. This slice uses one-use invitation links but, by decision, no expiry.
- [`docs/problems/2026-06-08-person-alternate-email-verification-missing.md`](../../problems/2026-06-08-person-alternate-email-verification-missing.md): intentionally left unresolved. This slice removes the Staff club-member direct-creation bypass but does not change alternate email address verification.

## Scope

### In scope

- Add a new Staff route under a club for inviting a member by email.
- The Staff invitation form takes only an email address.
- Keep the existing person edit route/form for editing known people, but remove, hide, redirect, or otherwise decommission Staff club-member creation paths that create an active member directly from a name and email address.
- Create a pending club invitation for an unknown email without creating an active person or active membership.
- Send an invitation email with a one-use invitation magic link.
- Following the invitation link signs/verifies the invited email into the invitation journey.
- Unknown invited people must enter their name before they become active members or continue into the club.
- Invitation tokens for unknown invitees remain pending and reusable until profile completion succeeds.
- Completing the name creates the person and active ordinary membership, signs the person in, marks the invitation accepted, consumes the invitation token, and lands them in the club.
- Existing complete people invited to a new club can accept by following the invitation link; Memba creates the active ordinary membership and lands them in the club without asking for their name again.
- Inviting an email that is already an active member of the club is blocked with a clear Staff-facing message.
- Inviting an email that already has a pending invitation for the same club resends the invitation instead of creating a duplicate pending invitation.
- Accepted invitation links cannot create duplicate memberships when reopened; reopening an accepted invitation signs or keeps the person in and lands them in the club.
- No invitation expiry in this slice.

### Out of scope

- Membership Admin invitation UI or authorization through `club.manage_members`.
- Dedicated pending-invitation list, resend button, cancel/revoke UI, or reminder workflow.
- Choosing roles during invitation; invited people become ordinary members only.
- Date of birth, emergency contact, club-specific required details, or configurable onboarding forms.
- Public get-started request email verification.
- Redesigning all Staff person/email-address management beyond preventing Staff club-member creation from bypassing invitations.
- Bulk import/invite flows.
- Invitation expiry.

## Iteration Type

Behaviour-facing.

The user-observable rules changed are: Staff invite club members by email instead of directly creating active members; an invitation becomes membership only after the invitee follows the link and completes required profile details; duplicate active/pending invitations are handled safely.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes identity, membership activation, invitation lifecycle, and Staff workflow. Stakeholder-readable examples are necessary to keep the invitation/profile-completion policy clear.

New feature file:

- `acceptance-tests/features/club_member_invitations.feature`
  - Feature tagged `@iteration-028 @todo-domain @todo-ui` during planning.
  - Rule: Staff invite new members by email
    - Scenario: Robin accepts an invitation and completes their profile
    - Scenario: Alice accepts an invitation as an existing person
  - Rule: Invited people complete required profile details before membership starts
    - Scenario: Robin leaves before entering their name, then returns with the same invitation link
  - Rule: Staff club-member creation goes through invitations
    - Scenario: Pat cannot bypass invitation when adding a club member
  - Rule: An invitation does not create duplicate club membership
    - Scenario: Pat cannot invite an active member again
    - Scenario: Pat resends a pending invitation by inviting the same email again
  - Rule: Invitation links can only be accepted once
    - Scenario: Robin reopens an accepted invitation

The feature is tagged `@todo-domain`/`@todo-ui` because the invitation domain, route, email, acceptance journey, profile-completion step support, and browser steps are future-facing at planning time. Delivery should remove or narrow those tags once the scenarios pass.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_member_invitations.feature`: implement the planned scenarios and remove or narrow `@todo-domain`/`@todo-ui` once the Staff invitation and profile-completion behaviour is implemented.
- Existing authentication/request-account/person feature files may be updated only where necessary to keep language consistent with the new shared profile-completion pattern or to remove obsolete direct Staff club-member creation expectations. Preserve existing covered behaviour unless this plan explicitly changes it.

## Acceptance Criteria

- Staff can open a club-scoped invitation page/route and submit an email address.
- Staff do not provide the invitee's name on the invitation form.
- Unknown invited emails create a pending invitation, not an active person and not an active membership.
- The invitation email contains an invitation link that is one-use for successful membership creation.
- Following an invitation link for an unknown email asks the invitee for their name before creating an active membership.
- If the invitee leaves before entering their name, they are still not an active member of the club, the invitation remains pending, and the same invitation link can be followed again to resume profile completion.
- Submitting a non-blank name creates the person with the invited email, creates an ordinary active membership for the invited club, marks the invitation accepted, consumes the invitation token, signs the person in, and takes them to the invited club.
- Following an invitation link for an existing complete person who is not a member of the club creates an ordinary active membership and signs them in to the invited club without asking for their name again.
- Inviting an email that is already an active member of the club is rejected with a clear message.
- Inviting an email that already has a pending invitation for the club resends an invitation email and preserves a single pending invitation record.
- Reopening an already accepted invitation link signs/keeps the person in and takes them to the club without creating another membership or repeating profile completion.
- Reopening a pending invitation before profile completion resumes the profile-completion step and does not consume the invitation until completion succeeds.
- Staff club-member creation paths no longer allow creating an active club member directly from name and email; Staff are directed to the invitation flow instead.
- Invitation links are one-use for membership creation. No expiry is required in this slice.
- New invited members receive no Admin role by default.
- Existing staff onboarding still works.
- Existing member sign-in and club navigation still work.
- The new Cucumber scenarios pass after implementation with `@todo-domain`/`@todo-ui` removed or narrowed.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Confirmed decisions:

- First invitation UI is Staff-only.
- The Staff route is under a club and asks only for an email address.
- Unknown invitees enter name only in this slice.
- Invited people become active members only after accepting the link and completing required profile details.
- Existing complete people can accept and join automatically by following the invitation link.
- Duplicate active members are blocked.
- Duplicate pending invitations resend rather than creating another pending invitation.
- Invitation links do not expire in this slice.
- Invited members are ordinary members by default.

## Implementation Plan

1. Inspect current Staff club/person routes and forms, especially any club-scoped create-person/add-member path and `/admin/clubs/:club_id/people/:person_id/edit`.
2. Inspect the existing auth sign-in token and staff onboarding flow to decide how to reuse or extend it for invitation acceptance without mixing ordinary short-lived sign-in links with membership-granting invitation links.
3. Add a minimal club invitation model in the Membership boundary, event-sourced if consistent with nearby Membership aggregates:
   - pending invitation for club/email;
   - accepted state;
   - separate invitation token/token-hash storage from ordinary sign-in tokens, because invitation links grant membership;
   - token remains usable while the invitation is pending and profile completion has not succeeded;
   - successful acceptance/profile completion marks the invitation accepted and consumes the token;
   - resend behaviour for duplicate pending invite submissions;
   - no expiry for this slice.
4. Add public Membership APIs/commands for Staff/system use:
   - invite email to club;
   - resend existing pending invitation for same club/email;
   - accept invitation for existing complete person;
   - complete invited-person profile and accept invitation for unknown/incomplete person.
5. Ensure duplicate checks use normalized email:
   - active member in club blocks invitation;
   - pending invitation in club resends;
   - existing person not in club can be invited and reused at acceptance.
6. Add an invitation email module with clear club context and a one-use invitation link.
7. Add the Staff club-scoped invite route and form. Exact route name is implementation detail, but it should sit under `/admin/clubs/:club_id/...` and not replace the existing person edit route.
8. Decommission direct Staff club-member creation from name/email by hiding/removing that action or redirecting it to the invite route. Keep person edit behaviour where still needed for existing people.
9. Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.
10. Generalize the current staff onboarding/profile completion enough that invited unknown members can enter their name before membership activation. For this slice, profile-completion state can live in the invitation/session journey; do not create an incomplete person before the name is submitted, and avoid overbuilding date-of-birth or configurable detail schemas.
11. Preserve existing staff onboarding: new Memba staff with no person record still enter a name and continue to the Staff area.
12. Add domain/application tests for pending invitation creation, duplicate active block, duplicate pending resend, existing-person acceptance, unknown-person profile completion, abandoned profile completion, and accepted-link reuse.
13. Add browser/LiveView/controller tests for the Staff invite page, invitation email link, profile completion page, and final redirect to the club.
14. Implement or update Cucumber step definitions only as needed to exercise `club_member_invitations.feature`.
15. Remove or narrow `@todo-domain`/`@todo-ui` from `club_member_invitations.feature` once implemented.
16. Run targeted tests for affected auth/membership/onboarding surfaces, then run `dev check`.

## Open Technical Decisions

- Exact invitation aggregate/stream shape and event names.
- Exact URL and LiveView/controller split for the Staff invite page, invitation callback, and profile completion step.

Resolved technical decisions for this slice:

- Invitation tokens use separate invitation-token storage from ordinary sign-in tokens, because invitation links grant membership.
- Unknown invited emails are represented as pending invitations only before acceptance/profile completion; do not create incomplete person records in this slice.
- Profile-completion state for invited unknown people lives in the invitation/session journey until the invitee submits a valid name.
- The invitation token is not consumed when an unknown invitee first opens the link. It remains usable while the invitation is pending, and is consumed only when profile completion succeeds and membership is created.
- For existing complete people, following the link accepts the invitation, creates membership, consumes the token, signs them in, and lands them in the club.

## New Capability

Memba can invite a person to a club by email without trusting Staff-entered identity details. The invitee proves control of the email, supplies their own required name, and only then becomes an active ordinary club member.

## Validation Plan

- Matt reviews `acceptance-tests/features/club_member_invitations.feature` for domain language before delivery is treated as final.
- During implementation, add domain/application tests for invitation lifecycle and duplicate rules.
- Add web tests for Staff invitation UI, email delivery, invitation callback, profile completion, and redirects.
- Run the new Cucumber scenarios after removing or narrowing `@todo-domain`/`@todo-ui`.
- Run existing authentication, request-account, person-email-address, and club membership administration tests to protect adjacent flows.
- Run `dev check`.

## Risks / Follow-ups

- This does not yet let Membership Admins invite members, so the approved-club-owner problem remains unresolved for real club self-service.
- Staff may still have global person/email-address management paths that can create unverified identity data. This slice should close the club-member creation bypass, but full email-verification policy remains larger.
- Invitation links grant membership and currently have no expiry by decision; revisit expiry before broad production use if risk changes.
- Pending invitation management is deferred: Staff cannot list, cancel, or manually resend from a management screen yet.
- Future profile fields such as date of birth, emergency contact, or club-specific details need their own modelling and UX slices.
