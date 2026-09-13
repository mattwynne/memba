Implemented and checked off task 009. Already-open compose, conversation-detail, and delivery-detail LiveViews now stop exposing private data when membership or conversation access is revoked.

1. Selected task

`009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.`

2. Changes made

- [member_message_live/new.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:21)
  - Subscribes compose screens to committed group, group-membership, and club-membership projection changes.
  - Reloads the server-authoritative compose context after relevant changes and immediately before submission.
  - Clears private audience metadata and navigates to the selected group’s safe surface when access is lost.
  - Retains the existing final submission authorization check.

- [member_message_live/show.ex](/workspace/memba/web/lib/memba_web/live/member_message_live/show.ex:17)
  - Rechecks effective conversation access after current-member membership changes or matching conversation grant changes.
  - Navigates away from inaccessible conversation details while preserving selected-group context.

- [member_message_delivery_live/show.ex](/workspace/memba/web/lib/memba_web/live/member_message_delivery_live/show.ex:14)
  - Now subscribes to committed read-model changes.
  - Applies the same reauthorization and safe navigation behavior to delivery details.

- Added routed LiveView regressions covering:
  - Compose metadata after membership removal.
  - Compose submission during the notification race.
  - Open message detail after membership removal and conversation-access revocation.
  - Open delivery detail after both forms of revocation.

3. Validation

- TDD red phase: the new focused regressions produced five expected missing-navigation failures before implementation.
- Focused LiveView suite:
  - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/live/member_dashboard_live_test.exs`
  - Result: 97 tests, 0 failures.
- Formatting verification:
  - `devenv shell -- mix format --check-formatted ...`
  - Result: passed for every touched Elixir file.
- Broad quick gate:
  - `PATH="$PWD/bin:$PATH" dev check --quick`
  - Result: 1,277 tests, 0 failures.
- Targeted real-browser scenario:
  - `PATH="$PWD/bin:$PATH" dev acceptance --name '^Bob starts an Admin conversation in the web app$'`
  - Result: 1 scenario, 7 steps, all passed.
- `git diff --check`: passed.

The full `dev check` was not run in this per-task node because task 011 explicitly owns the final full delivery gate.

4. Todo check-off

Changed only [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:11):

`- [x] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.`

5. Todo structure

No tasks were split, added, removed, or reordered. Tasks 010 and 011 remain unchecked.

6. ADR conformance

- ADR 0015: behavior remains implemented through member-facing LiveViews.
- ADR 0021: refreshes are triggered by committed `ReadModelChanges` projection notifications.
- ADR 0007: authorization is reloaded through Membership and Messaging public APIs, including `MemberMessageDetail`; no cross-context projection joins were added to the web layer.
- ADR 0023: access-loss navigation preserves the selected group in the URL.
- ADRs 0022 and 0024 remain unaffected: no projection-barrier semantics or membership consistency boundaries were changed.