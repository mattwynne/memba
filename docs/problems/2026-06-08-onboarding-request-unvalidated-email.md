# Problems

## Onboarding requests can be submitted with unvalidated email addresses

Observed: 2026-06-08

Status: Unresolved. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) plans an invitation/profile-completion pattern for Staff-created club member invitations, but deliberately leaves public get-started request email verification out of scope.

A person can submit a Memba access request with an email address that has not been verified. Staff may then be asked to review or act on a request without knowing whether the requester controls the supplied email address.

Expected:

- Memba should verify that the requester controls the email address before treating the request as trusted or actionable.
- The requester should have a clear path to confirm their identity, such as creating an account/person through a magic-link email before or during the request flow.
