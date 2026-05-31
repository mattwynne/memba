1. **Selected todo line**
   - `- [ ] 001 Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.`

2. **Changes made for this task only**
   - Added `docs/iterations/008-postmark-email-integration/inspection.md` with findings covering:
     - `Memba.Messaging.DeliveryProvider` port and Fake provider.
     - Current `DeliveryRequest` fields and the send flow.
     - Existing Swoosh/Mailer config.
     - Existing Postmark webhook routing/correlation logic.
     - Relevant ADR constraints.
     - Gaps identified for later todo items.
   - Updated only the selected todo line in `docs/iterations/008-postmark-email-integration/todo.md`.

3. **Focused validation commands run**
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - Compiled app.
     - Ran ExUnit: `112 tests, 0 failures`.
     - Command exited `0`. The devenv manager emitted its usual shutdown SIGKILL message after successful completion.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.`
   - To:
     - `- [x] 001 Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspection notes explicitly checked the current implementation against:
     - ADR 0004: message aggregate owns deliverability by `message_id`.
     - ADR 0005: resolved recipients and channel-neutral delivery language.
     - ADR 0006: simplified member-facing receipt statuses.
     - ADR 0007: Messaging uses Membership public query API.
     - ADR 0012: opened status is idempotent.