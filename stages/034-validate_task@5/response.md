### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Read `/tmp/fabro-pre-validate-snapshot.md`; snapshot captured clean tree at implementation checkpoint `0325583`.
  - Live `git status --short` and `git diff` are clean; current HEAD has advanced to `fd0d53b` pre-validation checkpoint.
  - `git log --oneline -5` shows recent checkpoint trail including `0325583 fabro(...): implement_next_task (succeeded)`.
  - `git show 0325583 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary task changed:
    - `005 Ensure duplicate checks use normalized email:`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`–`004` checked and `005` as the first unchecked task.

- Implementation artifacts found.
  - `0325583` changes only:
    - `docs/iterations/028-staff-member-invitations/todo.md`
    - `web/lib/memba/membership.ex`
    - `web/test/memba/membership/public_api_test.exs`
  - `web/lib/memba/membership.ex` now:
    - blocks `invite_club_member/2` when the normalized email belongs to an active member of the club via `active_member_of_club_by_email?/2`;
    - detects an existing pending invitation by normalized club/email and resends/rotates that invitation instead of dispatching a duplicate invite;
    - preserves the existing invitation/acceptance path for existing people not already in the club.
  - No `*.feature` files were changed.

- Tests run/results found.
  - Added public API tests for:
    - rejecting an active club member by normalized alternate email;
    - resending a pending invitation by normalized club/email while preserving a single pending invitation.
  - I reran focused tests live:
    - `devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs`
    - Result: `22 tests, 0 failures`.
  - Working tree remained clean after validation test run.

- ADR/plan conformance notes.
  - Matches plan task `005` exactly: normalized duplicate checks for active members and pending invitations; existing-person-not-in-club acceptance remains intact.
  - ADR 0002 respected: invitation lifecycle remains Commanded command/event based.
  - ADR 0007 respected: duplicate invitation behavior stays inside Membership.
  - ADR 0009 respected: duplicate checks use projected read models.
  - ADR 0011 respected: no natural-key aggregate identity introduced; caller/application generated IDs remain in use.
  - ADR 0022 respected in tests through strong consistency/read-your-writes assertions.
  - Scope is small and independently checkpointed.

{"context_updates":{"task_valid":true,"task_retry_available":false}}