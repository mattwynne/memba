1. **Selected todo line**
   - `020 Add/update domain tests for verification state, primary restrictions, duplicate handling, removal restrictions, sign-in-as-verification, and inbound rejection.`

2. **Changes made**
   - Added Membership public API domain coverage in `web/test/memba/membership/public_api_test.exs` for:
     - pending email addresses cannot become primary;
     - primary email addresses cannot be removed;
     - duplicate normalized email attached to another Person is rejected;
     - pending known address sign-in verification marks the address verified without making it primary;
     - already-verified/unknown sign-in-verification inputs are no-ops and append no events.
   - Updated existing domain/query expectations to include the new `verified_at` field returned by `Membership.list_person_email_addresses/1`:
     - `web/test/memba/membership/public_api_test.exs`
     - `web/test/memba/membership/query_test.exs`
     - `web/test/memba_web/live/admin_people_live_test.exs`
   - Updated the Membership public API contract test in `web/test/memba/membership/no_crud_spike_test.exs` to include the already-introduced `list_active_club_memberships_for_person/1`.
   - Checked off task `020` in `docs/iterations/053-my-settings-email-addresses/todo.md`.

3. **Validation commands run**
   - `cd web && mix format --check-formatted test/memba/membership/public_api_test.exs`
     - initially found formatting needed; fixed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_addresses_test.exs test/memba/membership/person_email_address_projection_test.exs test/memba/messaging/inbound_club_sender_test.exs`
     - passed: `24 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs`
     - initially exposed stale `verified_at` expectation; fixed.
     - passed after fix: `28 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/membership/query_test.exs test/memba_web/live/admin_people_live_test.exs`
     - passed: `51 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/no_crud_spike_test.exs`
     - passed: `4 tests, 0 failures`.
   - Final validation on the final diff:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - passed: `1005 tests, 0 failures`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 020 Add/update domain tests for verification state, primary restrictions, duplicate handling, removal restrictions, sign-in-as-verification, and inbound rejection.`
   - To:
     - `- [x] 020 Add/update domain tests for verification state, primary restrictions, duplicate handling, removal restrictions, sign-in-as-verification, and inbound rejection.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 and ADR 0023 were not materially affected by this domain-test-only task.
   - No member page implementation, routing, LiveView tab state, or client-side state behaviour was changed.
   - The added tests reinforce the plan’s domain invariants around verified/pending email-address state, primary-address rules, sign-in-as-verification, and safe identity handling.