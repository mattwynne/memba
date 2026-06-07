# Problems

## Delivery status does not update live as webhooks come in

Observed: 2026-06-01

Status: Resolved in the codebase by the read-model change PubSub refresh work (`ReadModelChanges` subscriptions on member message detail, member dashboard/message list, staff message diagnostics, and staff deliveries). I did not find a dedicated iteration plan for this fix; it landed as follow-up/kaizen work rather than a named iteration.

Email delivery status does not update live when webhook events arrive. This is expected to affect every place where email delivery status is shown. The known surfaces are likely two member-facing places and one staff-facing place, but the exact list needs an audit.

Users may need to refresh or revisit the page before they can see the latest email delivery state.

Expected:

- Email delivery status reflects incoming webhook updates without a manual refresh wherever it is shown.
- Members and staff can trust the visible delivery status to show the latest known state.
