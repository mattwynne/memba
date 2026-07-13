Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Existing verified addresses for the same Person keep their verified state when staff edit the set; removed addresses lose any outstanding verification tokens.`

2. **Changes made**
   - Updated `Memba.Membership.replace_person_email_addresses/2` to:
     - preserve existing verified email-address state via the already-established replacement command path;
     - compute pending email addresses removed by a staff replacement;
     - invoke a verification-token revocation hook for those removed pending addresses after successful dispatch.
   - Updated `Memba.Membership.remove_person_email_address/2` with the same revocation hook for direct pending-address removal.
   - Added revocation plumbing:
     - strips `:verification_revoker` from dispatch options before Commanded dispatch;
     - default revoker is a safe no-op until the dedicated token store is added in the next tasks;
     - supports `:ok`, `{:ok, _}`, and `{:error, reason}` revoker results.
   - Added a focused public API test proving staff replacement:
     - keeps a verified alternate address verified;
     - removes a pending address;
     - sends the removed pending address scope to the verification revoker.

3. **Validation run**
   - TDD failure before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs:455`
     - Failed as expected because no revocation message was sent.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs:455`
     - Passed.
   - Formatting:
     - `cd web && mix format lib/memba/membership.ex test/memba/membership/public_api_test.exs --check-formatted`
     - Passed.
   - Focused Membership suite:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/person_email_address_projection_test.exs`
     - Passed: `53 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `977 tests, 0 failures`.
   - Full final validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including browser acceptance: `109 scenarios, 783 steps`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Existing verified addresses for the same Person keep their verified state when staff edit the set; removed addresses lose any outstanding verification tokens.`
   - To:
     - `- [x] 007 Existing verified addresses for the same Person keep their verified state when staff edit the set; removed addresses lose any outstanding verification tokens.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Preserves Membership bounded-context ownership; no Account aggregate or new bounded context introduced.
   - Keeps the state-changing email-address rules in the Membership application/domain flow.
   - Respects CQRS/event-sourcing boundaries: replacement/removal still dispatch explicit Membership commands/events; revocation is an application-service side effect around successful command dispatch, not a projection or generic CRUD bypass.
   - ADR 0015/0023 were read; this task did not add or change member LiveView routing/UI.