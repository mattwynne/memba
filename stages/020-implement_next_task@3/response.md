Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`

2. **Changes made**
   - Added `Memba.Accounts` authentication context:
     - email normalization,
     - exact `memba.io` staff-domain check,
     - magic-link request eligibility for staff or active members,
     - secure URL-safe token generation,
     - SHA-256 token hashing,
     - 15-minute token expiry,
     - transactional single-use token consumption,
     - active club listing for an email,
     - active club membership check by `club_id` and email.
   - Added `Memba.Accounts.MagicToken` Ecto schema for `auth_magic_tokens`.
   - Added `web/test/memba/accounts_test.exs` covering:
     - normalization,
     - staff detection,
     - hashed token persistence,
     - no token creation for unknown emails,
     - expiry,
     - single-use consumption,
     - active club listing,
     - membership authorization checks.

3. **Validation**
   - `cd web && mix format --check-formatted` — passed.
   - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check` — passed:
     - `148 tests, 0 failures`.
   - Note: an initial bare `mix test test/memba/accounts_test.exs` attempt could not connect to Postgres outside the dev-managed environment, so final validation used the project-supported `dev check`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`
   - To:
     - `- [x] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: uses Phoenix/Ecto/PostgreSQL in the core app.
   - ADR 0007: `Memba.Accounts` derives member authorization through the public `Memba.Membership` API rather than coupling to membership projection internals.
   - ADR 0008: auth tokens remain normal app persistence in the public schema, not EventStore.
   - ADR 0009: no projection machinery is misused for auth state.
   - ADR 0013: no acceptance feature files or web feature-test strategy changes were made.