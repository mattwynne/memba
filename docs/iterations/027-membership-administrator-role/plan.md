# Membership Administrator role foundation

Date: 2026-06-06
Status: ready

## Goal

Create the first flexible club role and permission foundation: every newly approved club starts with a default Membership Administrator role, and the approved requester/first member receives it.

The role grants the coarse permission `club.manage_members`, which covers managing club membership and membership-management roles. The implementation should authorize member-management behaviour through permissions rather than hard-coding checks against the Membership Administrator role name.

## Background / Context

Today Memba staff can convert an onboarding request into a club and first active member, but that first member has no club-owned authority to manage membership. The next product direction is club-defined roles assembled from app-defined permission primitives. This iteration creates the smallest useful foundation for that direction without building the full invite flow or custom role editor.

Important modelling decisions from discovery:

- Permissions are authorization primitives defined by the app.
- Roles are bundles of permissions and may later be assembled by staff or club administrators.
- Authorization checks should ask whether a member has a permission in a club, not whether they hold a particular role name.
- The default Membership Administrator role is created automatically for new clubs and assigned to the club requester/first member.
- `club.manage_members` is intentionally coarse for now and includes adding/removing members and granting/removing membership-management roles.
- A club must always have at least one Membership Administrator.

## Related Problems

- [`docs/problems/2026-06-05-approved-club-owner-cannot-add-members.md`](../../problems/2026-06-05-approved-club-owner-cannot-add-members.md): partially addressed. This iteration creates the role/permission foundation and assigns the approved requester the membership-administration role, but it deliberately does not add the member-facing invitation flow needed to fully resolve the problem.
- [`docs/problems/2026-06-01-memba-staff-identity-and-club-access.md`](../../problems/2026-06-01-memba-staff-identity-and-club-access.md): related but intentionally left unresolved. Staff identity remains separate from club membership administration; this iteration should not make Memba staff implicit club administrators.
- [`docs/problems/2026-06-01-staff-adds-person-with-unverified-email.md`](../../problems/2026-06-01-staff-adds-person-with-unverified-email.md): intentionally left unresolved. Member invitations and email verification are future slices.

## Scope

### In scope

- Introduce app-defined permission primitives for club-scoped authorization, starting with `club.manage_members`.
- Introduce club roles as permission bundles, with role assignments to club members.
- Create a default Membership Administrator role for each new club.
- Grant `club.manage_members` to the Membership Administrator role.
- Assign the approved requester/first member to the Membership Administrator role when an onboarding request is converted into a club.
- Ensure existing club creation paths used by test support/seeds/staff conversion can create or backfill the required default role safely.
- Project member permissions so authorization checks can ask whether a person has `club.manage_members` in a club.
- Add authorization for membership-management commands/actions using the projected permission, not a direct role-name check.
- Allow a member with `club.manage_members` to grant Membership Administrator to another active club member.
- Prevent a member without `club.manage_members` from granting Membership Administrator.
- Prevent revoking/removing the last Membership Administrator from a club.
- Add tests for role creation, permission projection, authorization, and the zero-administrator invariant.
- Add stakeholder-readable acceptance scenarios for the new role and authorization rules.

### Out of scope

- Member-facing invite-by-email flow.
- Member-facing club-admin UI.
- Staff or club UI for assembling arbitrary custom roles from permissions.
- Fine-grained permissions beyond `club.manage_members`.
- Trips, Leaders, or trip proposal permissions.
- Memba staff implicit access to club member-only areas.
- Email verification, invitation acceptance, invitation expiry, resend, or cancellation.
- Reworking all existing staff-only admin screens into club-admin screens.
- Fully resolving the approved-club-owner-cannot-add-members problem.

## Iteration Type

Behaviour-facing foundation iteration.

The user-observable/domain rule changed is that an approved club requester becomes a Membership Administrator of the new club and can use membership-administration authority that is represented by permissions. The slice is mostly domain/application behaviour today, with Cucumber documenting the intended business rules ahead of the later member-facing invite UI.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes who can do what in a club, introduces a new role name, and establishes safety rules about the last administrator. Stakeholder-readable examples are useful to keep the role/permission language aligned.

New feature file:

- `acceptance-tests/features/club_membership_administration.feature`
  - `@todo-domain`/`@todo-ui` Feature: Club membership administration
  - Rule: New clubs start with a Membership Administrator
    - Scenario: A converted requester can administer membership for their new club
  - Rule: Membership administration is authorized by permission
    - Scenario: Robin grants membership administration to Alice
    - Scenario: Alice cannot grant membership administration to Bob
  - Rule: A club always has at least one Membership Administrator
    - Scenario: Robin cannot remove the last Membership Administrator

