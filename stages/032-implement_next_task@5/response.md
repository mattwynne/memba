Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Extend Memba.Membership query API as needed:`

2. **Changes made**
   - Added `Memba.Membership.list_active_clubs_for_member_email/1`
     - normalizes email,
     - returns active clubs for that email,
     - excludes inactive memberships and missing club projections,
     - deduplicates clubs,
     - orders by club name/id.
   - Added `Memba.Membership.active_member_email_of_club?/2`
     - normalizes email,
     - validates `club_id`,
     - checks active membership by club + email.
   - Updated `Memba.Accounts` to delegate email-based club/member checks to the new public Membership query API instead of scanning clubs/members itself.
   - Added/updated tests:
     - `web/test/memba/membership/query_test.exs`
     - `web/test/memba/membership/no_crud_spike_test.exs`

3. **Validation commands run**
   - Initial red test:
     - `devenv shell -- bash -lc 'mix test test/memba/membership/query_test.exs --trace'`
     - Failed as expected with undefined `Membership` email-query functions.
   - Formatting:
     - `devenv shell -- bash -lc 'mix format --check-formatted lib/memba/membership.ex lib/memba/accounts.ex test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs'`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'mix test test/memba/membership/query_test.exs test/memba/accounts_test.exs test/memba/membership/no_crud_spike_test.exs'`
     - Passed: `22 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `152 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Extend Memba.Membership query API as needed:`
   - To:
     - `- [x] 004 Extend Memba.Membership query API as needed:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Keeps the implementation in the Phoenix/Ecto/PostgreSQL app stack.
   - ADR 0007: Keeps membership lookups behind the public `Memba.Membership` query API; `Accounts` delegates to it instead of depending on projection details.
   - ADR 0009: Queries existing Ecto projections without changing Commanded projection machinery.
   - ADR 0011: Does not alter aggregate identity rules; uses existing UUID projection identities.
   - ADR 0013: No acceptance feature files were changed; focused ExUnit tests cover this task.