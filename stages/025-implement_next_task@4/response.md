Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 004 Add Cucumber step definitions for all Background lines in both feature`

2. **Changes made**
   - Expanded `web/test/features/step_definitions/membership_steps.exs` with Cucumber steps for the plan-listed Membership Background lines:
     - `Kootenay Mountaineering Club is a club`
     - `Nelson Paddling Club is a club`
     - `Alice, Bob, and Carol are people`
     - `Alice and Bob are people`
     - `Pat is a person`
     - `Alice, Bob, and Carol are members of Kootenay Mountaineering Club`
     - `Alice and Bob are members of Kootenay Mountaineering Club`
     - `Pat is a member of Nelson Paddling Club`
   - The steps dispatch real Membership commands and verify results through `Memba.Membership` query APIs.
   - Updated `web/test/features/cucumber_configuration_test.exs` to discover and execute the Membership Background step sequences for both shared feature files, then assert active membership results.

3. **Validation**
   - `cd web && mix test test/features/cucumber_configuration_test.exs`
     - Failed because it was run outside the dev-managed Postgres environment.
   - `cd web && mix format --check-formatted`
     - Passed after formatting fixes.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Final run: `53 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add Cucumber step definitions for all Background lines in both feature`
   - To:
     - `- [x] 004 Add Cucumber step definitions for all Background lines in both feature`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Kept work inside Membership; no Messaging context or direct cross-context storage access added.
   - ADR 0010: Step definitions remain under `web/test/features/step_definitions/**/*.exs` and use shared feature files from `acceptance-tests/features/**/*.feature`.
   - ADR 0011: Steps generate caller-supplied UUIDs before dispatching Membership commands.