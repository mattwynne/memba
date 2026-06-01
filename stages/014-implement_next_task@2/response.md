Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Add member acceptance support:`

2. **Changes made**
   - Added `acceptance-tests/features/support/member_harness.js` with:
     - `withStaffHarness(world, action)` preserving staff/admin setup harness behaviour for `Given` setup steps.
     - `withMemberHarness(world, memberName, action)` creating an isolated browser context, signing in by magic link using the named member’s scenario email, then running member actions.
     - Member-route guard helpers:
       - `memberBrowserAction(...)`
       - `assertMemberPageIsNotAdmin(...)`
       - internal guarded `page.goto(...)` convention that fails fast on `/admin/*`.
   - Refactored `acceptance-tests/features/step_definitions/member_message_steps.js` to use the shared `withStaffHarness` support helper without changing existing staff setup semantics.
   - Added `acceptance-tests/test/member_harness.test.js` covering:
     - member magic-link sign-in using the member email;
     - shared scenario state propagation;
     - isolated context cleanup;
     - fast failure on `/admin/*` navigation;
     - final-state guard against member helpers ending on `/admin/*`.

3. **Focused validation**
   - `cd acceptance-tests && HOME="$PWD/.home" npm_config_cache="$PWD/.npm" npm ci`
     - Passed.
   - `cd acceptance-tests && node --test test/member_harness.test.js test/member_message_steps.test.js`
     - Passed: `19` tests, `0` failures.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Passed: Cucumber support/step definitions loaded; `17` scenarios skipped due dry run/current tags.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `203 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add member acceptance support:`
   - To:
     - `- [x] 002 Add member acceptance support:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / ADR 0010: kept shared feature files unchanged and added browser-runner plumbing only in support/step-definition code.
   - Staff/admin setup remains available for setup steps, while member harness support is ready for later member-facing `When`/`Then` steps.
   - The new guard convention enforces the plan’s separation between member assertions/actions and `/admin/*` operator routes.
   - No internal delivery projection/status values or staff diagnostics were changed.