# Membership Admin invitations

Date: 2026-06-08
Status: validated

## Goal

Let a club Membership Admin invite new ordinary members by email without Memba Staff involvement. The invitation uses the same email-control, one-use-link, and profile-completion rules as the Staff invitation flow from iteration 028.

## Background / Context

Iteration 027 created the `club.manage_members` permission and default Membership Administrator role. Iteration 028 is implementing the first invitation/profile-completion path for Memba Staff, deliberately leaving Membership Admin self-service out of scope.

This iteration turns that foundation into the first useful club-owned membership-management capability: the approved club requester, as Membership Admin, can start building the club membership without asking Memba Staff to invite each person.

## Related Problems

- [`docs/problems/2026-06-08-membership-admins-cannot-invite-members.md`](../../problems/2026-06-08-membership-admins-cannot-invite-members.md): expected to resolve for the first invitation slice. Membership Admins can invite ordinary members by email themselves.
- [`docs/problems/2026-06-05-approved-club-owner-cannot-add-members.md`](../../problems/2026-06-05-approved-club-owner-cannot-add-members.md): expected to resolve for ordinary member growth. A newly approved club requester who is a Membership Admin can invite more members without Staff intervention.
- [`docs/problems/2026-06-08-pending-invitations-cannot-be-managed.md`](../../problems/2026-06-08-pending-invitations-cannot-be-managed.md): intentionally left unresolved. Duplicate pending invitation submission may resend through the inherited invitation rule, but there is no pending-invitation list, cancel/revoke workflow, explicit resend button, or accepted/cancelled lifecycle view in this slice.
- [`docs/problems/2026-06-08-invitation-links-do-not-expire.md`](../../problems/2026-06-08-invitation-links-do-not-expire.md): intentionally left unresolved. This slice keeps iteration 028's one-use invitation links with no expiry.
- [`docs/problems/2026-06-08-club-onboarding-details-not-collected.md`](../../problems/2026-06-08-club-onboarding-details-not-collected.md): intentionally left unresolved. Unknown invitees only provide their name before activation.
- [`docs/problems/2026-06-08-onboarding-request-unvalidated-email.md`](../../problems/2026-06-08-onboarding-request-unvalidated-email.md): related but intentionally left unresolved. Public get-started request email verification is a separate onboarding concern.
- [`docs/problems/2026-06-08-person-alternate-email-verification-missing.md`](../../problems/2026-06-08-person-alternate-email-verification-missing.md): related but intentionally left unresolved. This slice invites new members by controlled email link; it does not change alternate email-address management for existing people.

## Scope

### In scope

- Give signed-in active members with `club.manage_members` a club-scoped way to invite a new member by email.
- Reuse an existing club members list if one exists; otherwise add the smallest member-facing club members/admin page needed to expose the invitation action.
- Show the invitation action only to Membership Admins for that club.
- Ask the Membership Admin for the invitee's email address only.
- Create or resend a pending club invitation using the same domain rules as Staff invitations.
- Send an invitation email with a one-use invitation magic link.
- Unknown invited people must enter their name before becoming active members.
- Existing complete people invited to a new club can accept without entering their name again.
- Invited people become ordinary active members only; they do not receive Membership Administrator by default.
- Block inviting an email that is already an active member of the club with a clear Admin-facing message.
- Inviting an email that already has a pending invitation for the same club resends the invitation and preserves a single pending invitation record.
- Prevent ordinary members from seeing or using the invitation flow. Direct URL access by an ordinary member must be forbidden, redirected, or otherwise clearly rejected.
- Preserve the Staff invitation flow from iteration 028.

### Out of scope

- Dedicated pending-invitation list.
- Explicit resend button, cancel/revoke workflow, reminders, accepted/cancelled lifecycle view, or audit UI.
- Invitation expiry.
- Bulk import or bulk invitation flows.
- Choosing a role during invitation; invited people become ordinary members only.
- Required profile details beyond name.
- Role-management UI beyond anything already delivered by iteration 027.
- Public get-started request email verification.
- Alternate email-address verification for existing people.
- Reworking Staff access or Memba Staff identity.

## Iteration Type

Behaviour-facing.

The user-observable rule changed is that club members with `club.manage_members` can invite ordinary members to their own club by email, while ordinary members cannot. The invitee activation rules stay aligned with the Staff invitation/profile-completion flow.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes who can invite people into a club and relies on authorization, invitation lifecycle, and identity-control rules. Stakeholder-readable examples keep the Membership Admin capability and boundaries clear.

Updated existing feature file:

