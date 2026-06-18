# Problems

## Replies are not tracked as thread conversations

Observed: 2026-06-01

Additional observation: 2026-06-17

Status: Unresolved. [Iteration 019](../iterations/019-inbound-club-messages-by-email/plan.md) lets members create new club messages by email, but explicitly does not add reply/threading behaviour. [Iteration 024](../iterations/024-email-template-designs/plan.md) clarifies that current email replies go to the sender, not back into Memba.

A user cannot reply to an email message in Memba. Replies to club messages are not tracked in Memba as part of a thread, so members cannot follow the conversation there or opt in to receive replies to that thread.

Expected:

- Users can reply to email messages from the message view.
- Replies preserve enough message context for the user to understand what they are responding to.
- Replies are tracked as part of the relevant thread in Memba.
- Members can opt in to receive replies to a thread.
