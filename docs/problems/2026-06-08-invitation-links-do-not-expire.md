# Problems

## Invitation links do not expire

Observed: 2026-06-08

Status: Unresolved. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) explicitly chooses no invitation expiry for the first Staff invitation slice, while still requiring one-use invitation links.

Invitation links grant club membership when accepted. If they never expire, an old invitation email could be accepted much later than Staff or the club intended, unless it has been cancelled by a future management workflow.

Why it matters:

- Long-lived membership-granting links increase the impact of forwarded, compromised, or stale emails.
- Clubs may assume an invitation was only valid during a launch or onboarding window.
- Future pending-invitation management needs clear lifecycle rules.

Expected:

- Invitation links should eventually have an explicit expiry policy.
- Expired invitations should not create membership.
- Staff and Membership Admins should see enough status to decide whether to resend or cancel expired invitations.
