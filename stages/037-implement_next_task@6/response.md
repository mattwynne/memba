1. **Selected todo line**
   - `006 Implement signed-in /get-started behaviour using the current person’s known name/email as read-only request details.`

2. **Changes made**
   - Updated `/get-started` rendering so signed-in requesters with a matching `Membership` person see their known name/email as read-only details.
   - Signed-in requesters now only fill in:
     - club name
     - short note
   - Updated `POST /get-started` so signed-in submissions:
     - derive `requester_name` from `Memba.Membership.get_person_by_email/1`;
     - derive `requester_email` from the current signed-in identity email;
     - store `requester_person_id`;
     - ignore any submitted/forged name or email fields.
   - Added controller tests proving:
     - signed-in identity details are rendered read-only;
     - name/email inputs are absent for signed-in requesters;
     - signed-in submissions store current person details, not submitted identity params;
     - no club or membership is created by the request.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/page_controller_test.exs`
     - Could not run directly due local Postgres wrapper/socket lock issue.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `546 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `546 tests, 0 failures`;
     - acceptance passed: `38 scenarios (38 passed), 252 steps (252 passed)`.
   - Re-ran `PATH="$PWD/bin:$PATH" dev check` after final todo check-off:
     - Passed again with the same results.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Implement signed-in /get-started behaviour using the current person’s known name/email as read-only request details.`
   - To:
     - `- [x] 006 Implement signed-in /get-started behaviour using the current person’s known name/email as read-only request details.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: kept the behaviour in Phoenix controller-rendered HTML backed by PostgreSQL/Ecto request persistence.
   - ADR 0002: continued using the approved Onboarding Ecto request model exception; no new CRUD workflow was added to Membership.
   - ADR 0013: added user-facing web tests around the rendered form and submitted behaviour.
   - ADR 0015: `/get-started` remains a public onboarding/marketing surface, so controller-rendered HTML remains appropriate.