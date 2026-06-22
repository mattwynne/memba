# Problems

## Automatic email responses can be posted as conversation replies

Observed: 2026-06-21

Iteration 041 lets members reply to a Memba conversation from their email client. During review, we noticed that the same inbound path could also treat automatic mailbox responses as real member replies when they come from a member address and carry recognized reply headers.

Examples include out-of-office replies, delivery-status notifications, vacation responders, mailbox forwarding notices, and other automated replies. If accepted as normal replies, these messages could appear in a club conversation and be fanned out to followers, creating confusion or even reply loops.

Expected:

- Memba distinguishes human-written email replies from obvious automatic responses.
- Automatic responses are not posted into member conversations as if the member intentionally replied.
- Automatic responses do not trigger follower fan-out loops.
- Members still receive a clear outcome when their own intentional reply cannot be posted safely.
