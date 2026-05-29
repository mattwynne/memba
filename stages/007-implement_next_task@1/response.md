Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`

2. **Changes made**
   - Added Person write model:
     - `Memba.Membership.Person`
     - `Memba.Membership.Commands.CreatePerson`
     - `Memba.Membership.Events.PersonCreated`
   - Added Person read side:
     - `Memba.Membership.Projections.Person`
     - `Memba.Membership.Projectors.Person`
     - `Memba.Membership.get_person/1`
     - migration for `membership_people`
   - Wired Person into:
     - `Memba.Membership.Router`
     - application supervision
     - event-sourced test reset/projector setup
     - projection table config
   - Added ExUnit coverage for:
     - Person aggregate decisions/rules
     - CreatePerson dispatch/routing
     - Person projector/query behavior
     - event-sourced setup handling the new projection table
   - Updated existing app test to include the Person command/projector.

3. **Validation**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/person_test.exs`
     - Failed as expected before implementation because `CreatePerson` was undefined.
   - Focused passing checks:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/person_test.exs test/memba/membership/create_person_dispatch_test.exs test/memba/membership/person_projection_test.exs test/memba/membership/app_test.exs`
     - Result: `13 tests, 0 failures`
   - Projection setup check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/event_sourced_setup_test.exs`
     - Result: `3 tests, 0 failures`
   - Required final gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - First run hit a file permission issue from tool-created root-owned files; fixed permissions.
     - Rerun result: `40 tests, 0 failures`, exit 0.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`
   - To:
     - `- [x] 001 Add Person aggregate, CreatePerson command, PersonCreated event,`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Kept Person inside the Membership context (`Memba.Membership.*`) and exposed it through the Membership public query boundary.
   - ADR 0011: Person aggregate identity is caller-supplied `person_id`; no natural-key/email identity was introduced.
   - ADR 0002/0009: Implemented command/event aggregate behavior with Commanded and Ecto projection read model storage.