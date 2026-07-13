Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Preserve or adapt replace_person_email_addresses/2 for staff edit compatibility while enforcing the new rule that newly introduced addresses become pending/unverified unless they already exist as verified addresses for that Person.`

2. **Changes made**
   - Adapted `Memba.Membership.EmailAddresses` with replacement-state merging:
     - existing addresses keep their verification state;
     - newly introduced replacement addresses get `verified_at: nil`;
     - replacement is rejected if the selected primary address is not verified.
   - Updated `Memba.Membership.Person` aggregate:
     - `ReplacePersonEmailAddresses` now uses existing aggregate email-address state to determine verified vs pending;
     - legacy replacement events without `verified_at` still replay as verified for backwards compatibility.
   - Updated `Memba.Membership.Projectors.Person`:
     - replacement projection preserves `verified_at` when present, including `nil` for pending;
     - legacy replacement events still project as verified.
   - Updated tests for aggregate, public API, dispatch, and projection behavior.
   - Updated domain/browser acceptance setup helpers only, so legacy scenario fixture setup verifies addresses before using replace to change primary. No feature files were edited.
   - Checked off only todo `006`.

3. **Focused validation commands/results**
   - TDD pre-implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_test.exs test/memba/membership/public_api_test.exs`
     - Failed as expected with 4 failures showing new addresses were still verified and new primary was allowed.
   - Focused Membership suite:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_test.exs test/memba/membership/public_api_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/person_email_address_projection_test.exs`
     - Passed: `52 tests, 0 failures`.
   - Impacted projection/domain Cucumber tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_projection_test.exs test/features/domain_cucumber_acceptance_test.exs`
     - Passed: `96 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format ... --check-formatted`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `976 tests, 0 failures`.
   - Browser acceptance after JS helper fix:
     - `PATH="$PWD/bin:$PATH" dev acceptance features/person_email_addresses.feature`
     - Passed: `109 scenarios, 783 steps`.
   - Final full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including full browser acceptance: `109 scenarios, 783 steps`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Preserve or adapt ...`
   - To:
     - `- [x] 006 Preserve or adapt ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Preserves CQRS/event-sourcing boundaries: verification state is enforced in the Person aggregate and projected into the read model.
   - Maintains legacy event replay compatibility for existing `PersonEmailAddressesReplaced` events.
   - Does not introduce a new bounded context or Account model.
   - ADR 0015/0023 were read; this task did not add/change member LiveView routing or URL-addressable UI state.