Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.`

2. **Changes made**
   - Updated `web/test/memba/accounts_test.exs`
     - Strengthened alternate-email sign-in coverage to prove:
       - the token row stores the normalized requested alternate address;
       - the token hash matches the returned token;
       - consuming the token signs in as the normalized alternate address, not the primary address.
   - Updated `web/test/memba_web/controllers/auth_controller_test.exs`
     - Added controller coverage proving a member requesting a sign-in link with an alternate address:
       - gets a token stored for that normalized alternate address;
       - receives the email at that alternate address;
       - does not receive it at their primary address.
     - Extended the local controller test helper to create a projected member with primary plus alternate email-address rows.
   - Updated `docs/iterations/016-person-email-addresses/todo.md`
     - Checked off only task `010`.

   No production code changes were needed; existing Accounts/AuthController/AuthEmail behavior already used the normalized token email returned from `Accounts.request_sign_in_link/2`.

3. **Validation run**
   - `cd /workspace/memba/web && mix format --check-formatted test/memba/accounts_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Passed.
   - `cd /workspace/memba/web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/accounts_test.exs test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `23 tests, 0 failures`.
   - `cd /workspace/memba && git diff --check`
     - Passed.
   - `cd /workspace/memba && PATH="$PWD/bin:$PATH" dev check`
     - Passed: `334 tests, 0 failures`.

   Note: an initial bare `mix test ...` attempt failed before tests ran because the bare shell expected a missing `/tmp/devenv/postgres` socket. I started devenv Postgres and reran the focused tests successfully with the reported socket/port.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 010 Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.`
   - To:
     - `- [x] 010 Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: No domain CRUD bypass or aggregate write changes introduced.
   - ADR 0007: Accounts/AuthController tests continue to exercise Membership through public/projection-backed behavior, without making Messaging depend on Membership storage.
   - ADR 0009: Uses existing projection-backed Membership lookup behavior.
   - ADR 0010: No acceptance feature files were edited.
   - ADR 0011: Email remains mutable identity data; UUID person identity remains unchanged.