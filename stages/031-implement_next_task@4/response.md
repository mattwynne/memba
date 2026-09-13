Implemented and checked off task 004:

> Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface.

Changes made:

- [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:49) now resolves selected groups through `Membership.list_discoverable_groups_for_member/2` after club and identity authorization.
- Participation remains separately determined through `list_active_groups_for_member/2`.
- Participating members receive the existing member and conversation surfaces.
- Non-participants receive only safe group identity fields; member counts, group email addresses, member rows, conversation rows, and participant-name maps are not loaded.
- Missing and foreign-club group IDs still return the indistinguishable `:not_found` result.
- [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:71) preserves the existing remembered-group fallback until the dedicated remembered-selection task.
- [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:92) tolerates the intentionally absent member count when rendering the interim safe surface.
- Presentation and routed LiveView regressions now cover same-club discovery without private-row disclosure, while retaining invalid and foreign-group rejection.

Validation:

- Focused presentation and routed LiveView suites: 52 tests, 0 failures.
- `dev check --quick`: 1,262 tests, 0 failures.
- `git diff --check`: passed.
- Full browser acceptance was not run in this ordinary per-task node; final full validation remains explicitly owned by task 011.

Todo check-off in [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:6):

```markdown
- [x] 004 Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface.
```

No tasks were split, added, removed, or reordered. Task 005 remains the first unchecked task.

Architecture remains conformant with ADRs 0007 and 0009: the web presentation layer uses Membership’s public query APIs and does not join Membership projections directly. ADRs 0015 and 0023 remain intact because the surface stays LiveView- and URL-driven. No commands, events, projection publication behavior, barriers, or Club consistency rules covered by ADRs 0021, 0022, or 0024 were changed.