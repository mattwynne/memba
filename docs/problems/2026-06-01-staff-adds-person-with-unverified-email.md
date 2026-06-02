# Problem

## Staff can add a person whose email has not been verified

Observed: 2026-06-01

When staff adds a person, Memba has not verified that the email address belongs to that person.

Why it matters:

- Staff could accidentally give access, messages, or identity-linked actions to the wrong email address.
- A typo or stale address may create a person record that cannot reliably receive future communication.
- If email later becomes an authentication or authorization signal, unverified addresses may weaken trust in person identity.

Open questions:

- Should staff-created people be marked as having an unverified email until the person confirms it?
- What staff actions, if any, should be allowed before the email is verified?
- Should Memba send an email verification request automatically when staff adds a person?
