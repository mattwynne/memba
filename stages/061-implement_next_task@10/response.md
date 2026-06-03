1. **Selected todo line**
   - `010 Verify or add tests proving Postmark auth email configuration uses MEMBA_AUTH_EMAIL_PROVIDER=postmark, MEMBA_POSTMARK_SERVER_TOKEN, MEMBA_AUTH_EMAIL_FROM_ADDRESS, and MEMBA_AUTH_EMAIL_MESSAGE_STREAM, and fails clearly when incomplete.`

2. **Changes made**
   - Updated `web/test/memba/accounts/auth_email_config_test.exs` to:
     - Assert Postmark env parsing returns `provider: :postmark`.
     - Add a runtime config test proving `MEMBA_AUTH_EMAIL_PROVIDER=postmark` configures:
       - `Memba.Mailer` with `Swoosh.Adapters.Postmark`
       - `api_key` from `MEMBA_POSTMARK_SERVER_TOKEN`
       - `Memba.Accounts.AuthEmail` with `provider: :postmark`
       - `from` from `MEMBA_AUTH_EMAIL_FROM_ADDRESS`
       - `message_stream` from `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`
       - `Swoosh.ApiClient.Req`
     - Add a runtime config failure test proving selected-but-incomplete Postmark auth email config raises a clear `ArgumentError` mentioning all required env vars and `MEMBA_AUTH_EMAIL_PROVIDER`.
   - Updated `docs/iterations/020-migrate-production-email-to-postmark/todo.md` to check off task 010 only.

3. **Focused validation commands run and results**
   - Formatting:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/accounts/auth_email_config_test.exs
     ```
     Passed.
   - Initial focused test:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_config_test.exs
     ```
     Failed due the known sandbox `PGHOST=/tmp/devenv/postgres PGPORT=5432` mismatch.
   - Focused auth config test with sandbox Postgres override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_config_test.exs'
     ```
     Passed: `7 tests, 0 failures`.
   - Focused auth config + auth email delivery tests:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_test.exs test/memba/accounts/auth_email_config_test.exs'
     ```
     Passed: `13 tests, 0 failures`.
   - Broad quick validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     Passed: `489 tests, 0 failures`.
   - Whitespace check:
     ```sh
     git diff --check
     ```
     Passed.

4. **Exact todo check-off made**
   - Changed:
     ```md
     - [ ] 010 Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
     ```
   - To:
     ```md
     - [x] 010 Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0016 preserved: auth email remains provider-selectable through runtime configuration, Postmark uses the Swoosh Postmark adapter, and Resend fallback support was not changed or weakened.
   - The tests verify provider-specific Postmark configuration at the configuration boundary without changing domain behaviour.
   - ADR 0017 alignment: selected-but-incomplete production-style auth email config now has explicit test coverage for clear operator-facing failure.
   - No acceptance feature files, routing, UI, or production secrets were changed.