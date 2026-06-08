### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Read `/tmp/fabro-pre-validate-snapshot.md`: snapshot was clean at implementation checkpoint `aa49d66`.
  - Live `git status --short` and `git diff --stat` are clean.
  - `git log --oneline -5` shows:
    - `8427850 ... pre_validate_snapshot`
    - `aa49d66 ... implement_next_task`
  - `git show aa49d66 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary task changed:
    - task `010` from `- [ ]` to `- [x]`.
  - Parent/current todo evidence shows task `010` was the first unchecked task after `001`–`009`.

- **Implementation artifacts found.**
  - `web/lib/memba_web/router.ex` adds:
    - `GET /invitations/club-members/profile`
    - `POST /invitations/club-members/profile`
  - `web/lib/memba_web/controllers/club_member_invitation_controller.ex` now:
    - validates invitation/profile-completion session state;
    - renders profile completion for verified unknown invitees;
    - rejects direct profile completion without an invitation journey;
    - keeps blank-name submissions pending without creating person/membership;
    - completes profile via `Membership.complete_invited_club_member_profile/2`;
    - signs in and redirects to the invited club after successful completion.
  - Added `MembaWeb.ClubMemberInvitationHTML` and `profile.html.heex` with a name-only profile completion form.
  - No acceptance `.feature` files were changed in the checkpoint.

- **Tests run/results found.**
  - Checkpoint added/updated controller tests covering:
    - profile page access after invitation callback;
    - no person/member created before name submission;
    - blank-name submission keeps invitation pending/token reusable;
    - valid name creates profile, activates membership, accepts invitation, and clears session journey.
  - Live validation ran:
    - `PATH="$PWD/bin:$PATH" dev check`
    - Result: `705 tests, 0 failures`; `62 scenarios (62 passed)`.
  - Working tree remained clean after validation.

- **ADR/plan conformance notes.**
  - Matches task `010`: invited unknown members can enter their own name before membership activation, with no incomplete person created before name submission.
  - Plan scope preserved; task `011` remains unchecked for broader staff-onboarding preservation.
  - ADR 0001 respected: implementation remains in Phoenix.
  - ADR 0002/0007/0009 respected: membership-changing behavior goes through Membership public APIs/Commanded flow, not direct projection mutation from web code.
  - ADR 0013 respected: user-visible web behavior has automated Phoenix/controller tests.
  - ADR 0015 acceptable: this is an invitation/session journey rather than an authenticated member application page.
  - ADR 0022 respected: completion uses `consistency: :strong` before redirecting to read-model-backed club surfaces.

{"context_updates":{"task_valid":true,"task_retry_available":false}}