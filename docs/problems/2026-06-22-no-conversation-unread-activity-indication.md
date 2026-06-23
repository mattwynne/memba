# Problems

## Conversations give no indication of new or unread replies

Observed: 2026-06-22

Status: Unresolved. Deferred from iteration 043 (conversations overview grouping) as scope creep.

Once the club home lists conversations with a reply count (iteration 043), a member still
cannot tell which conversations have **new** replies they haven't seen. Every member sees
the same static count and ordering, so an active thread with a fresh reply looks the same
as one they have already read.

This needs per-member read state — a record of how far each member has read in each
conversation — which is a new model (and events) rather than a presentation tweak, so it
was kept out of the grouping slice.

Expected:

- A member can see at a glance which conversations have replies they have not yet read.
- Read/unread is tracked per member per conversation, updated as they view a conversation.
- The indication is unobtrusive (e.g. emphasis or a small marker), not a separate inbox.

Impact:

- Members may miss new replies to conversations they care about, undermining the point of
  keeping replies in Memba.
- Without it, the reply count is informative but not actionable — there is no "what's new."