- `acceptance-tests/features/club_member_invitations.feature`
  - New scenarios tagged `@iteration-029`.
  - The feature remains under feature-level `@todo-domain @todo-ui` until delivery implements the shared invitation behaviour.
  - Commented rule heading: `# Rule: Membership Admins invite new members by email`
    - Scenario: Robin invites Dana to join West Coast Paddlers
  - Commented rule heading: `# Rule: Membership invitations are authorized by club permission`
    - Scenario: Alice cannot invite someone to join West Coast Paddlers
  - Commented rule heading: `# Rule: An invitation does not create duplicate club membership`
    - Scenario: Robin cannot invite an active member again
    - Scenario: Robin resends a pending invitation by inviting the same email again

The existing Staff invitation scenarios in the same feature continue to express Staff behaviour. Delivery may remove or narrow `@todo-domain`/`@todo-ui` tags once iteration 028 and 029 scenarios pass in their respective runners.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_member_invitations.feature`: implement the planned Membership Admin scenarios tagged `@iteration-029`; during delivery, remove or narrow `@todo-domain`/`@todo-ui` only when the covered behaviour passes in the relevant runner.
- Existing authentication, membership administration, or invitation feature files may be updated only where necessary to keep language consistent with this new member-facing invitation capability. Preserve existing covered behaviour unless this plan explicitly changes it.

## Acceptance Criteria

- A signed-in active Membership Admin can reach the club-scoped invitation action from the club members list if it exists, or from the smallest suitable member-facing club members/admin page if it does not.
- The Membership Admin invitation form asks for email address only.
- Submitting an unknown email creates a pending invitation and sends an invitation email.
- The invitation email contains a one-use invitation magic link.
- Following the invitation link as an unknown person asks for the person's name before creating an active membership.
- If the invitee leaves before entering their name, they are still not an active member of the club.
- Submitting a non-blank name creates the person with the invited email, creates an ordinary active membership for the invited club, signs the person in, and takes them to the invited club.
- Inviting an existing complete person who is not a club member sends an invitation; accepting it creates an ordinary active membership and signs them in to the club without asking for their name again.
- Invited people receive no Membership Administrator role by default.
- Inviting an email that is already an active member of the club is rejected with a clear Membership Admin-facing message.
- Inviting an email that already has a pending invitation for the club resends an invitation email and preserves a single pending invitation record.
- Ordinary members do not see the invitation action.
- Ordinary members cannot use the invitation route/action by direct URL or crafted request.
- The Staff invitation flow from iteration 028 still works.
- Existing member sign-in and club navigation still work.
- The new Cucumber scenarios pass after implementation with `@todo-domain`/`@todo-ui` removed or narrowed as appropriate.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- The next iteration should focus on Membership Admin invitations only.
- Pending invitation management, expiry, and richer onboarding details remain future slices.
- Membership Admin invitations use email address only; invitees supply their own names when needed.
- The preferred UI entry is the existing members list if one exists.

## Implementation Plan

1. Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.
2. Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.
3. Add a member-facing route/action for inviting club members, scoped to the current club.
4. Authorize the route/action using the `club.manage_members` permission for the signed-in person in the current club.
5. Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.
6. Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.
7. If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.
8. Keep the Admin invitation form email-only.
9. Ensure accepted Membership Admin invitations create ordinary active memberships only.
10. Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.
11. Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.
12. Implement or update Cucumber step definitions only as needed during delivery to exercise the new `@iteration-029` scenarios.
13. Remove or narrow `@todo-domain`/`@todo-ui` tags from the affected scenarios only when they pass in the relevant runner.
14. Run `dev check`.

## Open Technical Decisions

- Exact route/page names for the member-facing members/invitation surface, especially if no members list currently exists.
- Whether the existing Staff invitation command can accept a club-member actor directly, or whether a thin club-admin application service should wrap the same lower-level invitation command.
- How to present direct URL/action rejection for ordinary members: forbidden page, redirect with flash, or not-found-style concealment. Any choice is acceptable if it is clear and tested.

## New Capability

A newly approved club can grow beyond its first member without Memba Staff inviting each person. Membership Admins can invite ordinary members themselves while Memba still verifies email control through an invitation link and preserves profile-completion before activation.

## Validation Plan

- Review `acceptance-tests/features/club_member_invitations.feature` language for the new Membership Admin scenarios before delivery.
- During implementation, add domain/application tests proving Membership Admin invitation authorization and reuse of Staff invitation lifecycle rules.
- Add web tests proving the invitation action is visible to Membership Admins and unavailable to ordinary members.
- Run the updated Cucumber scenarios after implementation with appropriate todo tags removed or narrowed.
- Run `dev check`.

## Risks / Follow-ups

- Iteration 028 is currently implementing. Delivery for this plan should build on the shared invitation foundation from iteration 028 rather than duplicating a parallel Membership Admin-only invitation implementation.
- The first member-facing members/admin surface may become a seed for later pending-invitation management, role assignment, or member removal; keep it small and do not prebuild those workflows.
- Pending invitation list/resend/cancel and expiry remain important hardening follow-ups once invitations are used by real clubs.
