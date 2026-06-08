### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - `/tmp/fabro-pre-validate-snapshot.md` shows a clean validation snapshot for implement checkpoint `6bcba5f`.
  - Live `git status --short` and `git diff` are clean, which is acceptable under the Fabro checkpoint workflow.
  - Recent history shows:
    - `957e5ed fabro(...): pre_validate_snapshot (succeeded)`
    - `6bcba5f fabro(...): implement_next_task (succeeded)`
  - `git show 6bcba5f -- docs/iterations/029-membership-admin-invitations/todo.md` shows exactly one ordinary todo line changed:
    - `007 If needed, add an inviter/actor distinction...`
    - from `- [ ]` to `- [x]`.
  - At `6bcba5f^`, task `007` was the first unchecked task.

- Implementation artifacts found.
  - `web/lib/memba/membership.ex`
    - Added `Memba.Membership.invite_club_member_as_club_member/2`.
    - Requires `actor_person_id`.
    - Authorizes via `Authorization.authorize_manage_members/2`.
    - Delegates to the existing `invite_club_member/2` lifecycle after authorization.
    - Clarifies `invite_club_member/2` as the Staff/system actor path.
  - `web/lib/memba_web/club_member_invitation_sender.ex`
    - Splits optional `:actor_person_id` from dispatch options.
    - Uses Staff/system invitation API when no actor is present.
    - Uses club-member actor invitation API when an actor is present.
  - `web/lib/memba_web/live/club_member_invitations_live/new.ex`
    - Passes the current member’s person ID as `actor_person_id` for Membership Admin invitations.
  - `web/test/memba/membership/public_api_test.exs`
    - Adds tests for Membership Admin actor authorization and shared invitation lifecycle.
    - Adds ordinary-member rejection coverage.
    - Confirms Staff/system invitations still work without Staff club membership.
  - No acceptance feature files were changed in checkpoint `6bcba5f`.

- Tests run/results found.
  - I reran focused tests:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba_web/live/club_member_invitations_live/send_test.exs`
  - Result:
    - `21 tests, 0 failures`.
  - Implementor also reported `dev check` passing, including acceptance scenarios.

- ADR/plan conformance notes.
  - Matches task `007`: introduces a clear Staff/system vs club-member actor distinction without giving Staff implicit club membership.
  - Preserves iteration scope: no role-selection UI, no pending-invitation management, no expiry changes.
  - Respects ADR 0002 and ADR 0007 by keeping invitation lifecycle and authorization in the Membership context / Commanded-backed application service boundary.
  - Respects ADR 0015 by keeping member-facing interaction in LiveView.
  - Respects ADR 0016 by preserving the existing email delivery boundary; no new provider or HTTP integration added.
  - The checkpoint is focused and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}