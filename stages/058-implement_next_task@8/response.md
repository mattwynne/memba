Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Store only a token hash plus Person/address scope (`person_id`, normalized email), expiry, and consumed/revoked state.`

2. **Changes made**
   - Updated `web/lib/memba/membership/email_address_verification_token.ex`
     - Added validation that `token_hash` must be a 32-byte SHA-256 digest.
     - This prevents plaintext/malformed token material from being accepted through the dedicated verification-token schema.
   - Updated `web/test/memba/membership/email_address_verification_token_test.exs`
     - Strengthened the storage-contract test to assert the exact allowed columns:
       - `id`, `person_id`, `normalized_email`, `token_hash`, `expires_at`, `consumed_at`, `revoked_at`, `inserted_at`, `updated_at`
     - Added a regression test proving plaintext-like token material is rejected.

3. **Focused validation run**
   - TDD failing test first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_address_verification_token_test.exs`
     - Failed as expected before implementation: malformed `"plaintext-token"` was accepted.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_address_verification_token_test.exs test/memba/release_test.exs`
     - Passed: `7 tests, 0 failures`
   - Formatting:
     - `cd web && mix format lib/memba/membership/email_address_verification_token.ex test/memba/membership/email_address_verification_token_test.exs --check-formatted`
     - Passed
   - Broad quick validation on final working tree:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `982 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Store only a token hash plus Person/address scope (`person_id`, normalized email), expiry, and consumed/revoked state.`
   - To:
     - `- [x] 009 Store only a token hash plus Person/address scope (`person_id`, normalized email), expiry, and consumed/revoked state.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0015 and ADR 0023 as explicitly referenced by the plan.
   - This task is persistence/schema-validation only, so it does not alter member LiveView surfaces, routing, or URL-addressable state.
   - The implementation stays within the existing Membership/Person email-address model and does not introduce an Account aggregate or new bounded context.