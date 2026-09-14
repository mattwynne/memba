Task 007 is revised and ready for independent review. The picker now handles Escape, restores focus after either dismissal path, responds to paste/native input events, and matches the reviewed styling and empty state.

1. Selected todo line

`- [ ] 007 Extend MemberDashboardPresentation, shared member components and the group Members surface with the picker and admin self-add.`

2. Changes made

- Replaced unsupported input `phx-keyup` filtering with a `to_form/2`-backed `phx-change` search form in [member_components.ex](/workspace/memba/web/lib/memba_web/components/member_components.ex:205) and [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:73).
- Focuses search automatically when the picker opens.
- Escape and Close both dismiss the picker and restore focus to Add member.
- Changed candidate Add buttons to the reviewed outlined-primary treatment.
- Moved the picker’s responsive header breakpoint from 640px to the designed 700px in [app.css](/workspace/memba/web/assets/css/app.css:1457).
- Added the designed zero-member state, distinct from the one-member state.
- Added component, LiveView, CSS-contract, runner-configuration, and real-browser coverage.
- Added the permitted UI-only scenario to [custom_group_membership.feature](/workspace/memba/acceptance-tests/features/custom_group_membership.feature:11), with browser plumbing in [custom_group_membership.js](/workspace/memba/acceptance-tests/features/support/custom_group_membership.js:1). Admission scenarios remain tagged as runner debt for task 014.
- No membership submission, domain mutation, welcome email, or acceptance admission scenario was implemented; task 009’s boundary remains intact.

3. Focused validation

- TDD red run: 58 tests, 3 expected failures covering input events and zero-member rendering.
- Focused component/LiveView/presentation/Cucumber tests: 91 tests, 0 failures.
- Browser scenario:

  `PATH="$PWD/bin:$PATH" dev acceptance --name 'Bob searches and dismisses the picker'`

  Result: 1 scenario, 13 steps, all passed. This verifies input-event filtering, initial search focus, Escape dismissal, Close dismissal, and focus restoration.

- Cucumber configuration: 15 tests, 0 failures.
- Final broad gate:

  `PATH="$PWD/bin:$PATH" dev check --quick`

  Result: 1,427 tests, 0 failures.

- `git diff --check` passes. Existing dependency security advisories remain informational.
- Full `dev check` remains the explicit pending task 016 and is not claimed here.

4. Todo state

Still exactly unchecked in [todo.md](/workspace/memba/docs/iterations/063-add-custom-group-members/todo.md:9):

`- [ ] 007 Extend MemberDashboardPresentation, shared member components and the group Members surface with the picker and admin self-add.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0013: user-visible behavior has focused web and real-browser coverage.
- ADR 0015: transient picker interaction remains coordinated by `MemberDashboardLive`.
- ADR 0023: picker open/focus state remains intentionally transient; routed Members-tab state remains URL-addressable.
- ADR 0024: this revision introduces no projection-backed mutation or authorization shortcut; membership submission remains deferred to task 009 and the existing Club consistency boundary.