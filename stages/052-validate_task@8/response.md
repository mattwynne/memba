### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Live working tree is clean: `git status --short` and `git diff` are empty.
  - `/tmp/fabro-pre-validate-snapshot.md` records implementation checkpoint `8ce67ac`.
  - Recent history shows `af0dd92 pre_validate_snapshot` on top of `8ce67ac implement_next_task`.
  - `git show 8ce67ac -- docs/iterations/029-membership-admin-invitations/todo.md` changes exactly one ordinary task from unchecked to checked:
    - `006 Reuse the iteration 028 invitation command/application service where possible...`
  - At `8ce67ac^`, task `006` was the first unchecked todo item.

- Implementation artifacts found.
  - Added `web/lib/memba_web/club_member_invitation_sender.ex`, a shared sender that:
    - normalizes the invited email;
    - checks for pending invitations;
    - calls `Memba.Membership.invite_club_member/2`;
    - delivers the existing `ClubMemberInvitationEmail`;
    - builds the same `/invitations/club-members/:token` callback URL.
  - Updated Staff admin invitation LiveView to use `MembaWeb.ClubMemberInvitationSender`.
  - Updated Membership Admin/member-facing invitation LiveView to submit an email-only invitation form through the same sender.
  - Added `web/test/memba_web/live/club_member_invitations_live/send_test.exs`, proving Membership Admin submission creates a pending invitation, sends email, preserves no pre-acceptance person/member creation, and resolves the email token through the shared invitation lifecycle.
  - No acceptance feature files were edited in this checkpoint.

- Tests run/results found.
  - I reran the focused relevant tests:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
    - Result: `11 tests, 0 failures`.
  - The implementor also reported `dev check` passing for the checkpoint.

- ADR/plan conformance notes.
  - Work matches task `006`: Staff and Membership Admin flows now share the same Membership invitation application service and email/link lifecycle.
  - The implementation stays within the approved iteration scope and does not delete, weaken, or silently defer remaining plan tasks.
  - ADR 0001/0015 respected: member-facing behaviour remains Phoenix LiveView-based.
  - ADR 0002/0007 respected: invitation lifecycle stays in the Membership context and uses the existing Commanded-backed application service.
  - ADR 0016 respected: email delivery remains behind the existing Swoosh/Mailer email boundary; no new HTTP/provider integration was introduced.
  - Checkpoint is focused and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}