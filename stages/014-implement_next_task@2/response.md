1. **Selected todo line**
   - `002 Split the public Get Started experience into two states:`

2. **Changes made**
   - Updated `/get-started` rendering to branch by sign-in state:
     - signed-out visitors now see an email-only verification form: `#get-started-verification-form`;
     - signed-in identities now see the request form: `#get-started-request-form`.
   - Added controller assigns for:
     - `signed_in_get_started?`
     - `verification_form`
   - Updated the HEEx template copy and structure to explain the email verification-first state.
   - Added a signed-in/no-Person identity panel showing the verified email.
   - Updated controller tests for:
     - signed-out email-only state;
     - signed-in identity without Membership Person showing the request form;
     - existing signed-in Person staying on the request form;
     - invalid signed-out POSTs re-rendering the verification state.
   - Checked off only todo 002.

3. **Focused validation**
   - Passed:
     - `bin/mix format --check-formatted lib/memba_web/controllers/page_controller.ex test/memba_web/controllers/page_controller_test.exs`
     - focused controller test file: `35 tests, 0 failures`
     - `git diff --check`
   - Also ran required full UI validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - ExUnit passed: `742 tests, 0 failures`
     - Acceptance currently fails: `73 scenarios (1 failed, 72 passed)`
     - The failing acceptance plumbing still waits for the old signed-out `#get-started-request-form`, which this task intentionally replaced with the email-only verification form. That is expected to be addressed by later iteration tasks for magic-link flow and Cucumber step updates.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Split the public Get Started experience into two states:`
   - To:
     - `- [x] 002 Split the public Get Started experience into two states:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR is explicitly referenced by the plan.
   - Changes stayed within the Phoenix controller/HEEx template path identified by task 001 inspection.
   - Followed local Phoenix/HEEx guidance:
     - used `<.form>` / `<.input>`;
     - kept unique DOM IDs for testable forms/buttons;
     - avoided LiveView/routing changes;
     - preserved Staff/domain behaviour for later tasks.