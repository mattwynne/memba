Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Extend Memba.Membership query API as needed:`

2. **Changes made**
   - Added public Membership query APIs:
     - `Memba.Membership.list_active_clubs_for_member_email/1`
     - `Memba.Membership.active_member_of_club_by_email?/2`
   - These queries:
     - normalize email input by trimming/downcasing,
     - compare projected person emails case-insensitively,
     - include only active memberships,
     - return safe empty/false results for invalid club IDs or blank/nil emails,
     - return clubs in stable name/ID order.
   - Updated `Memba.Accounts` to use the new Membership API instead of reaching through existing member-list queries.
   - Added/updated tests:
     - Membership query tests for active clubs by email and active membership by club/email.
     - No-CRUD boundary test updated to allow the new public query functions.

3. **Validation commands run**
   - TDD red check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/query_test.exs`
     - Failed as expected with undefined new API functions.
   - Formatting:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Passed.
   - Focused tests:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/query_test.exs test/memba/accounts_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Passed: `19 tests, 0 failures`.
   - Full project check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `151 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Extend Memba.Membership query API as needed:`
   - To:
     - `- [x] 004 Extend Memba.Membership query API as needed:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: changes stay within Phoenix/Ecto/PostgreSQL app architecture.
   - ADR 0007: member authorization queries are exposed through the public `Memba.Membership` API; `Memba.Accounts` no longer composes this from lower-level membership queries.
   - ADR 0008: no EventStore schema or persistence strategy changes.
   - ADR 0009: uses existing Membership projection read models through the query context; no custom projection machinery added.
   - ADR 0013 / plan constraint: no acceptance feature files were changed.