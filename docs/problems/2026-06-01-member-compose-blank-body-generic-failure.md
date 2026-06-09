# Problems

## Member message compose accepts a blank body and fails generically

Observed: 2026-06-01

Status: Resolved by [iteration 025: Messaging and onboarding quick wins](../iterations/025-messaging-and-onboarding-quick-wins/plan.md). The member compose LiveView now validates blank or whitespace-only message bodies before calling `Messaging.send_club_message/2`, keeps the compose form open, preserves the subject, and shows the specific message `Message body can’t be blank.` Evidence: `web/test/memba_web/live/member_message_live/new_send_test.exs`.

When a member sends a club message with a subject but an empty message body, the LiveView allows the submit. The Messaging aggregate rejects the command with `:invalid_body`, so no delivery provider is called and no email appears in `/dev/mailbox`.

The member sees only the generic send-failure state instead of inline validation or a clear “message body can’t be blank” error.

Evidence from manual test/log:

```text
%Memba.Messaging.Commands.SendMessage{subject: "yo yo yo", body: "", ...}
[error] Member message send failed
```

Expected:

- The compose UI should prevent or clearly validate blank message bodies before send.
- The member should see a specific, recoverable validation message.
- Invalid form input should not look like an infrastructure send failure.
