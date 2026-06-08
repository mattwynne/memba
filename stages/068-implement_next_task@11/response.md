Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Preserve existing staff onboarding: new Memba staff with no person record still enter a name and continue to the Staff area.`

2. **Changes made**
   - Added a focused end-to-end regression test in:
     - `web/test/memba_web/controllers/auth_controller_test.exs`
   - The new test proves first-time Memba staff can:
     - follow an auth sign-in token;
     - land on `/auth/onboard`;
     - enter their name;
     - create their staff person record;
     - continue to `/admin/clubs`;
     - see the Staff clubs index.

3. **Validation**
   - Initial attempt:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/auth_controller_test.exs test/memba_web/auth_gates_test.exs`
     - Failed due the known sandbox Postgres socket mismatch: `PGHOST=/tmp/devenv/postgres`.
   - Focused validation:
     - `devenv shell -- bin/mix test test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `23 tests, 0 failures`.
   - Adjacent auth gate validation:
     - `devenv shell -- bin/mix test test/memba_web/controllers/auth_controller_test.exs test/memba_web/auth_gates_test.exs`
     - Passed: `36 tests, 0 failures`.
   - Formatting:
     - `devenv shell -- bin/mix format --check-formatted test/memba_web/controllers/auth_controller_test.exs`
     - Passed.
   - Broad checks:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `706 tests, 0 failures`.
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `706 tests, 0 failures`; `62 scenarios (62 passed)`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 011 Preserve existing staff onboarding...`
     - to
     - `- [x] 011 Preserve existing staff onboarding...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Stayed within the Phoenix application.
   - ADR 0013: Added a user-facing PhoenixTest-style regression for the web onboarding journey.
   - ADR 0015: Preserved the existing LiveView onboarding flow.
   - ADR 0002/0009/0022: No new domain/projection write path was introduced; the existing onboarding flow continues through Membership APIs and is validated after the strong-write behavior already present in the app.