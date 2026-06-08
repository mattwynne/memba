### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Live `git status --short` is clean; `/tmp/fabro-pre-validate-snapshot.md` also recorded a clean tree at implementation checkpoint `45a8121`.
  - Recent commits show:
    - `146d2ba` pre-validation snapshot
    - `45a8121` `implement_next_task`
  - `git show 45a8121 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary task changed from unchecked to checked:
    - `008 Decommission direct Staff club-member creation from name/email...`
  - Current `todo.md` has tasks `001`–`008` checked and `009` as the first unchecked task, matching the expected next-task progression.

- **Implementation artifacts found.**
  - `web/lib/memba_web/live/admin/clubs_live/show.ex`
    - Removed the direct `add-member` form/options from the club detail memberships card.
    - Keeps an “Invite member” link to `/admin/clubs/:club_id/invitations/new`.
    - Adds an “Invitation required” notice explaining Staff no longer create active memberships directly.
    - Keeps person edit links intact.
    - Leaves a defensive stale `add_member` event handler that redirects to the invitation route and does not create a membership.
  - `web/lib/memba_web/live/admin/people_live/new.ex`
    - Updates workflow copy so creating a person is explicitly separate from creating active club membership.
  - Tests updated in:
    - `web/test/memba_web/live/admin/clubs_live/show_test.exs`
    - `web/test/memba_web/live/admin_people_live_test.exs`
    - `web/test/memba_web/live/browser_acceptance_harness_test.exs`
  - No acceptance feature files were changed in checkpoint `45a8121`.

- **Tests run/results found.**
  - I reran the focused tests live:
    - `devenv shell -- bin/mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/admin_people_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
    - Result: `23 tests, 0 failures`.
  - Working tree remained clean after the test run.
  - The implementation summary also reports `dev check` passed with acceptance output ending `62 scenarios (62 passed)`.

- **ADR/plan conformance notes.**
  - Plan task `008` is implemented directly and independently: Staff UI no longer creates active memberships directly from selected/created people, while existing person edit behavior remains available.
  - Scope is plan-preserving: it does not attempt invitation callback/profile completion work reserved for tasks `009`–`011`.
  - ADR 0001/0015 respected: changes remain in Phoenix/LiveView surfaces.
  - ADR 0007 respected: production UI no longer invokes direct membership creation for this workflow; Membership API usage added/kept only where appropriate for tests/fixtures and existing remove-member behavior.
  - ADR 0013 respected: user-facing behavior is covered with PhoenixTest/LiveView tests.
  - Acceptance feature edit rule respected: no `.feature` files were edited for this task.

{"context_updates":{"task_valid":true,"task_retry_available":false}}