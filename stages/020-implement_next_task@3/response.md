Implemented the next unchecked iteration task as a split first slice.

1. **Selected todo line**
   - Original first unchecked line:
     - `002b Add the Membership Admin invite action to the existing member dashboard #club-members section once the member-facing invitation route/action and permission-aware assigns are in place.`

2. **Changes made**
   - Split `002b` because the visible invite link/action still depends on pending route/authorization tasks `003–005`.
   - Added `can_manage_members?` to `MembaWeb.MemberDashboardPresentation.load/3`.
   - The assign is backed by:
     - `Membership.person_has_club_permission?/3`
     - `Permissions.club_manage_members()`
   - Added focused tests proving:
     - ordinary members get `can_manage_members?: false`;
     - members with projected `club.manage_members` permission get `can_manage_members?: true`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba_web/member_dashboard_presentation.ex test/memba_web/member_dashboard_presentation_test.exs`
     - Passed.
   - `devenv shell -- bin/mix test test/memba_web/member_dashboard_presentation_test.exs`
     - Passed: `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `722 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Checked off only:
     - `- [x] 002b1 Add the permission-aware dashboard assign needed to gate the Membership Admin invite action.`

5. **Todo split/reordering**
   - Replaced the original `002b` with:
     - checked `002b1` for the permission-aware assign;
     - pending `002b2` for rendering the dashboard invite action.
   - Moved pending `002b2` after `003–005` so the visible action is added only after the member-facing route/action and authorization rejection path exist.

6. **ADR conformance**
   - ADR 0001: stays within Phoenix app surface.
   - ADR 0015: prepares the existing LiveView-backed member dashboard for permission-gated member app behaviour.
   - ADR 0007: uses Membership public query API for membership permission state.
   - ADR 0009: reads permission state through projected read models via the Membership API, not aggregate internals.