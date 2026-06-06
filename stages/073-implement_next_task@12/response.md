1. **Selected todo line**
   - `012 Implement conversion preparation with generated/editable slug using the same rules as staff club creation.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/requests_live/index.ex`:
     - Added conversion-preparation state to the admin requests LiveView.
     - Wired the existing Convert button to open a conversion-preparation panel.
     - Reused `MembaWeb.Admin.ClubSlugForm` for:
       - default slug suggestion from requested club name,
       - staff slug override/preservation,
       - slug validation,
       - slug availability feedback,
       - shared max length and feedback styling.
     - Added cancellation and stale/non-active request handling.
     - Ensured opening conversion clears rejection UI, and opening rejection clears conversion UI.
     - Added a disabled “Continue conversion” placeholder button; actual conversion remains for task 013.
   - Updated `web/test/memba_web/live/admin/requests_live/index_test.exs`:
     - Added tests proving conversion preparation:
       - opens from the active request inbox,
       - prepopulates club name,
       - generates the expected slug,
       - allows staff slug override and preserves it,
       - reports invalid slugs,
       - reports already-taken slugs using the same availability rules as staff club creation,
       - disables continuation when slug feedback is invalid/taken,
       - refreshes when the request is no longer active.
   - Updated `docs/iterations/022-request-to-club-onboarding/todo.md`:
     - Checked off task 012 only.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/requests_live/index.ex test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed.
   - Focused test command attempted:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/requests_live/index_test.exs`
     - Blocked by sandbox Postgres readiness/lock state during process startup.
   - Full required validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - `557 tests, 0 failures`
       - `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 012 Implement conversion preparation with generated/editable slug using the same rules as staff club creation.`
   - To:
     - `- [x] 012 Implement conversion preparation with generated/editable slug using the same rules as staff club creation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant accepted ADRs:
     - ADR 0001: Phoenix/LiveView/PostgreSQL core app — followed by implementing the staff workflow in the Phoenix LiveView app.
     - ADR 0013: PhoenixTest/feature-style web tests, with lower-level LiveView helpers allowed for LiveView mechanics — used LiveView tests for interactive form/state behaviour.
     - ADR 0015: LiveView for app surfaces — continued the existing LiveView-based admin request workflow.
   - Also followed local LiveView/HEEx guidance:
     - used `to_form` via shared `ClubSlugForm.to_form/1`,
     - used `<.form>` / `<.input>`,
     - added stable DOM IDs for tests,
     - reused the shared club slug form module rather than duplicating slug policy.