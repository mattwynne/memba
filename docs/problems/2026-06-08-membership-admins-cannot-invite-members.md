# Problems

## Membership Admins cannot invite members themselves

Observed: 2026-06-08

Status: Resolved by [iteration 029: Membership Admin invitations](../iterations/029-membership-admin-invitations/plan.md). [Iteration 027](../iterations/027-membership-administrator-role/plan.md) created the Admin / `club.manage_members` foundation, [iteration 028](../iterations/028-staff-member-invitations/plan.md) added the invitation/profile-completion path for Staff, and iteration 029 exposed the same invitation capability to Membership Admins for their own club.

A newly approved club has an Admin, but that Admin still cannot invite additional people to join the club without Memba Staff doing it for them.

Why it matters:

- Newly approved clubs cannot start building their membership independently.
- Memba Staff remain a bottleneck for ordinary member growth.
- The `club.manage_members` permission is not yet visible as a useful club-admin capability.

Expected:

- A Membership Admin should be able to invite a person to join their club by email.
- The invitation should use the same email-control and profile-completion flow as Staff invitations.
- Invited people should become ordinary active members only after accepting the invitation and completing required profile details.
