### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Read `/tmp/fabro-pre-validate-snapshot.md`; validation snapshot showed clean tree at implementation checkpoint `ee7db66`.
  - Live `git status --short` and `git diff` are clean.
  - Recent history shows `ee7db66 fabro(...): implement_next_task (succeeded)` followed by `5ea321f ... pre_validate_snapshot`.
  - `git show ee7db66 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary task changed:
    - `004 Add public Membership APIs/commands for Staff/system use:`
    - from unchecked to checked.
  - Parent todo state had `001`–`003` checked and `004` as the first unchecked task.

- Implementation artifacts found.
  - `web/lib/memba/membership.ex` adds public Membership APIs for:
    - `invite_club_member/2`
    - `resend_club_member_invitation/2`
    - `accept_club_member_invitation_for_existing_person/2`
    - `complete_invited_club_member_profile/2`
  - Adds query helpers:
    - `get_club_member_invitation/1`
    - `get_pending_club_member_invitation_by_email/2`
  - Uses invitation token generation/hash storage via `Memba.Membership.InvitationToken`.
  - Acceptance/profile completion paths orchestrate person creation, membership creation, and invitation acceptance without creating an incomplete person before name submission.
  - Changed files in the implementation checkpoint are limited to `todo.md`, `web/lib/memba/membership.ex`, and `web/test/memba/membership/public_api_test.exs`.
  - No `*.feature` files were edited.

- Tests run/results found.
  - Implementation summary reported formatting, focused tests, `dev check --quick`, and `git diff --check` passing.
  - I reran focused tests live:
    - `devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs`
    - Result: `20 tests, 0 failures`.
  - Working tree remained clean after the test run.

- ADR/plan conformance notes.
  - Work matches task `004` and leaves task `005` duplicate-rule hardening for the next planned slice.
  - ADR 0002 respected: new behavior dispatches Commanded commands/events.
  - ADR 0007 respected: Membership invitation APIs remain in the Membership bounded context.
  - ADR 0009 respected: read-model lookups use Membership projections.
  - ADR 0011 respected: aggregate IDs are caller/application-service generated before dispatch.
  - ADR 0022 respected in tests via strong consistency for projected read-your-writes assertions.
  - Scope is appropriately small and independently checkpointed.

{"context_updates":{"task_valid":true,"task_retry_available":false}}