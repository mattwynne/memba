Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Verification tokens are one-use, scoped to the still-pending Person/address pair, expire on a short TTL aligned with sign-in links unless implementation finds an existing project constant to reuse, and cannot verify removed/replaced addresses.`

2. **Changes made**
   - `web/lib/memba/membership.ex`
     - Added `consume_person_email_address_verification_token/2`.
     - Changed the default email-address verification issuer to persist a hashed token in the dedicated verification-token table.
     - Set verification token TTL to `15 * 60` seconds, aligned with sign-in links.
     - Changed the default removed-address verification revoker to revoke outstanding token rows.
     - Kept direct token persistence out of `Membership` to satisfy the existing no-CRUD architecture guard.
   - `web/lib/memba/membership/email_address_verification_token.ex`
     - Added token lifecycle store operations:
       - insert;
       - locked consume;
       - revoked/consumed/expired checks;
       - revocation for pending Person/address tokens.
     - Added consume/revoke changesets.
   - `web/test/memba/membership/public_api_test.exs`
     - Added coverage proving:
       - default resend stores a scoped hashed 15-minute token;
       - tokens consume once only;
       - expired tokens are rejected;
       - tokens for already-verified/non-pending addresses are rejected;
       - tokens for removed and re-added pending addresses are revoked and cannot verify the new pending row.

3. **Validation run**
   - TDD failing test first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs`
     - Failed as expected because the default issuer returned an unstored token and `consume_person_email_address_verification_token/2` did not exist.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/membership/email_address_verification_token_test.exs`
     - Passed: `31 tests, 0 failures`.
   - Architecture guard and focused tests after refactor:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/membership/email_address_verification_token_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Passed: `35 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format lib/memba/membership.ex lib/memba/membership/email_address_verification_token.ex test/memba/membership/public_api_test.exs --check-formatted`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `985 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Verification tokens are one-use, scoped to the still-pending Person/address pair, expire on a short TTL aligned with sign-in links unless implementation finds an existing project constant to reuse, and cannot verify removed/replaced addresses.`
   - To:
     - `- [x] 010 Verification tokens are one-use, scoped to the still-pending Person/address pair, expire on a short TTL aligned with sign-in links unless implementation finds an existing project constant to reuse, and cannot verify removed/replaced addresses.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0015 and ADR 0023 as required by the plan.
   - This task is Membership/domain-token lifecycle work only; it does not add or alter member LiveViews, routes, URL-addressable UI state, or client-side tab behavior.
   - The implementation stays within the existing Membership/Person email-address model and does not introduce an Account aggregate or new bounded context.