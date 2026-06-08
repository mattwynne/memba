### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Live working tree is clean.
  - Recent checkpoints show current HEAD at `31038aa` (`pre_validate_snapshot`) and the implementation checkpoint at `8670275`.
  - `git show 8670275 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary todo line changed:
    - `007 Add the Staff club-scoped invite route and form...`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`–`006` checked and `007` as the first unchecked task, so the checked-off task is the correct next task.

- **Implementation artifacts found.**
  - `8670275` adds/updates concrete web artifacts for task `007`:
    - `web/lib/memba_web/router.ex`
      - Adds Staff route under `/admin/clubs/:club_id/invitations/new`.
    - `web/lib/memba_web/live/admin/club_member_invitations_live/new.ex`
      - Adds the club-scoped Staff invitation LiveView.
      - Form asks for email only.
      - Normalizes/validates email.
      - Calls `Membership.invite_club_member/2` with strong consistency.
      - Delivers via `Memba.Membership.ClubMemberInvitationEmail`.
      - Does not collect invitee name.
    - `web/lib/memba_web/live/admin/clubs_live/show.ex`
      - Adds an “Invite member” link on the club detail memberships card.
      - Existing person edit links remain present.
    - `web/lib/memba_web/controllers/dev_test_support_controller.ex`
      - Adds the invitation projector to acceptance reset support, consistent with keeping the new projection testable.
    - `web/test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
      - Adds focused web coverage for the new route/form and preservation of person edit route.

- **Tests run/results found.**
  - New focused tests were added for:
    - opening the club-scoped invitation form;
    - submitting an email-only invitation;
    - avoiding person/member creation before acceptance;
    - invalid email validation;
    - club detail invite link while preserving person edit link.
  - I reran the focused validation live:
    - `devenv shell -- bin/mix test test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba_web/live/admin/clubs_live/show_test.exs`
    - Result: `14 tests, 0 failures`.
  - Working tree remained clean after the test run.
  - Implementation summary also reports a successful `dev check`.

- **ADR/plan conformance notes.**
  - Plan task `007` is implemented directly: Staff route/form under `/admin/clubs/:club_id/...`, without replacing the person edit route.
  - Work remains within the approved iteration plan and does not silently complete or remove later tasks `008`–`016`.
  - No acceptance `.feature` files were edited in this checkpoint.
  - ADR 0001/0015: uses Phoenix LiveView for this authenticated application surface.
  - ADR 0013: adds PhoenixTest/LiveView-style feature coverage.
  - ADR 0007: web layer calls Membership APIs instead of mutating membership projections directly.
  - ADR 0016: email delivery remains through the existing Swoosh/Mailer boundary; no direct provider HTTP code added.

{"context_updates":{"task_valid":true,"task_retry_available":false}}