### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - Working tree is clean.
  - Recent implement checkpoint `43b7dca fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`
    - from `- [ ]` to `- [x]`.
  - The parent todo state shows `005` was the first unchecked task after completed `001`–`004`.

- Implementation artifacts found.
  - `web/lib/memba_web/member_dashboard_presentation.ex`
    - Adds `can_manage_members?` dashboard assign using `Membership.person_has_club_permission?/3` and `Permissions.club_manage_members/0`.
  - `web/lib/memba_web/controllers/page_html/club.html.heex`
    - Adds `data-can-manage-members` to `#club-members`, providing permission-gated visibility state for invitation UI.
  - `web/test/memba_web/member_dashboard_presentation_test.exs`
    - Covers ordinary members receiving `can_manage_members? == false`, including when same email has permission in another club.
  - `web/test/memba_web/live/member_dashboard_live_test.exs`
    - Covers ordinary members seeing `data-can-manage-members='false'` and not seeing `#member-invite-member-link`.
  - `web/test/memba_web/live/member_invitation_live/new_test.exs`
    - Covers direct routed/LiveView/host-selected invitation access being forbidden for ordinary members.

- Tests run/results found.
  - Live validation reran focused tests:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
    - Result: `24 tests, 0 failures`.
  - `git show --check --stat 43b7dca` passed.
  - Implementation summary reports full `dev check` passed.
  - Working tree remains clean after validation.

- ADR/plan conformance notes.
  - No acceptance feature files were changed.
  - Scope matches task `005`: ordinary-member non-visibility and direct URL/action rejection coverage.
  - The admin-visible invite link remains appropriately deferred to pending task `005a`.
  - Permission logic uses the Membership public API and `club.manage_members`, consistent with the plan.
  - No plan-required todo work was deleted, weakened, or silently deferred.
  - No relevant accepted ADR constraints were found beyond project/reference guidance.

{"context_updates":{"task_valid":true,"task_retry_available":false}}