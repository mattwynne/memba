# Problems

## Alternate email addresses can be added without verification

Observed: 2026-06-08

Status: Unresolved. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) plans to remove the Staff club-member direct-creation path in favour of invitations, but does not address verification for alternate email addresses added to an existing person.

Staff can add or change email addresses on an existing person without proving that the person controls the new address.

Why it matters:

- A typo or stale address may become associated with the wrong person.
- If alternate addresses are used for sign-in, inbound email, or identity-linked communication, unverified addresses weaken trust in person identity.
- A person may receive messages or access links at an address they do not control.

Expected:

- Newly added email addresses should be unverified until the person confirms control of the address.
- Unverified email addresses should not be used for sign-in or identity-linked behaviour unless a later policy explicitly allows it.
- Staff should be able to see which addresses are verified, pending, or unavailable.
