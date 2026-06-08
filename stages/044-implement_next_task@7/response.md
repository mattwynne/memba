1. **Selected todo line**
   - `- [ ] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

2. **Changes made**
   - Confirmed the invitation API does **not** need a new inviter/actor field for this slice:
     - Membership Admin authorization is already enforced at the member-facing caller boundary.
     - Staff/system callers can already use `Membership.invite_club_member/2` without being represented as club members.
   - Updated `web/lib/memba/membership.ex`
     - Documented `invite_club_member/2` as intentionally actor-neutral.
   - Updated `web/test/memba/membership/public_api_test.exs`
     - Renamed the existing invitation API test to explicitly prove the API creates invitations without requiring an actor.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off only task 007.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/public_api_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/public_api_test.exs`
     - Blocked before ExUnit by existing sandbox Postgres `postmaster.pid` lock.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `733 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`
   - To:
     - `- [x] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Invitation lifecycle remains in the Membership Commanded application service; no CRUD bypass added.
   - ADR 0007: Membership remains the bounded context owning invitation state.
   - ADR 0009: Read-model/projector shape was not altered unnecessarily.
   - ADR 0011: Caller-generated invitation UUID behaviour remains unchanged.
   - ADR 0022: Validation used existing project test/check workflow; no new polling or read-model bypass introduced.