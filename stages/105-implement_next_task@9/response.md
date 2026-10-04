Implemented packet `task-009c-5b39ca0-message-compose-binding-1` with result `ready_for_review`.

[MembaWeb.MemberMessageLive.New](/workspace/memba/web/lib/memba_web/live/member_message_live/new.ex:35) now:

- Owns projection-backed data solely through the accepted `:compose_context` live-query result.
- Uses `current_identity_email` for fresh authorization.
- Routes committed notifications through `Binding.handle_notification/2`.
- Uses `Binding.rebind/3` before sending.
- Removes manual PubSub subscription, mount-captured club authorization, direct compose loaders, projector allowlists, and page-specific filtering.
- Preserves route, form, validation, retry, flash, navigation, and command state.
- Clears and leaves the private surface on delivered access loss while surfacing unexpected binding/source errors.

Focused tests in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_test.exs:297) now prove participant entry/exit, Person eligibility changes, exact Club/Group refreshes, unrelated isolation, club/group access loss, and typed validation-state preservation.

Validation:

- Focused compose/query/source suite: `80 tests, 0 failures`
- `bin/mix format --check-formatted`: passed
- `git diff --check`: passed

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). Task 009C remains unchecked. No acceptance feature was changed, and no unscoped `dev check` was run, as required by the packet; the workflow’s deterministic gate owns that final check.