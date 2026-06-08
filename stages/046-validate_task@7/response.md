### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - Live `git status --short` is clean.
  - Recent implementation checkpoint `11acbea fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `006 Reuse the iteration 028 invitation command/application service...`
    - from `- [ ]` to `- [x]`.
  - `git show 11acbea^:docs/iterations/029-membership-admin-invitations/todo.md` shows `006` was the first unchecked task before the checkpoint.
  - Current `todo.md` has `006` checked and keeps later tasks `007`–`014` pending; no plan-required work was deleted or weakened.

- Implementation artifacts found.
  - `web/lib/memba/membership.ex`
    - Adds `Membership.invite_club_member_as_club_member/2`.
    - Requires `club_id` and `actor_person_id`.
    - Authorizes the actor through `Authorization.authorize_manage_members/2`.
    - Delegates to existing `invite_club_member/2`, preserving the shared invitation lifecycle path.
  - `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
    - Adds tests for Membership Admin invitation creation/resend/token rotation/profile completion.
    - Adds duplicate active member rejection coverage.
    - Adds ordinary-member unauthorized coverage.

- Tests run/results found.
  - Validator reran focused test:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
    - Result: `10 tests, 0 failures`.
  - Implementation summary also reports:
    - focused test passed,
    - format check passed,
    - `dev check --quick` passed,
    - `git diff --check` passed.
  - Working tree remained clean after validation.
  - `11acbea` did not edit acceptance feature files.

- ADR/plan conformance notes.
  - Scope matches task `006`: reuse the existing Staff invitation application service/lifecycle rather than duplicating a Membership Admin-only implementation.
  - Work stays within the approved plan and leaves later UI/form/Cucumber/full-check tasks pending.
  - Relevant accepted ADRs are respected:
    - ADR 0002: domain workflow remains Commanded-backed.
    - ADR 0007: Membership invitation rules remain in the Membership context.
    - ADR 0009: tests assert against Ecto projections/read models.
    - ADR 0011: tests continue using caller-generated aggregate IDs.
    - ADR 0022: tests use strong consistency/read-your-writes style assertions.

{"context_updates":{"task_valid":true,"task_retry_available":false}}