Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Add or adjust layout functions in MembaWeb.Layouts:`

2. **Changes made**
   - Added `Layouts.admin/1` with Memba-branded staff/admin chrome and admin nav links.
   - Added `Layouts.club_site/1` as a future white-label seam using neutral slate CSS custom property defaults.
   - Kept `Layouts.app/1` as the public Memba-branded layout.
   - Switched existing admin LiveViews to wrap their content in `Layouts.admin`.
   - Added component tests for public/admin/club-site layout seams.
   - Added LiveView assertions that admin pages render the admin layout chrome.

3. **Validation**
   - Attempted focused `dev test ...`; `dev` has no `test` subcommand, so no repo state changed from that.
   - Ran `PATH="$PWD/bin:$PATH" dev check`
     - First run failed due a syntax issue in the new layout test.
     - Fixed the syntax issue.
   - Re-ran `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `135 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 004 Add or adjust layout functions in MembaWeb.Layouts:`
   - To:
     - `- [x] 004 Add or adjust layout functions in MembaWeb.Layouts:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 respected: kept the implementation in Phoenix/Phoenix LiveView.
   - ADR 0013 respected: added web/layout coverage using Phoenix-compatible test helpers; no acceptance feature files were changed.
   - No temporary club resolver or member-facing production routes were introduced.