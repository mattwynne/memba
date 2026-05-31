Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Make diagnostics actionable: separate errors for Phoenix readiness, database setup, webhook HTTP failures, timeout waiting for projected UI state, and final assertion mismatches.`

2. **Changes made**
   - Updated `acceptance-tests/features/support/lifecycle.js`
     - Wraps database setup command failures with a distinct `Database setup failed while ...` diagnostic.
     - Leaves existing Phoenix startup/readiness diagnostics intact and separate.
   - Updated `acceptance-tests/features/support/member_message.js`
     - Added browser interaction diagnostics: `Browser interaction failed: ...`
     - Added final assertion mismatch diagnostics: `Assertion mismatch: ...`
     - Renamed projection wait failures to a distinct `Projection timing timeout: ...`
     - Added request-transport handling for Postmark webhook submission failures while preserving HTTP status/body diagnostics.
   - Updated tests:
     - `acceptance-tests/test/lifecycle.test.js`
       - Added coverage for database setup failure diagnostics.
     - `acceptance-tests/test/member_message_steps.test.js`
       - Added coverage for browser interaction diagnostics.
       - Added coverage for final assertion mismatch diagnostics.
       - Added coverage for projection timing diagnostics.

3. **Focused validation**
   - `cd acceptance-tests && npm run test:config`
     - Passed: `23` tests, `0` failures.
   - `cd acceptance-tests && npm test -- --dry-run --name "A delivered message is shown as delivered"`
     - Passed dry run: scenario matched, no undefined steps.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `109` tests, `0` failures.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 008 Make diagnostics actionable: separate errors for Phoenix readiness, database setup, webhook HTTP failures, timeout waiting for projected UI state, and final assertion mismatches.`
   - To:
     - `- [x] 008 Make diagnostics actionable: separate errors for Phoenix readiness, database setup, webhook HTTP failures, timeout waiting for projected UI state, and final assertion mismatches.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / 0010: Shared `.feature` files were not changed; this only improves browser-layer harness/step diagnostics.
   - ADR 0009: Projection consistency remains harness-level waiting/diagnostics only; no production consistency semantics changed.
   - ADR 0006 / 0012: Member-facing delivery status vocabulary and opened semantics were not changed.
   - Domain acceptance path and product behavior remain untouched.