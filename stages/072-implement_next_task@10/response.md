Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Add a general verification email template using existing transactional email delivery conventions.`

2. **Changes made**
   - Added `web/lib/memba/membership/person_email_address_verification_email.ex`
     - New `Memba.Membership.PersonEmailAddressVerificationEmail` delivery module.
     - Uses existing Swoosh/Mailer conventions.
     - Uses `Memba.Accounts.AuthEmailConfig` for auth-style sender/message stream configuration.
     - Uses shared `Memba.EmailTemplates` shell, Memba header/footer, trust footer, primary action button, escaped fallback URL.
     - Provides general copy and subject:
       - `Verify this email address for your Memba account`
     - Supports Postmark-style `:message_stream` provider option.
     - Supports Resend tags:
       - `memba_email_kind=person_email_address_verification`
       - `memba_auth_email_stream=...`
       - optional `memba_person_id=...`
     - Validates recipient email and verification URL before Swoosh handoff.
   - Added `web/test/memba/membership/person_email_address_verification_email_test.exs`
     - Covers successful delivery, HTML/text copy, URL escaping, provider options/tags, invalid inputs, and missing config.
   - Checked off only the selected todo line.

3. **Focused validation run**
   - TDD failing test first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_email_address_verification_email_test.exs`
     - Failed as expected because `Memba.Membership.PersonEmailAddressVerificationEmail` did not exist yet.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_email_address_verification_email_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Related email regression tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_email_address_verification_email_test.exs test/memba/membership/club_member_invitation_email_test.exs test/memba/accounts/auth_email_test.exs test/memba/email_templates_test.exs`
     - Passed: `26 tests, 0 failures`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba/membership/person_email_address_verification_email.ex test/memba/membership/person_email_address_verification_email_test.exs`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `990 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 011 Add a general verification email template using existing transactional email delivery conventions.`
   - To:
     - `- [x] 011 Add a general verification email template using existing transactional email delivery conventions.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0015 and ADR 0023 as referenced by the plan.
   - This task only adds a transactional email delivery/template module; it does not add member routes, LiveViews, URL-addressable UI state, or client-side tab behavior.
   - The implementation stays within the existing Membership/Person email-address model and does not introduce an Account aggregate or new bounded context.