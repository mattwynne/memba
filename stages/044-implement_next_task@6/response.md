1. **Selected todo line**
   - `006 Update/remove "opened" assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.`

2. **Changes made for this task**
   - Removed/replaced `"opened"` test fixtures and assertions from affected ExUnit suites:
     - Member dashboard/message-detail/member-message LiveView tests now use tracked statuses only.
     - Member email delivery presentation tests no longer assert unsupported `"opened"` presentation behavior.
     - Postmark/Resend webhook controller tests no longer include open-event rejection branches or payload helpers.
     - Staff deliveries and projection query tests no longer seed/assert unsupported `"opened"` rows.
     - Removed the status-report API absence assertion and the cucumber config “no opened receipts” grep-style test.
   - Cleaned acceptance JS step/support files:
     - Removed open-email step definitions.
     - Removed `"opened"` mappings from Postmark payload generation, member receipt status mapping, staff delivery status mapping, and icon mapping.
     - Removed acceptance unit coverage for opened-specific helper behavior.
   - Checked off only todo `006`.

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed after removing formatting-only blank-line drift.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Passed: Cucumber step definitions load; `82 scenarios`, `493 steps` skipped in dry-run.
   - `cd acceptance-tests && npm run test:config`
     - Passed: `48 tests`, `0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `798 tests`, `0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: ExUnit `798 tests`, `0 failures`; acceptance `82 scenarios`, `493 steps`, all passed.
   - Note: direct targeted `bin/mix test ...` initially hit a sandbox Postgres socket/env readiness issue; the broader `dev check --quick` and full `dev check` both started the environment correctly and passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 006 Update/remove "opened" assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.`
   - To:
     - `- [x] 006 Update/remove "opened" assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADR files.
   - The changes preserve the current supported delivery vocabulary (`sent`, `delivered`, `delivery problem`, plus staff-specific delivery problem details) and remove only test/support expectations for the deprecated `"opened"` status.
   - Remaining `opened` references in tests are limited to existing replay-shim coverage from earlier completed work, not active product/status behavior.