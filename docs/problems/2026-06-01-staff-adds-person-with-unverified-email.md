# Problems

## Staff and membership admins can create people or add emails without verification

Observed: 2026-06-01

Status: Unresolved. [Iteration 016: Multiple email addresses per person](../iterations/016-person-email-addresses/plan.md) added known primary/alternate email addresses, but explicitly left email verification workflow out of scope. On 2026-06-07 this was observed again for Staff and Membership admins creating people or adding emails to existing people.

When Staff or a Membership admin creates a person, or adds an email address to an existing person, Memba does not verify that the email address belongs to that person.

Why it matters:

- Staff or Membership admins could accidentally give access, messages, or identity-linked actions to the wrong email address.
- A typo or stale address may create or update a person record that cannot reliably receive future communication.
- If email later becomes an authentication or authorization signal, unverified addresses may weaken trust in person identity.

Expected:

- New people created by Staff or Membership admins should go through an invite or verification flow before their email is treated as verified.
- New email addresses added to an existing person should be verified before they are trusted for that person.
- People should only receive account access or identity-linked email behaviour through email addresses they have confirmed.

Open questions:

- What Staff or Membership admin actions, if any, should be allowed before the email is verified?
- Should Memba send an email verification request automatically when Staff or a Membership admin creates a person or adds an email address?
