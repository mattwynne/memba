# Problems

## Approved club requester cannot add more members

Observed: 2026-06-05

Status: In progress / partially addressed. [Iteration 022](../iterations/022-request-to-club-onboarding/plan.md) converts an approved requester into the first active member, but explicitly leaves club admin roles/permissions beyond that out of scope. [Iteration 027](../iterations/027-membership-administrator-role/plan.md) creates the Admin / `club.manage_members` foundation. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) plans the invitation and profile-completion pattern for Staff only. The problem remains unresolved until Membership Admins can invite members themselves.

When someone requests a new club and Memba staff approve the request, the requester gains access to the new club but does not have a way to add more members to that club.

Expected:

- An approved club requester should have a clear way to add or invite additional members.
- A newly approved club should be able to start building its membership without staff intervention for each member.
