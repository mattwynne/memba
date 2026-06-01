# Manual demo script: member compose LiveView flow

Use this after iteration 013 implementation.

1. Sign in as Alice, an active member of Kootenay Mountaineering Club.
2. Open Kootenay Mountaineering Club.
3. Confirm the club home shows a “Send club message” CTA and no inline compose form.
4. Click “Send club message”.
5. Confirm the compose page is at `/messages/new?club_id=<club_id>`.
6. Confirm the compose page:
   - uses the club member chrome;
   - explains the message goes to all active members;
   - shows Alice as the sender;
   - has no sender dropdown;
   - has subject and message fields.
7. Send a message with subject `Trip planning night`.
8. Confirm the success state says the message was sent.
9. Confirm the success state has actions:
   - “See who got it”;
   - “Send another message”;
   - “Back to home”.
10. Click “See who got it” and confirm the new message detail page opens for `Trip planning night`.
11. Return to the success/compose flow and click “Send another message”; confirm a fresh compose screen opens for the same club.
12. Simulate a send failure.
13. Try to send another message.
14. Confirm the failure state says the message was not sent and tells Alice to contact support.
15. Confirm the failure state offers “Try again” and “Back to club home”.
16. Confirm staff/operator diagnostics and existing member receipt pages still work.
