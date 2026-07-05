### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live `todo.md` now has task `004` checked.
  - Recent implementation checkpoint `7d8d5b8` changed exactly one ordinary todo line: task `004` from `- [ ]` to `- [x]`.
  - In `7d8d5b8^`, task `004` was the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba_web/controllers/page_html/club.html.heex` adds `#member-section-action-invite-member` inside `#member-section-tabs-action.section-tabs__action`.
  - The action uses `member_invitation_path(@selected_club, club_id_source)`, `variant="primary"`, `size="sm"`, `data-action="members"`, and `hidden`.
  - It is rendered only under `:if={@current_member_can_manage_members?}`.
  - `web/test/memba_web/live/member_dashboard_live_test.exs` adds coverage proving the action renders for manage-members users and is absent for ordinary members.

- Tests run/results found:
  - Reran focused test live:
    - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:104`
    - Passed: `20 tests, 0 failures, 19 excluded`.
  - Working tree is clean after validation.
  - Implementation summary also reported `dev check` passing.

- ADR/plan conformance notes:
  - No ADR files found under `docs/`.
  - Changed files in the implementation checkpoint are limited to the todo, club HEEx template, and LiveView test.
  - No acceptance `.feature` files were edited.
  - Work is within plan item `004` and preserves later planned scope for panels, CSS, and JS tab switching.

{"context_updates":{"task_valid":true,"task_retry_available":false}}