Implemented and checked off task 004:

> Refactor `MembaWeb.MemberDashboardPresentation` so it resolves the signed-in active club membership once, authorises a selected group through the new Membership API, and loads the selected group's active members and readable conversations.

Changes made:

- Added selected-group-aware `load/4` while retaining `load/3` as the Everyone-compatible default in [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:20).
- The presentation now:
  - resolves the current active club member once;
  - obtains authorized groups through `Membership.list_active_groups_for_member/2`;
  - authorizes selection by finding it in that result;
  - loads members through `Membership.list_active_members_of_group/1`;
  - loads conversations through `Messaging.list_conversations_for_group/1`;
  - exposes `groups` and `selected_group` assigns.
- Added a generic “Trip Planning” group test proving selected member and conversation scoping in [member_dashboard_presentation_test.exs](/workspace/memba/web/test/memba_web/member_dashboard_presentation_test.exs:203).
- Updated dashboard and invitation test fixtures to create realistic Everyone group state required by the new authorization boundary.
- No routing, LiveView UI, composition, action-authorization, or acceptance-feature work from later tasks was included.

Validation:

- TDD red phase: focused presentation test failed because `load/4` did not exist.
- Focused presentation suite: 8 tests, 0 failures.
- Presentation and dashboard LiveView suites: 39 tests, 0 failures.
- Invitation regression tests: 2 tests, 0 failures.
- Final `PATH="$PWD/bin:$PATH" dev check`: passed, including the full ExUnit and browser-acceptance gates.
- Formatting and `git diff --check`: passed.

Checked off only [task 004](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:6). No tasks were split, added, removed, or reordered; task 005 remains next.

ADR conformance:

- ADR 0007: production web code uses public Membership and Messaging APIs, with no projection-schema leakage.
- ADR 0009: read models remain encapsulated behind their owning context query APIs.
- ADR 0015: the presentation helper continues supporting the LiveView-owned member surface.
- ADR 0023: no premature routing or URL-state changes were introduced.
- ADRs 0021–0022: no projector publication or projection-barrier behavior was changed.