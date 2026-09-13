Implemented and checked off task 005:

> Explicitly distinguish ordinary non-member, outside admin and participating member.

Changes:

- [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:104) now exposes an explicit `selected_group_access` state:
  - `:participating_member` — member and conversation data.
  - `:outside_admin` — membership metadata only.
  - `:ordinary_non_member` — safe group identity and club Admin contact only.
- Participating membership takes precedence when a club admin also belongs to the selected group.
- Outside admins receive member rows, member count, and group email metadata, but no messages or conversation rows.
- Ordinary non-members receive no member count, group email, member rows, participant-name map, messages, or conversation rows.
- All branches use Membership’s public APIs; the web layer does not query projection schemas directly.
- Added focused regression coverage in [member_dashboard_presentation_test.exs](/workspace/memba/web/test/memba_web/member_dashboard_presentation_test.exs:454).

Validation:

- TDD red run: 11 tests, 3 expected failures before implementation.
- `dev test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs`: 53 tests, 0 failures.
- `dev check --quick`: 1,263 tests, 0 failures.
- `mix format --check-formatted ...`: passed.
- `git diff --check`: passed.
- Full browser acceptance remains owned by final task 011, as required by the workflow.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:7):

```markdown
- [x] 005 Explicitly distinguish ordinary non-member, outside admin and participating member.
```

No tasks were split, added, removed, or reordered. Task 006 remains first unchecked.

ADR conformance: ADRs 0007 and 0009 remain satisfied through public Membership query and authorization APIs; conversation loading occurs only on actual participation. ADRs 0015 and 0023 are unchanged because no routing or LiveView ownership was altered. ADR 0024’s Club/Admin write invariants are untouched; this task only reads the projected management permission.