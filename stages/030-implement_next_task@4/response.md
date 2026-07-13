Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Resend verification is an application-service action that issues a fresh verification token/email for an already-pending address and should not create a new domain event unless the pending-address state changes.`

2. **Changes made**
   - Added `Memba.Membership.resend_person_email_address_verification/2`.
   - The new application-service action:
     - validates `person_id`;
     - normalizes the submitted email;
     - looks up the projected Person email-address row;
     - only proceeds when the address still belongs to that Person and is pending (`verified_at == nil`);
     - rejects already-verified addresses before issuing;
     - invokes an injectable verification issuer for fresh verification-token/email issuance;
     - does **not** dispatch a Membership command or append a domain event.
   - Added a default fresh token issuer using the existing opaque token generator boundary, while leaving the dedicated persisted token store/template work to the later explicit todo items.
   - Added tests proving:
     - pending address resend invokes the issuer with Person/address scope;
     - resend leaves the pending row pending;
     - resend appends no EventStore domain event;
     - verified addresses are rejected before issuer invocation.

3. **Focused validation**
   - TDD pre-implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs`
     - Failed as expected with `Memba.Membership.resend_person_email_address_verification/2 is undefined`.
   - Formatting:
     - `cd web && mix format lib/memba/membership.ex test/memba/membership/public_api_test.exs --check-formatted`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/membership/person_email_address_projection_test.exs test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs`
     - Result: `50 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `974 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Resend verification is an application-service action that issues a fresh verification token/email for an already-pending address and should not create a new domain event unless the pending-address state changes.`
   - To:
     - `- [x] 005 Resend verification is an application-service action that issues a fresh verification token/email for an already-pending address and should not create a new domain event unless the pending-address state changes.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: modeled resend as an application-service side effect, not a domain event, because pending state does not change.
   - ADR 0007: kept the behavior inside the Membership bounded context.
   - ADR 0008/0009: verified no new EventStore event/projection change is produced for resend.
   - ADR 0011: continued using caller-supplied typed Person IDs.
   - ADR 0016: preserved email-provider indirection by using an issuer seam rather than direct provider HTTP code.