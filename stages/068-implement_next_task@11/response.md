Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Update active-club lookup and active-member-by-email checks to match any known address attached to the person.`

2. **Changes made**
   - Updated `web/test/memba_web/user_auth_test.exs`:
     - Added coverage that `IdentityAuth.fetch_current_identity/2` assigns active clubs when the signed-in session email is an alternate known member email.
     - Added coverage that `IdentityAuth.require_active_club_member/2` allows access when the signed-in email is an alternate known address for an active member.
     - Extended the local test helper with `:alternate_emails` support by inserting non-primary `membership_person_email_addresses` rows.
   - Updated `docs/iterations/016-person-email-addresses/todo.md`:
     - Checked off task `011` only.
   - No production code changes were needed; the existing Membership query implementation already joins `membership_person_email_addresses`, and Accounts/IdentityAuth already delegate through those public APIs.

3. **Focused validation run**
   - `cd web && mix format --check-formatted test/memba_web/user_auth_test.exs`
     - Passed.
   - Initial bare `mix test` failed because `/tmp/devenv/postgres` was not available.
   - `PATH="$PWD/bin:$PATH" dev postgres`
     - Started the devenv Postgres service.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/user_auth_test.exs`
     - Passed: `16 tests, 0 failures`.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/query_test.exs test/memba/accounts_test.exs test/memba_web/user_auth_test.exs`
     - Passed: `40 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `336 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 011 Update active-club lookup and active-member-by-email checks to match any known address attached to the person.`
   - To:
     - `- [x] 011 Update active-club lookup and active-member-by-email checks to match any known address attached to the person.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: No production CRUD/domain bypass introduced; production domain/write model unchanged.
   - ADR 0007: Messaging was untouched; caller behavior continues through Accounts/Membership public APIs.
   - ADR 0009: Behavior remains projection-backed through `membership_person_email_addresses`.
   - ADR 0011: Email remains mutable identity data; UUID person identity remains unchanged.
   - Acceptance feature files were not edited.