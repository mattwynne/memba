Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Define deterministic Everyone and Admin group IDs.`

2. **Changes made**
   - Added `Memba.Membership.SystemGroups` with:
     - stable system group keys:
       - `everyone`
       - `admin`
     - display names:
       - `Everyone`
       - `Admin`
     - deterministic club-scoped group ID helpers:
       - `everyone_group_id/1`
       - `admin_group_id/1`
   - Added focused tests in `web/test/memba/membership/system_groups_test.exs` proving:
     - keys/names are stable;
     - IDs are deterministic for the same club;
     - Everyone/Admin IDs are distinct;
     - IDs are valid typed `grp_` IDs;
     - IDs are scoped per club;
     - deterministic source parts are locked as:
       - `["system-group", club_id, "everyone"]`
       - `["system-group", club_id, "admin"]`

3. **Validation**
   - TDD failing run before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/system_groups_test.exs`
     - Result: expected failure, `Memba.Membership.SystemGroups` was undefined.
   - Focused passing run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/system_groups_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/club_test.exs`
     - Result: `30 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: wrapper exited `0`, but ExUnit output still reports the same 2 existing/unrelated `MembaWeb.PageControllerTest` footer failures for `"Red Donkey Technology Corp"` that were noted in the prior task.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Define deterministic Everyone and Admin group IDs.`
   - To:
     - `- [x] 004 Define deterministic Everyone and Admin group IDs.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: keeps the change in domain vocabulary and prepares explicit command/event usage without projector-only special cases.
   - ADR 0007: keeps group identity concerns inside the Membership context; no Messaging dependency or Membership storage leakage added.
   - ADR 0011: uses caller/resolver-accessible deterministic typed IDs instead of aggregate-generated identities, preserving stable Commanded identities for later commands/backfill.