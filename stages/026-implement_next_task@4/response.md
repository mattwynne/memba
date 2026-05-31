Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`

2. **Changes made**
   - Added `Memba.Accounts` context with:
     - `normalize_email/1`
     - `staff_email?/1`
     - `request_magic_link/2`
     - `create_magic_token/2`
     - `hash_magic_token/1`
     - `consume_magic_token/2`
     - `list_clubs_for_email/1`
     - `active_member_of_club?/2`
   - Magic tokens are generated securely, stored only as SHA-256 hashes, expire after 15 minutes, and are consumed atomically/single-use.
   - Staff authorization is derived from exact `@memba.io` email domain.
   - Club/member checks delegate to existing public `Memba.Membership` query APIs.
   - Added `web/test/memba/accounts_test.exs` covering normalization, staff checks, magic-link request/token storage, expiration, single-use consumption, and email-based membership club queries.

3. **Validation commands run**
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba/accounts.ex test/memba/accounts_test.exs'`
     - Passed.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `149 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`
   - To:
     - `- [x] 003 Add an authentication context, likely Memba.Accounts or Memba.Identity, with functions to:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Uses Phoenix/Ecto/PostgreSQL application storage and context conventions.
   - ADR 0007: Keeps membership decisions behind the public `Memba.Membership` query API.
   - ADR 0009: Does not misuse Commanded projections; auth tokens remain normal Ecto persistence.
   - ADR 0011: Does not alter Commanded aggregate identity conventions.
   - ADR 0013: Added focused ExUnit tests; no acceptance feature files changed.