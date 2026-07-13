Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 A valid callback verifies the address, publishes a settings/read-model change notification, and renders Email verified, you can close this browser. Invalid/expired callbacks render a calm invalid/expired message.`

2. **Changes made**
   - Updated `PersonEmailAddressVerificationController.callback/2` to:
     - consume the email-address verification token;
     - verify the still-pending Person email address via `Membership.verify_person_email_address/2`;
     - use `consistency: :strong` so the Person projector commits and publishes the existing `Memba.ReadModelChanges` notification;
     - render success copy exactly: `Email verified, you can close this browser.`;
     - render invalid/expired links as a calm `422` page.
   - Updated the callback HEEx template to render dynamic success/invalid state, icon, heading, and message.
   - Expanded controller tests to cover:
     - valid token verifies the pending address;
     - verified address remains non-primary;
     - `Memba.ReadModelChanges` notification is published from the Person projector;
     - unknown token renders invalid/expired copy;
     - expired token does not verify the address.
   - Checked off only todo `013`.

3. **Validation commands run**
   - TDD failing test first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/person_email_address_verification_controller_test.exs`
     - Failed as expected before implementation.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/person_email_address_verification_controller_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/person_email_address_verification_controller.ex lib/memba_web/controllers/person_email_address_verification_html/callback.html.heex test/memba_web/controllers/person_email_address_verification_controller_test.exs`
     - Passed after applying formatter suggestions.
   - Final full validation on the exact final working tree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance tests: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 013 A valid callback verifies the address, publishes a settings/read-model change notification, and renders ...`
   - To:
     - `- [x] 013 A valid callback verifies the address, publishes a settings/read-model change notification, and renders ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0015 and ADR 0023.
   - This task remains a standalone public verification callback/confirmation page, not the `/my/settings` member application LiveView surface.
   - No client-side-only state or tab switching was introduced.
   - Verification state change goes through the Membership command/application path and the existing Person projector/read-model notification mechanism, consistent with the CQRS/event-sourcing architecture in the plan.