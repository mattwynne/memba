1. **Selected todo line**
   - `003 Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_controller.ex`:
     - signed-out `POST /get-started` with `verification[email]` now:
       - validates the email address;
       - creates a sign-in token via `Accounts.create_sign_in_token/1` so unknown public requesters can verify;
       - sends the existing auth sign-in email via `AuthEmail.deliver_sign_in_link/2`;
       - includes `return_to=/get-started` on the magic-link callback URL;
       - redirects to the existing `/auth/check-email` acknowledgement.
     - invalid verification email re-renders the Get Started verification form with a 422 and flash.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`:
     - added coverage that signed-out verification sends an auth magic link with `return_to=/get-started`;
     - added coverage that invalid verification email creates no token/request/email.
   - Updated `docs/iterations/030-verified-onboarding-requests/todo.md` to check off task 003 only.

3. **Focused validation**
   - Passed:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/controllers/page_controller.ex test/memba_web/controllers/page_controller_test.exs`
     - `git diff --check`
     - `PATH="/nix/store/vly1mpb0rah7xr34ybcf3s339cjh22vh-postgresql-17.9/bin:$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/page_controller_test.exs --seed 0`
       - Result: `37 tests, 0 failures`
   - Also ran required full browser-facing validation:
     - `PATH="/nix/store/vly1mpb0rah7xr34ybcf3s339cjh22vh-postgresql-17.9/bin:$PWD/bin:$PATH" dev check`
     - Result: still fails in acceptance with `73 scenarios (1 failed, 72 passed)`.
     - The failure is the known pending acceptance plumbing still expecting the old signed-out `#get-started-request-form`; later unchecked tasks cover Cucumber/flow updates.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.`
   - To:
     - `- [x] 003 Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR is explicitly referenced by this iteration plan.
   - Inspected relevant accepted ADRs:
     - ADR 0001: stayed within Phoenix controller/web delivery.
     - ADR 0013: lower-level controller tests are appropriate here because this task verifies controller POST behaviour, token creation, email delivery, and callback URL internals.
   - Reused existing auth token/email modules rather than introducing a new auth mechanism.