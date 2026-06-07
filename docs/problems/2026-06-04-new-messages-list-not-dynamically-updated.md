# Problems

## New messages do not appear in the list automatically

Observed: 2026-06-04

Status: Resolved in the codebase by the member dashboard LiveView refresh on messaging read-model changes. I did not find a dedicated iteration plan for this fix; it appears to share the same read-model change PubSub follow-up as the delivery-status-live fix.

When new messages arrive, the message list does not dynamically update.

Expected:

- Newly arrived messages appear in the list without requiring the user to manually refresh or navigate away and back.
- Users can see new messages promptly while they are using the message list.
