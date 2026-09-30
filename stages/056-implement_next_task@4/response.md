Implemented packet `task-005-bcf5640-dashboard-binding-1` with result `ready_for_review`.

Key changes:

- Added the provisional scoped Memba notification adapter in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex), covering Club, Membership, Person, Group, GroupMembership, Role, Message, and ConversationGroupAccess notifications with exact scopes and conservative fallbacks.
- Extended [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) with a single `:dashboard` query descriptor and replacement interests for collections, represented identities, role badges, permissions, participation, conversations, and access.
- Migrated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex) from manual subscription/projector filtering to `Binding.bind/4`, `Binding.rebind/3`, and `Binding.handle_notification/2`. The broad MemberEmailDelivery refresh was removed.
- Added focused proof for member entry/removal/order/counts, represented Person and Group isolation, role assignment/definition/removal, route-interest replacement, current membership loss, and transient-state preservation.
- Wrote the required artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). The task remains unchecked in `todo.md`.

Validation passed:

- Live-query and dashboard-query tests: 18 tests, 0 failures.
- Dashboard presentation, LiveView, admission, and targeted-add tests: 89 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.
- Worker result JSON parsed successfully.

No unresolved issues. The full `dev check` was intentionally not run because this packet delegates that unscoped gate to the workflow’s deterministic `dev_check` node.