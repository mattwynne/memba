# Problems

## Member message compose accepts a blank body and fails generically

Observed: 2026-06-01

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
