1. **Selected todo line**
   - `008 Add staff /admin/requests route and LiveView under existing staff authentication.`

2. **Changes made**
   - Added `MembaWeb.Admin.RequestsLive.Index` as a minimal staff-only admin LiveView at:
     - `web/lib/memba_web/live/admin/requests_live/index.ex`
   - Wired the route inside the existing staff admin scope/session:
     - `live "/requests", RequestsLive.Index`
     - This uses the existing `:staff_browser` pipeline and `:memba_staff` LiveSession auth.
   - Added/updated tests:
     - Router test proves `/admin/requests` routes to `MembaWeb.Admin.RequestsLive.Index` through the staff browser pipeline.
     - Auth gate tests prove `/admin/requests`:
       - redirects signed-out users to `/auth` and preserves return path;
       - forbids signed-in non-staff users;
       - redirects first-time staff to onboarding;
       - allows onboarded staff.
     - LiveView test proves staff can mount the page and sees the expected admin page shell.
   - Checked off only the selected todo line.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format ...`
     - Passed.
   - Attempted focused tests with `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Blocked before tests ran by sandbox Postgres lock/socket state.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `552 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `552 tests, 0 failures`.
     - Acceptance passed: `38 scenarios (38 passed), 252 steps (252 passed)`.
   - `git diff --check`
     - Passed.
   - Explicit whitespace check for new untracked files
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 008 Add staff /admin/requests route and LiveView under existing staff authentication.`
   - To:
     - `- [x] 008 Add staff /admin/requests route and LiveView under existing staff authentication.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No `docs/adr/` files are present in this checkout.
   - Kept the change within the existing Phoenix router/admin LiveView structure.
   - Reused the existing staff auth pipeline and LiveSession rather than introducing a separate authorization path.
   - Did not implement later-scope work such as navigation, inbox listing, rejection, conversion, or welcome-email behavior.