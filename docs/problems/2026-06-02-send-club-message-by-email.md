# Problems

## Members cannot send a club message by email

Observed: 2026-06-02

Members can read club messages and receive club-message email, but they cannot create a new club message by sending an email into Memba.

Expected:

- A member can send an email to a club-specific address and have it appear as a club message in Memba.
- Memba identifies the sending member from the inbound email address.
- Memba associates the inbound message with the correct club.
- The resulting club message follows the same visibility, delivery, and audit rules as a message composed in the web UI.

Open questions:

- What should the club-specific inbound address look like?
- Should inbound email support attachments?
- How should Memba handle email from unknown, inactive, or unverified addresses?
- Should replies to existing message emails create threaded replies, new messages, or both depending on context?