The feature is tagged `@todo-domain`/`@todo-ui` during planning because the step definitions and implementation do not exist yet. The implementation should remove the `@todo-domain`/`@todo-ui` tag once the scenarios pass.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_membership_administration.feature`: implement the planned scenarios and remove `@todo-domain`/`@todo-ui` once the role/permission behaviour is implemented.
- Existing feature files may be updated only where necessary to keep current onboarding scenarios consistent with the new default role creation side effects. Do not rewrite existing onboarding language unless the behaviour changes.

## Acceptance Criteria

- A `club.manage_members` permission primitive exists with a stable app-defined meaning: managing club membership and membership-management role assignments.
- Creating a new club creates a Membership Administrator role for that club.
- The Membership Administrator role grants `club.manage_members`.
- Converting Robin's West Coast Paddlers request makes Robin an active member of West Coast Paddlers and a Membership Administrator of West Coast Paddlers.
- If Alice is an ordinary member of West Coast Paddlers, Robin can make Alice a Membership Administrator because Robin has `club.manage_members`.
- Alice cannot make Bob a Membership Administrator while Alice lacks `club.manage_members`.
- A club cannot be left with zero Membership Administrators.
- The last Membership Administrator cannot remove or revoke their own Membership Administrator assignment if that would leave the club with none.
- Authorization checks for granting/revoking membership-administration authority use permission projection, not direct checks against a hard-coded role name.
- Existing staff onboarding conversion behaviour still works: club created, requester/first member created or reused, membership created, request marked converted, welcome email sent.
- Existing member sign-in and club membership behaviours continue to work.
- The new Cucumber scenarios pass after implementation with `@todo-domain`/`@todo-ui` removed.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Confirmed decisions:

- The default role is called Membership Administrator.
- `club.manage_members` is the only initial permission primitive needed for this slice.
- Managing members includes granting/removing membership-management roles for now.
- The approved requester/first member, not the Memba staff converter, receives the default Membership Administrator role.
- Invite-by-email is the next user-facing member-management slice, not part of this iteration.

## Implementation Plan

1. Inspect current Membership event-sourced aggregate boundaries for club creation, membership creation/removal, onboarding conversion, and test-support creation paths.
2. Design a minimal role/permission model that supports future custom roles:
   - role definition per club;
   - app-defined permission identifiers;
   - role-to-permission grants;
   - membership/person-to-role assignments;
   - permission projection by club and person/member.
3. Add commands/events for creating the default Membership Administrator role, granting `club.manage_members`, and assigning/removing the role from active members. Prefer events that preserve future role customisation rather than baking all logic into one opaque flag.
4. Ensure club creation initializes the default Membership Administrator role and permission bundle. If the creator/first member is not known at `CreateClub` time, assign the role when the first member is added through onboarding conversion or an explicit assignment command.
5. Update onboarding conversion so the requester/first member receives the Membership Administrator assignment after membership creation.
6. Add projection tables/read models for roles, role permissions, role assignments, and/or flattened member permissions. Keep projections queryable by club and person/member.
7. Add a public Membership query/API for permission checks, for example “does this person have `club.manage_members` in this club?”. Exact function names are implementation details.
8. Add authorization handling to membership-management operations. For paths where Memba staff currently act through staff-only screens, keep staff authorization separate, but make club-member role assignment/removal commands rely on the permission model.
9. Add command/API support for a member with `club.manage_members` to make another active member a Membership Administrator.
10. Add command/API support for revoking Membership Administrator while enforcing that at least one remains.
11. Prevent ordinary members without `club.manage_members` from granting or revoking Membership Administrator.
12. Preserve or migrate existing test data/seeds so current acceptance tests still have valid clubs and memberships. Existing clubs in test/dev may need default role setup in seeds or migration/backfill.
13. Implement step definitions only as needed during delivery to exercise the new Cucumber scenarios through domain/application behaviour. Do not create a polished member-facing admin UI in this iteration.
14. Add ExUnit tests for events, projections, permission checks, authorization failures, and the last-administrator invariant.
15. Remove `@todo-domain`/`@todo-ui` from `club_membership_administration.feature` once implementation passes the scenarios.
16. Run `dev check`.

## Open Technical Decisions

- Exact event and command names for role creation, permission grants, and role assignments.
- Whether the default Membership Administrator assignment is emitted as part of the onboarding conversion application service, an aggregate process, or a follow-up command after membership creation. Prefer the simplest consistent event-sourced shape that keeps failure handling clear.
- Exact projection storage shape for permissions: flattened permission projection only, or both normalized role projections and flattened permission projection. The design should preserve role/permission decoupling for future role assembly.
- How to authorize staff-owned existing admin operations while introducing club-member permission checks. Staff access should remain platform authorization, not implicit club role membership.

## New Capability

Memba can represent and enforce a club-scoped Membership Administrator role built from a permission primitive. Newly approved club requesters become Membership Administrators of their clubs, and the system can distinguish ordinary members from members who can manage membership-administration authority.

## Validation Plan

- Review `acceptance-tests/features/club_membership_administration.feature` with Matt for domain language before implementation.
- During implementation, add domain/application tests proving default role creation, role permission grants, role assignment projection, and permission checks.
- Add tests proving Robin receives Membership Administrator during request conversion, including the existing-person conversion path.
- Add tests proving Robin can make Alice a Membership Administrator and Alice cannot make Bob one while Alice is ordinary.
- Add tests proving the last Membership Administrator cannot be removed/revoked.
- Run the new Cucumber scenarios after removing `@todo-domain`/`@todo-ui`.
- Run the existing request-account scenarios to protect onboarding conversion behaviour.
- Run `dev check`.

## Risks / Follow-ups

- This iteration only partially addresses the approved-requester problem because the requester still needs a future invite-by-email UI/flow to add members directly.
- Role and permission modelling can grow too large quickly. Keep this slice limited to one coarse permission and one default role while preserving extensibility.
- Existing staff admin screens may tempt implementation to blur Memba staff access and club membership administration. Keep platform/staff authorization separate from club-scoped permissions.
- Existing clubs/test fixtures may need backfilled default roles so authorization changes do not break current behaviour.
- Follow-up iteration: Membership Administrators invite new members by email.
- Follow-up iteration: staff or club admins assemble custom roles from permission primitives.
