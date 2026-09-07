Implemented and checked off task 005:

> Keep all current row presentation—including participant names and role badges—working against the selected member set.

Changes:

- Expanded the selected custom-group test in [member_dashboard_presentation_test.exs](/workspace/memba/web/test/memba_web/member_dashboard_presentation_test.exs:203).
- It now proves:
  - only selected-group members appear in member rows and the name lookup;
  - member initials and avatar initials remain intact;
  - selected members retain alphabetically ordered role badges;
  - roles belonging to members outside the selected group are excluded;
  - conversation originator, participant, reply count, latest-replier, and activity presentation remain intact;
  - participant names are resolved against the selected member set, with the existing generic `Club member` fallback outside that set.
- No production change was required: task 004 had already connected selected-group members to the existing row presenters. This task added the missing focused regression evidence.

Validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/member_dashboard_presentation_test.exs` — 8 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick` — 1,145 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check` — full ExUnit and acceptance/browser quality gate passed.
- `git diff --cached --check` — passed.

Checked off exactly [task 005](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:7). No tasks were split, added, removed, or reordered; task 006 is now next.

ADR conformance:

- ADR 0007 and 0009: production context boundaries remain unchanged; the tested path uses public Membership and Messaging APIs.
- ADR 0015: the existing LiveView-owned member surface is preserved.
- ADR 0023: no routes or URL state were changed ahead of their later tasks.

The two-file validated diff is staged for Fabro’s checkpoint; no manual commit was made.