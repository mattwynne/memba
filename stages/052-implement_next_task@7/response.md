Implemented and checked off task 007: “Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour.”

1. Changes made

- Corrected the tablist accessible name to “Group sections” in [member_dashboard_group_tabs.ex](/workspace/memba/web/lib/memba_web/components/member_dashboard_group_tabs.ex:24).
- Strengthened component coverage for tab roles, `aria-selected`, `aria-controls`, roving `tabindex`, and the single contextual-action container in [member_dashboard_group_tabs_test.exs](/workspace/memba/web/test/memba_web/components/member_dashboard_group_tabs_test.exs:10).
- Strengthened the outside-admin LiveView regression to prove the Members-only tab/panel relationship and empty contextual-action position in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:754).
- Updated the existing browser step implementation in [group_conversation_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/group_conversation_steps.js:405) to exercise ArrowRight, ArrowLeft, Home, and End navigation, including focus, selection, panel visibility, and at-most-one contextual action.
- No acceptance feature files were changed.

2. Focused validation

- TDD red run: 47 tests, 3 expected failures on the incorrect accessible name.
- Focused green run: 47 tests, 0 failures.
- Browser scenario `An Admin member views Admin conversations and members`: 1 scenario, 10 steps, all passed while exercising all four keyboard navigation keys.
- `node --check` for the changed step definition: passed.
- Focused `mix format --check-formatted`: passed.
- `git diff --check`: passed.
- The separately-run historical Cucumber inventory test still reports its known `15 !== 8` iteration-058 assertion. The plan and validation notes explicitly assign that bookkeeping update to task 011; it was not changed here.
- Full `dev check` remains assigned to task 011.

3. Todo check-off

[todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:9) now contains:

```markdown
- [x] 007 Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour.
```

No tasks were split, added, removed, or reordered. Task 008 remains the first unchecked task.

4. ADR conformance

- ADR 0013: browser-visible interaction is covered through the existing Cucumber/Playwright scenario, with lower-level component and routed LiveView checks for ARIA structure.
- ADR 0015: the member dashboard remains LiveView-based.
- ADR 0023: keyboard activation continues to click LiveView patch links, so selected-tab state remains URL-addressable rather than becoming client-only state.