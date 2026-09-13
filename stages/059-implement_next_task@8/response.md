Implemented task 008: “Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook.”

- Updated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:63) so a remembered, existing same-club group opens its server-authorized surface even when the member has not joined it. The LiveView patches to the group’s canonical URL and returns the authoritative selected group ID to the browser hook.
- Missing and foreign-club remembered IDs still fall back to Everyone.
- Explicit non-member group routes continue to take precedence over browser storage.
- Browser storage remains only a selection hint: tests verify that restoring a non-member group exposes access guidance but no conversations, tabs, or member rows.
- Added focused routed LiveView coverage in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:191) for valid non-member restoration, missing/foreign fallback, and explicit-route precedence.
- No acceptance feature or JavaScript files were changed.

Validation:

- TDD red: the focused non-member restoration test failed as expected because the server returned Everyone.
- `dev test test/memba_web/live/member_dashboard_live_test.exs`: 44 tests, 0 failures.
- `node --test acceptance-tests/test/remember_group_selection_hook.test.js`: 5 tests passed.
- Browser scenario `Bob returns to Admin`: 1 scenario, 6 steps, all passed, exercising local-storage restoration through the real browser.
- The new iteration-061 non-member browser scenario remains tagged `@todo-ui`; forcing it confirmed its five browser steps are still undefined and belong to task 011.
- `dev check --quick`: 1,266 tests, 0 failures.
- `git diff --check`: passed.
- Full `dev check` was not run because task 011 explicitly owns the final delivery gate.

Checked off only [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:10):

```markdown
- [x] 008 Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook.
```

No todo items were split, added, removed, or reordered. The implementation remains LiveView-based per ADR 0015, uses `push_patch` and canonical group routes per ADR 0023, and has routed LiveView plus browser-facing coverage consistent with ADR 0013.