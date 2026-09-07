Implemented and checked off task 021:

> Add focused Membership, Messaging, dashboard-presentation, LiveView/router, and browser tests for generic custom-group fixtures, selection scope, no-disclosure not-found behaviour, remembered selection, group-aware compose, existing Everyone regression, and club/group mismatch rejection.

Changes:

- Audited the existing focused coverage across Membership, Messaging, dashboard presentation, router/LiveView, compose, and browser-local selection tests.
- Added the missing future named-group recipient-composition regression in [send_club_message_test.exs](/workspace/memba/web/test/memba/messaging/send_club_message_test.exs:238).
- The new test uses a generic “Trips committee” group and proves that:
  - Active group members receive the message.
  - An active club member outside the group does not receive it.
  - A removed group member does not receive it.
  - The named group receives write access to the conversation.
  - The conversation appears in that group’s query results.
- No production code or acceptance feature files were changed.

Validation:

- Focused Messaging test: 11 tests, 0 failures.
- Cross-layer focused suite covering Membership, Messaging, dashboard presentation, router/LiveView, and compose: 124 tests, 0 failures.
- Browser hook/configuration tests: 54 tests, 0 failures.
- `mix format --check-formatted`: passed.
- Full `PATH="$PWD/bin:$PATH" dev check`: exited successfully. The only subsequent change was the non-executable todo check-off.
- `git diff --check`: passed.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:23):

```markdown
- [x] 021 Add focused Membership, Messaging, dashboard-presentation, LiveView/router, and browser tests for generic custom-group fixtures, selection scope, no-disclosure not-found behaviour, remembered selection, group-aware compose, existing Everyone regression, and club/group mismatch rejection.
```

No tasks were split, added, reordered, or otherwise checked off. Task 022 remains pending.

ADR conformance:

- ADR 0002/0009: the regression exercises event-sourced Membership setup and projected Messaging query results.
- ADR 0007: recipient composition continues through Membership’s public query boundary; no projection-schema dependency was added to Messaging or the web layer.
- ADR 0013/0015/0023: existing focused PhoenixTest, LiveView, and URL-addressable route coverage was retained and validated.
- ADR 0021/0022: test setup uses established strong projection consistency and avoids timing sleeps.
- ADR 0003/0010: shared Cucumber features and runner-debt tags were left untouched for task 022.