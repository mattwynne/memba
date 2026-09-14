Implemented and validated task 007. The task remains unchecked for independent review.

1. Selected task

   `- [ ] 007 Extend MemberDashboardPresentation, shared member components and the group Members surface with the picker and admin self-add.`

2. Changes made

   - Extended [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:114) to expose custom-group admission permissions, self-add eligibility, and eligible active-club candidates.
   - Added LiveView-owned picker open/close/filter state in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:42), including focus restoration and Escape handling.
   - Added reusable picker, outside-admin notice, empty membership state, and membership-authority guidance in [member_components.ex](/workspace/memba/web/lib/memba_web/components/member_components.ex:205).
   - Updated [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:163) with the contextual Add member action, inline picker, admin self-add surface, and access-specific guidance.
   - Added responsive design-system-aligned styling in [app.css](/workspace/memba/web/assets/css/app.css:223).
   - Added presentation, component, LiveView, UI-contract, and CSS coverage.
   - Reversed the previous failed checkpoint’s acceptance-feature edits. Relative to the pre-task checkpoint, there are now no acceptance `.feature` changes, satisfying the locked-feature policy.

3. Focused validation

   - Focused ExUnit suite: 84 tests, 0 failures.
   - Targeted browser harness: 2 scenarios, 20 steps, all passed, covering picker keyboard/input behavior and the outside-admin self-add surface without conversation access.
   - Cucumber configuration tests after restoring locked feature files: 14 tests, 0 failures.
   - `mix format --check-formatted` on touched Elixir/HEEx files: passed.
   - `git diff --check`: passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`: 1,429 tests, 0 failures.
   - Full `dev check` was not run because task 016 explicitly owns the final full gate.

4. Task remains unchecked

   `- [ ] 007 Extend MemberDashboardPresentation, shared member components and the group Members surface with the picker and admin self-add.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0013: user-facing behavior is covered through LiveView and browser-level tests.
   - ADR 0015: interactive member UI remains owned by `MemberDashboardLive`.
   - ADR 0023: the Members tab remains URL-addressable; only transient picker disclosure state stays local.
   - ADR 0021: existing read-model PubSub refresh behavior remains intact.
   - ADR 0024: this task adds presentation behavior only; it does not introduce projection-backed write authorization or bypass the `Membership.Club` consistency boundary.