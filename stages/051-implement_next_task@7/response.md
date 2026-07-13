Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Add a dedicated email-address verification-token store rather than overloading auth_sign_in_tokens.`

2. **Changes made**
   - Added migration:
     - `web/priv/repo/migrations/20260713181757_create_membership_person_email_address_verification_tokens.exs`
     - Creates dedicated table `membership_person_email_address_verification_tokens`.
   - Added schema:
     - `web/lib/memba/membership/email_address_verification_token.ex`
     - Dedicated Membership-owned Ecto schema, explicitly not using `auth_sign_in_tokens`.
   - Updated release schema verification:
     - `web/lib/memba/release.ex`
     - Includes the new schema in required release schema checks.
   - Added tests:
     - `web/test/memba/membership/email_address_verification_token_test.exs`
     - Proves the dedicated source table, hash-only token material, indexing, and persistence through the dedicated schema.

3. **Validation commands run**
   - TDD pre-implementation failure:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_address_verification_token_test.exs`
     - Failed as expected because the schema did not exist.
   - Focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_address_verification_token_test.exs`
     - Passed: `4 tests, 0 failures`.
   - Focused + release schema tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_address_verification_token_test.exs test/memba/release_test.exs`
     - Passed: `6 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format lib/memba/membership/email_address_verification_token.ex lib/memba/release.ex priv/repo/migrations/20260713181757_create_membership_person_email_address_verification_tokens.exs test/memba/membership/email_address_verification_token_test.exs --check-formatted`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `981 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios, 783 steps`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Add a dedicated email-address verification-token store rather than overloading auth_sign_in_tokens.`
   - To:
     - `- [x] 008 Add a dedicated email-address verification-token store rather than overloading auth_sign_in_tokens.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Keeps verification-token persistence in the existing Membership/Person email-address model; no Account aggregate or new bounded context introduced.
   - Does not alter LiveView/member routing, so ADR 0015 and ADR 0023 remain unaffected for this slice.
   - Uses Ecto migration/schema conventions and keeps release schema verification aligned with production migration safety.