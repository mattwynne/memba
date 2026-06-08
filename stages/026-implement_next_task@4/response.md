1. **Selected todo line**
   - `- [ ] 004 Authorize the route/action using the \`club.manage_members\` permission for the signed-in person in the current club.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/member_invitation_live/new.ex`
     - Added `Memba.Membership.Authorization`.
     - The invitation LiveView now requires `Authorization.authorize_manage_members(club_id, current_member.id)` during mount-context loading.
     - Unauthorized signed-in active members receive the existing LiveView forbidden behavior via `MembaWeb.ForbiddenError`.
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Existing successful invitation page tests now grant `club.manage_members` to the signed-in member.
     - Added coverage proving an active club member without `club.manage_members` is rejected.
     - Added a local `grant_manage_members!/1` helper using the projected `MemberPermission` read model, consistent with nearby dashboard tests.

3. **Validation**
   - Attempted focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Result: did not reach ExUnit due sandbox Postgres `postmaster.pid` lock wrapper issue.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed; acceptance output showed `69 scenarios (69 passed), 466 steps (466 passed)`.
   - Broad ExUnit validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: passed — `728 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Authorize the route/action using the \`club.manage_members\` permission for the signed-in person in the current club.`
   - To:
     - `- [x] 004 Authorize the route/action using the \`club.manage_members\` permission for the signed-in person in the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015: kept the member-facing invitation surface as a LiveView.
   - ADR 0013: added/updated web tests for authorization behavior.
   - ADR 0009: reused the existing projection-backed authorization/read-model path; no duplicate permission state.
   - ADR 0022: no new write/read-after-write flow introduced, so no projection barrier needed.