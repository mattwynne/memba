Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Add individual Membership commands/events for adding a pending email address, verifying an email address, making a verified address primary, and removing a non-primary address.`

2. **Changes made**
   - Added individual Membership command modules:
     - `AddPersonEmailAddress`
     - `VerifyPersonEmailAddress`
     - `MakePersonEmailAddressPrimary`
     - `RemovePersonEmailAddress`
   - Added corresponding domain event modules:
     - `PersonEmailAddressAdded`
     - `PersonEmailAddressVerified`
     - `PersonPrimaryEmailAddressChanged`
     - `PersonEmailAddressRemoved`
   - Routed the new commands through `Memba.Membership.Router` to the `Person` aggregate.
   - Updated `Memba.Membership.Person` to:
     - execute and apply the new email-address lifecycle commands/events;
     - enforce pending vs verified primary rules via the existing `EmailAddresses` write-side state helpers;
     - tolerate serialized `verified_at` values during event replay.
   - Updated `Memba.Membership.Projectors.Person` to project the new events into `membership_person_email_addresses` and `membership_people`.
   - Added public Membership API entry points:
     - `add_person_email_address/2`
     - `verify_person_email_address/2`
     - `make_person_email_address_primary/2`
     - `remove_person_email_address/2`
   - Added/updated tests covering aggregate behaviour, Commanded routing/registration, dispatch, projection updates, and public API flow.

3. **Validation commands run and results**
   - TDD pre-implementation check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/public_api_test.exs`
     - Failed as expected with missing new command structs.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/app_test.exs test/memba/membership/email_addresses_test.exs test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/person_email_address_projection_test.exs test/memba/membership/public_api_test.exs`
     - Result: `62 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted ...`
     - Result: passed for touched files.
   - Broad quick validation on final diff:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `972 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add individual Membership commands/events for adding a pending email address, verifying an email address, making a verified address primary, and removing a non-primary address.`
   - To:
     - `- [x] 004 Add individual Membership commands/events for adding a pending email address, verifying an email address, making a verified address primary, and removing a non-primary address.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: added explicit business commands/events and aggregate-side decision logic rather than CRUD updates.
   - ADR 0007: changes stay inside the Membership bounded context.
   - ADR 0008 / 0009: uses existing Commanded/EventStore and Commanded Ecto projection patterns.
   - ADR 0011: commands continue routing by caller-supplied `person_id`.
   - ADR 0021: projector remains the read-model update boundary and continues publishing committed read-model changes through the existing projector callback.