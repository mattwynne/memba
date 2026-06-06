1. **Selected todo line**
   - `005 Implement signed-out /get-started form with required-field and email validation.`

2. **Changes made**
   - Replaced the signed-out `/get-started` mailto-only page with a hosted request form.
   - Added `POST /get-started` routing and controller handling.
   - Added `Memba.Onboarding.change_request/2` for form changesets.
   - On successful submission:
     - creates an active onboarding request;
     - redirects to `/get-started?submitted=true`;
     - shows an acknowledgement explaining staff will review the request;
     - does not create clubs or memberships.
   - On invalid submission:
     - returns `422`;
     - preserves validation errors for required fields and invalid email shape.
   - Updated page controller tests for:
     - signed-out form rendering;
     - required-field validation;
     - invalid email rejection;
     - durable request creation;
     - no immediate club/membership creation;
     - acknowledgement display.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `544 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `544 tests, 0 failures`;
     - acceptance passed: `38 scenarios (38 passed), 252 steps (252 passed)`.
   - `git diff --check`
     - Passed.
   - Note: direct `bin/mix test test/memba_web/controllers/page_controller_test.exs` hit the local wrapper/Postgres socket startup issue, but the same test suite passed through `dev check`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Implement signed-out /get-started form with required-field and email validation.`
   - To:
     - `- [x] 005 Implement signed-out /get-started form with required-field and email validation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: uses Phoenix controller/routes/templates and PostgreSQL-backed persistence.
   - ADR 0002: continues using the explicitly documented onboarding-request Ecto exception while leaving club/person/membership lifecycle untouched.
   - ADR 0013: adds user-facing web tests around form rendering, submission, validation, and outcomes.
   - ADR 0015: this is a public marketing/onboarding page, so controller-rendered HTML remains appropriate; no member application LiveView surface was added.