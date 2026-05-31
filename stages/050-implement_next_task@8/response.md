Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Update the home page:`

2. **Changes made**
   - Updated `/` home page behavior:
     - Unauthenticated visitors still see the existing marketing page.
     - Signed-in users now see a “My clubs” page.
     - Active member clubs are listed from the existing `current_identity_clubs` assign.
     - Club links include `?club_id=<uuid>` query strings.
     - Signed-in `@memba.io` staff see an Admin link to `/admin/clubs`.
     - Signed-in users who are both staff and members see both their clubs and Admin access.
   - Updated page title:
     - Signed-in: `My clubs`
     - Unauthenticated: existing `Membership made calm`
   - Added focused controller tests for:
     - signed-in member clubs and query-string club links,
     - staff Admin link,
     - staff-member combined view.

3. **Validation commands run**
   - `cd web && mix format`
     - Passed.
   - Initial direct focused test attempt:
     - `cd web && mix test test/memba_web/controllers/page_controller_test.exs`
     - Could not run because Postgres was not available outside the devenv service environment.
   - Focused test rerun inside devenv/Postgres wrapper:
     - `mix test test/memba_web/controllers/page_controller_test.exs`
     - Passed: `8 tests, 0 failures`.
   - Required full check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `183 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Update the home page:`
   - To:
     - `- [x] 008 Update the home page:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / project conformance**
   - Used existing Phoenix controller/template patterns.
   - Reused `MembaWeb.UserAuth` assigns and `Memba.Accounts`/membership-derived identity data instead of coupling the template to storage queries.
   - Added focused Phoenix controller tests; no acceptance `.feature` files were changed.
   - No new HTTP client usage introduced.