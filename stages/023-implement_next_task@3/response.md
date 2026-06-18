1. **Selected todo line**
   - `003 Remove the "opened" read-model normalization clauses in messaging.ex, the presentation "opened" -> "delivered" mapping, and the webhook "opened" rejection branch.`

2. **Changes made**
   - Removed member/staff read-model `"opened"` normalization clauses from `web/lib/memba/messaging.ex`.
   - Removed `"opened" -> "delivered"` presentation normalization from `web/lib/memba_web/member_email_delivery_presentation.ex`.
   - Removed the explicit Postmark `"opened"` rejection branch from `web/lib/memba_web/controllers/postmark_webhook_controller.ex`; `"Opened"` now falls through the generic unsupported-record path.
   - Updated focused tests covering those exact behaviours:
     - `member_email_delivery_presentation_test.exs`
     - `member_email_delivery_projection_test.exs`
     - `memba_staff_email_delivery_projection_test.exs`
     - `postmark_webhook_controller_test.exs`

3. **Focused validation**
   - TDD red run before production changes:
     - Focused test command failed as expected with assertions proving the old normalization/mapping/branch still existed.
   - Green focused test run after implementation:
     - `env -u PGHOST -u PGPORT -u DEVENV_RUNTIME devenv shell -- bash -lc 'devenv processes status postgres >/dev/null 2>&1 || DEVENV_TUI=false devenv processes up --no-strict-ports -d postgres >/dev/null; cd web && MIX_ENV=test mix test test/memba_web/member_email_delivery_presentation_test.exs test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs'`
     - Result: `30 tests, 0 failures`
   - Formatting check:
     - `mix format --check-formatted ...`
     - Passed.
   - Specific production grep checks:
     - No remaining task-003 refs for read-model `"opened"` normalization, `"opened" -> "delivered"` presentation mapping, or Postmark `"opened" ->` branch.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Remove the ...`
   - To:
     - `- [x] 003 Remove the ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs: Commanded/CQRS, message aggregate ownership, Messaging bounded context separation, Ecto projections, member-facing status simplification, historic opened tracking, and read-model/projection synchronization.
   - This task stayed in the query/presentation/webhook layer only:
     - No command routing changes.
     - No aggregate/event/projector replay-shim changes; those remain for tasks 004/005/007.
     - Messaging context boundaries remain intact.
   - The historical opened-status ADR is being retired by the validated iteration plan; this slice removes only the specific live compatibility behaviours assigned to task 003.