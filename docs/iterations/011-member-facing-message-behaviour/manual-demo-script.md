# Manual demo script: member-facing message behaviour

Use this after implementation removes `@wip` from `acceptance-tests/features/member_message_deliverability.feature`.

1. Sign in as Alice, an active member of Kootenay Mountaineering Club.
2. Open Kootenay Mountaineering Club from Alice's clubs.
3. Confirm the club home shows recent messages, active members, and a send-message action.
4. Send a message with subject `Trip planning night`.
5. Open the sent message from the member-facing club surface.
6. Confirm the addressed members are Alice, Bob, Carol, and Dana, and Pat is not shown.
7. Confirm each addressed member initially shows `Sending` with a status icon.
8. Simulate provider events:
   - Bob delivered;
   - Carol bounced or delayed;
   - Dana opened after delivery.
9. As Alice, reopen the message and confirm:
   - Alice: `Sending`;
   - Bob: `Delivered`;
   - Carol: `Delivery problem`;
   - Dana: `Opened`.
10. Sign out and sign in as Bob.
11. Open the same message and confirm Bob sees the same shared receipt statuses.
12. Confirm member pages do not show delivery IDs, provider event names, webhook metadata, or raw provider statuses.
13. Confirm staff/operator delivery diagnostics are still available on `/admin/*` for staff users.
