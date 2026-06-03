Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `015 Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.`

2. **Changes made**
   - No code/config/docs changes were needed.
   - Checked off only task 015 in `docs/iterations/020-migrate-production-email-to-postmark/todo.md`.

3. **Focused validation commands run**
   - Initial direct `bin/mix test ...` attempt hit the known stale sandbox `PGHOST=/tmp/devenv/postgres` issue, so I reran inside a clean devenv shell with matching Postgres env.
   - Successful targeted test command:
     ```sh
     env -u DEVENV_DOTFILE -u DEVENV_PROFILE -u DEVENV_ROOT -u DEVENV_STATE \
       -u DEVENV_TASKS -u DEVENV_TASK_FILE -u PGDATA -u PGHOST -u PGPORT \
       MEMBA_POSTGRES_PORT=15432 \
       devenv shell -O services.postgres.port:int 15432 -- bash -lc '
       set -euo pipefail
       PATH="$PWD/bin:$PATH" bin/mix test \
         test/memba_web/postmark_inbound_email_parser_test.exs \
         test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs \
         test/memba_web/resend_inbound_email_parser_test.exs \
         test/memba_web/controllers/resend_inbound_webhook_controller_test.exs \
         test/memba/messaging/inbound_email_api_test.exs \
         test/memba/messaging/inbound_email_dispatch_test.exs \
         test/memba/messaging/email_delivery_providers/postmark_test.exs \
         test/memba_web/controllers/postmark_webhook_controller_test.exs \
         test/memba/accounts/auth_email_config_test.exs \
         test/memba/accounts/auth_email_test.exs \
         test/memba/messaging/email_delivery_provider_config_test.exs \
         test/memba/messaging/email_delivery_provider_test.exs \
         test/memba/messaging/email_delivery_providers/postmark_config_test.exs \
         test/memba/messaging/email_delivery_providers/resend_config_test.exs
     '
     ```
     Result: `72 tests, 0 failures`.

   - Todo diff/whitespace check:
     ```sh
     git diff -- docs/iterations/020-migrate-production-email-to-postmark/todo.md
     git diff --check -- docs/iterations/020-migrate-production-email-to-postmark/todo.md
     ```
     Result: passed; expected one-line todo check-off only.

4. **Exact todo check-off made**
   ```md
   - [x] 015 Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
   ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - This task only validated existing implementation.
   - The focused test set confirms Postmark inbound, Resend fallback/regression, provider-neutral inbound handling, Postmark outbound metadata/webhook correlation, auth email provider config, and provider selection remain covered.
   - Resend remains a tested fallback as required by ADR 0016’s updated posture.
   - I did not run `dev check`; that remains the next explicit task (`016`).