# Problems

## Pending invitations cannot be managed

Observed: 2026-06-08

Status: Unresolved. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) adds initial Staff invitation sending and automatic resend when the same pending club/email invitation is submitted again. [Iteration 029](../iterations/029-membership-admin-invitations/plan.md) extends invitation sending/resend behaviour to Membership Admins. Neither iteration adds a pending-invitation management surface for listing, cancelling, manually resending, or auditing pending invitations.

After an invitation has been sent, Staff or Membership Admins do not have a clear place to see that it is pending, resend it deliberately, cancel it, or understand whether it has been accepted.

Why it matters:

- Staff may not know whether someone has been invited already.
- Mistyped or no-longer-needed invitations cannot be revoked through a clear workflow.
- Clubs may need to chase or clean up pending invitations before a launch or migration.

Expected:

- Staff and, later, Membership Admins should be able to see pending invitations for a club.
- They should be able to resend a pending invitation intentionally.
- They should be able to cancel/revoke a pending invitation before it is accepted.
- Accepted and cancelled invitations should have clear lifecycle status.
