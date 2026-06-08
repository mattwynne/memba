# Problems

## Staff and membership admins can create people or add emails without verification

Observed: 2026-06-07

When Staff or a Membership admin creates a person, or adds an email address to an existing person, Memba does not verify that the email address belongs to that person.

Expected:

- New people created by Staff or Membership admins should go through an invite or verification flow before their email is treated as verified.
- New email addresses added to an existing person should be verified before they are trusted for that person.
- People should only receive account access or identity-linked email behaviour through email addresses they have confirmed.
