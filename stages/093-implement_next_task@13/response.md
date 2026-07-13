Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `014 Update sign-in callback handling so a successful sign-in link for a pending known Person email address marks that address verified without making it primary or changing the Person session semantics.`

2. **Changes made**
   - Added `Membership.verify_pending_person_email_address_for_sign_in/2`.
     - Safe no-op for invalid, unknown, or already-verified addresses.
     - Dispatches the existing `verify_person_email_address` Membership command for pending Person email addresses.
   - Updated `MembaWeb.AuthController.callback/2` to verify a pending email address after consuming a valid sign-in token and before logging the identity in.
   - Added an auth controller test proving that:
     - a sign-in link for a pending known alternate email verifies that address;
     - the verified pending address remains non-primary;
     - the existing primary address remains primary;
     - the browser session remains the normal signed-in identity session.
   - Checked off only todo `014`.

3. **Validation commands run**
   - TDD failing test first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/auth_controller_test.exs`
     - Failed as expected before implementation because the pending email stayed unverified.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `33 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format lib/memba/membership.ex lib/memba_web/controllers/auth_controller.ex test/memba_web/controllers/auth_controller_test.exs`
     - Completed successfully.
   - Broad quick validation on final diff:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `994 tests, 0 failures`.
   - Full validation on final diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 014 Update sign-in callback handling so a successful sign-in link for a pending known Person email address marks that address verified without making it primary or changing the Person session semantics.`
   - To:
     - `- [x] 014 Update sign-in callback handling so a successful sign-in link for a pending known Person email address marks that address verified without making it primary or changing the Person session semantics.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0015 and ADR 0023 as referenced by the plan.
   - This task did not introduce member application UI, LiveView routing, or client-side state.
   - The state change goes through the Membership application service and existing explicit verification command/event path, preserving CQRS/event-sourcing boundaries and avoiding controller-side projection mutation.