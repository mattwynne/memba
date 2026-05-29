Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`

2. **Changes made for this task**
   - Added Membership write model:
     - `Memba.Membership.Membership`
     - `Memba.Membership.Commands.AddMember`
     - `Memba.Membership.Events.MemberAdded`
   - Added Membership projection:
     - `Memba.Membership.Projections.Membership`
     - `Memba.Membership.Projectors.Membership`
     - Migration: `create_membership_memberships_projection`
   - Wired Membership into:
     - `Memba.Membership.Router` with `identify(Membership, by: :membership_id)`
     - `Memba.Application` supervision tree
     - event-sourced projection reset config/test helpers
   - Added/updated tests for:
     - aggregate decision and apply rules
     - Commanded dispatch/routing
     - projector persistence
     - supervised projector/registered command coverage
     - projection migration/reset support
   - Did not edit acceptance feature files.

3. **Validation commands/results**
   - `cd web && mix compile --warnings-as-errors`
     - Passed.
   - `cd web && mix format --check-formatted`
     - Passed after manual format fix.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `49 tests, 0 failures`.
   - Note: an initial direct `mix test ...` attempt outside `dev` failed because Postgres was not running in that shell; final validation used `dev check`, which starts required services.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add Membership aggregate, AddMember command, MemberAdded event,`
   - To:
     - `- [x] 002 Add Membership aggregate, AddMember command, MemberAdded event,`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: all changes stay inside the Membership bounded context; no Messaging coupling or Messaging code changes.
   - ADR 0011: Membership uses caller-supplied `membership_id` as aggregate identity, routed via Commanded conventions; `club_id` and `person_id` are event/projection fields rather than natural aggregate identity.