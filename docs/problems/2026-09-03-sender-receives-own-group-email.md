# Problems

## A sender receives a redundant copy of their own group email

Observed: 2026-09-03

Status: Unresolved. Captured while planning iteration 057, Admin-group email conversations.

When a member starts a group conversation by emailing its group address, Memba's
normal recipient delivery would also send a copy of that message back to the sender
when they belong to the addressed group. The sender already has the message in their
Sent folder, so the extra copy is noisy rather than useful.

Expected:

- A sender who starts a group conversation by email does not receive an outbound copy
  of that same root message merely because they belong to its recipient group.
- Other active members of the addressed group still receive the normal group-message
  email.
- The decision should preserve useful delivery/audit semantics and define the
  corresponding behaviour for future web-composed group messages and replies.
