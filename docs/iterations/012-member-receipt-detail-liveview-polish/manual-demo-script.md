# Manual demo script: member receipt detail LiveView polish

Use this after iteration 012 implementation.

1. Sign in as Alice, an active member of Kootenay Mountaineering Club.
2. Open Kootenay Mountaineering Club.
3. Open a message with mixed receipt statuses.
4. Confirm the message detail page shows:
   - subject;
   - body;
   - sender;
   - addressed member count;
   - a “Who got this” receipt summary.
5. Confirm the summary shows a segmented status bar plus visible counts and percentages for:
   - Opened;
   - Delivered;
   - Sending;
   - Delivery problem.
6. Confirm receipt groups are collapsed by default.
7. Expand each group and confirm recipient rows appear for that status.
8. Collapse each group and confirm recipient rows are hidden again.
9. Confirm recipient rows show member-facing labels only and do not expose delivery IDs, provider event names, webhook metadata, raw provider statuses, recipient email addresses, or delivery failure reasons.
10. Sign in as Bob and confirm he sees the same summary and group behaviour for the same message.
11. As a staff/operator user, confirm `/admin/messages/:message_id` and `/admin/deliveries` still show operator diagnostics.
