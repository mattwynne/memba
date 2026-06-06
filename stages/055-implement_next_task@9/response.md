Implemented the next unchecked task.

1. **Selected todo line**
   - `009 Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.`

2. **Changes made**
   - Added a `Requests` link to the Memba staff navigation in `Layouts.admin`.
   - Added `:requests` as an allowed active staff nav item.
   - Marked `/admin/requests` as the active nav item in `MembaWeb.Admin.RequestsLive.Index`.
   - Updated existing layout/admin LiveView tests to assert:
     - Requests appears with `href="/admin/requests"`.
     - Existing Clubs, People, Messages, and Deliveries links still appear.
     - Staff nav count is now 5.
   - Updated the existing browser acceptance step support so the “unavailable pages” check uses the known staff page list length instead of a hard-coded `4`.
   - Checked off only todo item `009`.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format ...` with web-relative paths: **passed**
   - Focused `bin/mix test ...` attempts were blocked by sandbox Postgres lock/PGHOST state, not by test failures.
   - First full `PATH="$PWD/bin:$PATH" dev check`: found the existing acceptance step hard-coded to 4 nav items; fixed it.
   - Final `PATH="$PWD/bin:$PATH" dev check`: **passed**
     - `552 tests, 0 failures`
     - `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check`: **passed**

4. **Todo check-off**
   - Changed:
     - `- [ ] 009 Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.`
   - To:
     - `- [x] 009 Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADR was explicitly referenced by the plan.
   - Inspected relevant accepted ADRs:
     - ADR 0003 for Cucumber/application-layer acceptance support.
     - ADR 0013 for Phoenix/PhoenixTest-style web coverage.
     - ADR 0015 for LiveView application page conventions.
   - No acceptance feature files were edited; only existing step support was updated to reflect the newly available staff navigation item.