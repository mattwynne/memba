Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 016 Run targeted tests for affected auth/membership/onboarding surfaces, then run dev check.`

2. **Changes made**
   - No code/config/test changes were needed.
   - Checked off only the final validation task in:
     - `docs/iterations/028-staff-member-invitations/todo.md`

3. **Validation run**
   - Initial per-file `bin/mix test ...` attempts hit sandbox Postgres environment/socket issues, so I switched to the project-supported wrapper.
   - Passed:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
       - `721 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" npm test --prefix acceptance-tests -- --dry-run`
       - `69 scenarios (69 skipped)`, `466 steps (466 skipped)`
     - `PATH="$PWD/bin:$PATH" node --test acceptance-tests/test/cucumber_config.test.js`
       - `4 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev acceptance features/club_member_invitations.feature`
       - Passed; current Cucumber config merges configured paths with CLI paths, so this executed the selected acceptance suite:
       - `69 scenarios passed`, `466 steps passed`
     - `PATH="$PWD/bin:$PATH" dev check`
       - `721 tests, 0 failures`
       - `69 scenarios passed`, `466 steps passed`

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 016 Run targeted tests for affected auth/membership/onboarding surfaces, then run dev check.`
   - To:
     - `- [x] 016 Run targeted tests for affected auth/membership/onboarding surfaces, then run dev check.`

5. **Todo splits/additions/reordering**
   - None.
   - Verified there are no remaining unchecked todo lines.

6. **ADR conformance**
   - The plan did not explicitly reference any ADRs.
   - This task was validation-only and conforms to the iteration validation plan: targeted affected-surface checks plus full `dev check`.
   - Final working tree change is limited to the intended todo check-off.