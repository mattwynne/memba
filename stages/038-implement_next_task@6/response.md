Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_controller.ex`
     - Signed-out `POST /get-started` request-detail submissions now return to the email verification step with `422` instead of creating an onboarding request.
     - Verified/signed-in identities without an existing Person now submit requests using `current_identity.email`.
     - Any submitted `requester_email` parameter is ignored for Staff-visible onboarding requests.
     - Existing signed-in Person behaviour still uses the known Person name/email and ignores typed requester identity fields.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`
     - Replaced old signed-out request submission coverage with a test proving signed-out detail submissions do not create requests or send email.
     - Added coverage proving a signed-in identity without a Person can submit a request, while a forged typed email is ignored.
     - Preserved acknowledgement coverage for verified submissions.

3. **Validation commands/results**
   - TDD failure observed before implementation:
     - `bin/mix test test/memba_web/controllers/page_controller_test.exs:1105 test/memba_web/controllers/page_controller_test.exs:1134 --seed 0`
     - Failed as expected: signed-out request still created a record; signed-in no-Person request trusted typed email.
   - Focused tests after implementation:
     - `bin/mix test test/memba_web/controllers/page_controller_test.exs:1105 test/memba_web/controllers/page_controller_test.exs:1131 test/memba_web/controllers/page_controller_test.exs:1186 --seed 0`
     - Passed: `39 tests, 0 failures, 36 excluded`
   - Formatting:
     - `bin/mix format --check-formatted lib/memba_web/controllers/page_controller.ex test/memba_web/controllers/page_controller_test.exs`
     - Passed
   - Full controller test file:
     - `bin/mix test test/memba_web/controllers/page_controller_test.exs --seed 0`
     - Passed: `39 tests, 0 failures`
   - Broad non-browser check:
     - `dev check --quick`
     - Passed: `746 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Passed
   - Full browser-facing check attempted:
     - `dev check`
     - Failed in acceptance tests because existing browser request-account plumbing still expects the old signed-out request form. That is already covered by later tasks `013–014`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.`
   - To:
     - `- [x] 006 Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: changes stay within the Phoenix web application.
   - ADR 0013: used focused controller/LazyHTML tests for controller-rendered Get Started behaviour.
   - ADR 0010: did not edit shared acceptance feature files; acceptance plumbing remains for the later planned tasks.