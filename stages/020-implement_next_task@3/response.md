Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`

2. **Changes made**
   - Removed current Messaging opened-report API:
     - Deleted `Memba.Messaging.report_email_delivery_opened/2`.
     - Removed private opened-command builder from `Memba.Messaging`.
   - Stopped routing opened-report commands:
     - Removed `ReportEmailDeliveryOpened` from `Memba.Messaging.Router`.
     - Updated app/router registration tests to exclude it.
   - Stopped aggregate opened command execution:
     - Removed `Message.execute/2` handling for `ReportEmailDeliveryOpened`.
     - Removed `:sent/:delivered -> :opened` transitions.
     - Kept `EmailDeliveryOpened` as compatibility replay input, but aggregate replay now treats it as delivered rather than an opened current state.
   - Kept `ReportEmailDeliveryOpened` command module as a compatibility struct and updated its moduledoc to say it is no longer routed/current behaviour.
   - Updated Messaging tests so current API/domain expectations cover delivered, delayed, bounced, and spam complaint only.
   - Updated affected webhook/harness tests and controllers so code no longer calls the removed opened API:
     - Postmark/Resend opened webhook events are rejected as unsupported and do not mutate delivery status.
     - Browser harness status refresh no longer reports or expects `opened`.
   - Checked off only task `003` in `docs/iterations/017-remove-open-tracking/todo.md`.

3. **Focused validation**
   - `cd web && mix format --check-formatted ...` — passed for changed Elixir files.
   - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test ...'` — passed:
     - `46 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check`
     - First run hit an unrelated transient auth consistency timeout.
   - Reran the failing auth test:
     - `mix test test/memba_web/controllers/auth_controller_test.exs:278` — passed.
   - Reran full check:
     - `PATH="$PWD/bin:$PATH" dev check` — passed:
       - `373 tests, 0 failures`
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`
   - To:
     - `- [x] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs: `0002`, `0004`, `0005`, `0006`, `0007`, `0009`, `0011`, `0012`, and `0016`.
   - Preserved the ADR 0004 one-message-aggregate boundary and Commanded routing model.
   - Preserved ADR 0007 Messaging context boundaries.
   - Kept event compatibility rather than deleting historical event structs, consistent with the iteration implementation note.
   - ADR 0012’s opened-tracking decision is intentionally superseded by this approved iteration plan for current behaviour.