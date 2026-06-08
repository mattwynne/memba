1. **Selected todo line**
   - `007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

2. **Changes made**
   - `web/lib/memba/membership.ex`
     - Documented `invite_club_member/2` as the Staff/system invitation entry point that does not require club membership.
     - Made `invite_club_member_as_club_member/2` explicitly strip `actor_person_id` before delegating to the shared invitation lifecycle API, keeping actor authorization separate from invitation data.
   - `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Added coverage proving a Membership Admin actor is authorized separately and not carried into `ClubMemberInvited` lifecycle data.
     - Added coverage proving the member-facing invitation API requires `actor_person_id`.

3. **Focused validation commands run**
   - Attempted direct focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Failed before tests due sandbox `PGHOST` mismatch.
   - Passed focused test via required sandbox workaround:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Result: `12 tests, 0 failures`.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed after applying formatter’s single alignment change manually because `mix format` could not write via `/repos/...` in this sandbox.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `738 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - From:
     - `- [ ] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`
   - To:
     - `- [x] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan, and no `docs/adr` files were found in this workspace.
   - The change keeps invitation lifecycle behavior inside the Membership application service and Commanded-backed invitation aggregate/event path.
   - Staff/system invitations remain possible without requiring implicit club membership.
   - Membership Admin invitations require a club-member actor authorized through `club.manage_members`.
   - No UI, route, acceptance feature, role assignment, or acceptance-profile behavior was changed for this task.