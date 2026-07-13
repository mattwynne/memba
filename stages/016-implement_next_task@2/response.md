Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Model the write-side behaviour with explicit business commands/events rather than a generic replace-only edit.`

2. **Changes made**
   - Added write-side Person email-address state modelling in `web/lib/memba/membership/email_addresses.ex`:
     - `address_state` type with `verified_at`.
     - `mark_all_verified/2` for legacy/current create/replace compatibility.
     - `add_pending/2` for pending non-primary additions.
     - `verify/3` for still-pending address verification.
     - `make_primary/2` enforcing verified-only primary changes.
     - `remove_non_primary/2` preventing primary removal.
   - Updated `web/lib/memba/membership/person.ex` so rehydrated aggregate state records legacy/current create/replace addresses as verified using deterministic `~U[1970-01-01 00:00:00Z]`.
   - Added focused domain tests in:
     - `web/test/memba/membership/email_addresses_test.exs`
     - `web/test/memba/membership/person_test.exs`

3. **Validation commands and results**
   - TDD failure before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_addresses_test.exs`
     - Result: failed as expected with undefined transition functions.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_addresses_test.exs`
     - Result: `11 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_test.exs`
     - Result: `13 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/email_addresses_test.exs test/memba/membership/person_test.exs test/memba/membership/person_email_address_projection_test.exs test/memba/membership/public_api_test.exs`
     - Result: `51 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba/membership/email_addresses.ex lib/memba/membership/person.ex test/memba/membership/email_addresses_test.exs test/memba/membership/person_test.exs`
     - Result: passed
   - Final broad validation on the final working-tree diff:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `968 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Model the write-side behaviour with explicit business commands/events rather than a generic replace-only edit.`
   - To:
     - `- [x] 003 Model the write-side behaviour with explicit business commands/events rather than a generic replace-only edit.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: kept write-side behaviour in explicit domain/aggregate-side modelling rather than adding CRUD/projection-driven rules.
   - ADR 0007: changes remain inside the Membership bounded context; no Messaging mutation or cross-context leakage.
   - ADR 0009 / 0021: no custom projection plumbing or PubSub changes were introduced; projection behaviour remains projector-owned.
   - ADR 0011: no aggregate identity changes; Person remains routed by caller-generated `person_id`.
   - ADR 0015 / 0023: no UI/routes/LiveView state were touched in this non-UI task.