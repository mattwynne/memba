# Problems

## Staff can create club members without email verification

Observed: 2026-06-01

Status: Resolved by [iteration 028: Staff member invitations](../iterations/028-staff-member-invitations/plan.md). Staff now invite by email instead of creating an active person/member from typed name and email through the club-member direct-creation path. The remaining related concern is tracked separately: [Alternate email addresses can be added without verification](2026-06-08-person-alternate-email-verification-missing.md).

When Staff creates a club member directly from a name and email address, Memba does not verify that the email address belongs to that person.

Why it matters:

- Staff could accidentally give access, messages, or identity-linked actions to the wrong email address.
- A typo or stale address may create a person/member record that cannot reliably receive future communication.
- Email is already an authentication and authorization signal in Memba, so unverified direct member creation weakens trust in person identity.

Expected:

- New club members created by Staff should go through an invitation flow.
- People should only receive club membership access after confirming control of the invited email address and completing required profile details.
