Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Implement rejection with required internal notes and no requester email.`

2. **Changes made**
   - Added `Memba.Onboarding.change_rejection/2` for staff rejection form changesets.
   - Wired `/admin/requests` rejection UI:
     - Reject button opens a staff-only rejection panel.
     - Internal rejection notes are required.
     - Submit calls `Onboarding.reject_request/3` with the current staff email.
     - Successful rejection removes the request from the active inbox, decrements the active count, clears the panel, and shows a flash.
     - Stale/non-active request attempts refresh the inbox and show an error.
     - No requester email is sent.
   - Added LiveView test coverage proving:
     - Rejection panel/form opens.
     - Blank/whitespace notes are rejected.
     - Valid notes reject the request.
     - Request leaves the active inbox.
     - Rejection audit fields are stored.
     - No email is sent.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/onboarding.ex lib/memba_web/live/admin/requests_live/index.ex test/memba_web/live/admin/requests_live/index_test.exs` — passed.
   - Focused `bin/mix test test/memba_web/live/admin/requests_live/index_test.exs` was attempted but blocked by sandbox Postgres readiness/lock state.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `554 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `554 tests, 0 failures`
     - `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Implement rejection with required internal notes and no requester email.`
   - To:
     - `- [x] 011 Implement rejection with required internal notes and no requester email.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Inspected relevant accepted ADRs:
     - ADR 0001: Phoenix/PostgreSQL core app — followed.
     - ADR 0013: feature-style Phoenix web tests, with lower-level LiveView helpers allowed where needed — used LiveView-specific tests for LiveView mechanics.
     - ADR 0015: LiveView for interactive app surfaces — continued the existing LiveView admin request workflow.
   - Also followed local LiveView/form guidance: used `to_form/2`, `<.form>`, `<.input>`, stable element IDs, and LiveView streams for the request collection.