Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 002 Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,`

2. **Changes made**
   - Added Membership write model:
     - `Memba.Membership.Membership`
     - `Memba.Membership.Commands.AddMember`
     - `Memba.Membership.Events.MemberAdded`
   - Added Membership read side:
     - `Memba.Membership.Projections.Membership`
     - `Memba.Membership.Projectors.Membership`
     - migration for `membership_memberships`
   - Wired Membership into:
     - `Memba.Membership.Router`
     - Phoenix supervision tree
     - event-sourced projection table config
     - event-sourced test reset/projector setup
   - Added/updated ExUnit coverage for:
     - Membership aggregate decisions/rules
     - AddMember command dispatch/routing
     - Membership projector behavior
     - app supervision/router wiring
     - event-sourced setup/reset handling the new projection table

3. **Focused validation**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/membership_test.exs test/memba/membership/add_member_dispatch_test.exs test/memba/membership/membership_projection_test.exs`
     - Failed as expected because `Memba.Membership.Commands.AddMember` was undefined.
   - Focused passing check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/membership_test.exs test/memba/membership/add_member_dispatch_test.exs test/memba/membership/membership_projection_test.exs test/memba/membership/app_test.exs test/event_sourced_setup_test.exs`
     - Result: `15 tests, 0 failures`
   - Required final gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `49 tests, 0 failures`, exit 0

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,`
   - To:
     - `- [x] 002 Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: Membership remains inside `Memba.Membership.*`; no Messaging context or acceptance feature files were touched.
   - ADR 0011: Membership uses caller-supplied UUID identity `membership_id`, with `club_id` and `person_id` as event/projection fields.
   - ADR 0002/0009: Implemented command/event aggregate behavior with Commanded and an Ecto-backed projection via `commanded_ecto_projections`.