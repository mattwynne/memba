1. **Selected todo line**
   - `002 Delete the ReportEmailDeliveryOpened command and any dispatch routing/registration for it.`

2. **Changes made**
   - Deleted `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`.
   - Confirmed `Memba.Messaging.Router` already had no `ReportEmailDeliveryOpened` route/registration.
   - Removed direct test/support references that compiled or constructed the deleted command:
     - `web/test/memba/messaging/send_message_dispatch_test.exs`
     - `web/test/features/step_definitions/messaging_steps.exs`
   - Did **not** edit acceptance `.feature` files.

3. **Focused validation**
   - `grep ReportEmailDeliveryOpened web/lib/**/*.ex` — no results.
   - `grep ReportEmailDeliveryOpened web/test/**/*.exs` — no results.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `807 tests, 0 failures`
   - Note: earlier validation attempts exposed stale sandbox Postgres/quality-gate processes from timed-out runs; I cleared only those stale local processes, then reran successfully.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Delete the ReportEmailDeliveryOpened command and any dispatch routing/registration for it.`
   - To:
     - `- [x] 002 Delete the ReportEmailDeliveryOpened command and any dispatch routing/registration for it.`

5. **Todo splits/additions/reordering**
   - None.
   - I did remove minimal Elixir Cucumber support references to the deleted command because `dev check --quick` compiled those step definitions and could not pass while they expanded the deleted struct. Broader opened-status cleanup remains unchecked under later tasks.

6. **ADR conformance**
   - Reviewed relevant ADRs: Commanded/CQRS, message aggregate ownership, separate Messaging context/router, projections, and the historic opened-status ADR.
   - This task keeps command routing within `Memba.Messaging.Router`/`Memba.Messaging.App` boundaries and removes only the deprecated command path required by the validated iteration plan.
   - Historic `EmailDeliveryOpened` replay-shim work was not changed in this task; it remains for later planned tasks.