1. **Selected todo line**
   - `- [ ] 003 Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.`

2. **Changes made**
   - Added generated migration:
     - `web/priv/repo/migrations/20260620071150_add_status_constraints_to_messaging_email_deliveries.exs`
   - The migration adds database check constraint:
     - `messaging_email_deliveries_status_check`
     - Allows the async dispatch lifecycle statuses:
       - `pending`
       - `dispatching`
       - `sent`
       - `failed`
     - Preserves existing provider/webhook statuses:
       - `delivered`
       - `delayed`
       - `bounced`
       - `spam_complaint`
   - Added focused DB constraint tests:
     - `web/test/memba/messaging/email_delivery_status_constraints_test.exs`
     - Proves valid lifecycle/webhook statuses insert successfully.
     - Proves an unknown status is rejected by the named DB constraint.
   - Staged the selected-task changes for Fabro checkpointing.

3. **Focused validation commands run and results**
   - Generated migration:
     - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix ecto.gen.migration add_status_constraints_to_messaging_email_deliveries`
     - Passed.
   - Format check:
     - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix format --check-formatted priv/repo/migrations/20260620071150_add_status_constraints_to_messaging_email_deliveries.exs test/memba/messaging/email_delivery_status_constraints_test.exs`
     - Passed.
   - Focused test:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/email_delivery_status_constraints_test.exs'`
     - Passed: `2 tests, 0 failures`.
   - Broad per-task check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check --quick'`
     - Passed after final todo check-off: `801 tests, 0 failures`.
   - Whitespace:
     - `git diff --check && git diff --cached --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.`
   - To:
     - `- [x] 003 Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / 0009: Kept this as an Ecto read-model/projection persistence constraint; no command/event semantics were changed.
   - ADR 0004 / 0005: Did not alter aggregate ownership or domain event vocabulary.
   - ADR 0006: Did not expose new infrastructure/provider diagnostics to member-facing projections or UI.
   - ADR 0021 / 0022: Did not change projector publishing, barriers, or replay behaviour; no provider side effects were introduced.