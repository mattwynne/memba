Implemented task 007 and left it unchecked for independent review.

Key behavior:

- Custom-group members can open an inline “Add member” picker and search eligible active club members.
- Existing group members are excluded from picker candidates.
- Club admins outside a custom group receive a Members-only view with an explicit “Add yourself” action and history/email disclosure.
- Everyone/Admin system groups retain the existing invitation behavior.
- Picker state is transient LiveView state; no membership mutation or submission handling was added, preserving task 009’s boundary.
- No acceptance feature files were changed.

Primary changes are in [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:133), [member_components.ex](/workspace/memba/web/lib/memba_web/components/member_components.ex:205), [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:75), and [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:176).

Validation:

- `dev check --quick`: 1,425 tests, 0 failures
- Focused presentation/component/LiveView tests: 47 tests, 0 failures
- UI contract tests: 4 tests, 0 failures
- Focused browser harness passed picker open/search/close and outside-admin self-add rendering
- Existing acceptance sanity scenario passed
- Formatting and diff checks passed
- Changes are staged but not committed
- Task 007 remains unchecked in [todo.md](/workspace/memba/docs/iterations/063-add-custom-group-members/todo.md:9)

The dependency scan emitted existing security advisories, but these did not fail the project gate.