Packet `001-c228a6d8-2` is complete with result `ready_for_review`.

- Added the regression test `reports current non-participation while the group membership projection is stale` in [authoritative_custom_group_target_test.exs](/workspace/memba/web/test/memba/membership/authoritative_custom_group_target_test.exs:70).
- The test proves the person remains an active club member, the stopped `GroupMembership` projection remains `active: true`, and the authoritative resolver returns `active_group_member?: false` after committed removal.
- Added deterministic subscriber barriers for clean test teardown.
- Production code did not require changes.
- Focused validation passed: `19 tests, 0 failures`.
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/066-request-group-access/.delivery/latest-worker-result.json:1), with no unresolved items.
- Task 001 remains unchecked as required.

`dev check` was not run because this packet explicitly prohibits full-suite commands; the workflow’s deterministic `dev_check` node remains responsible for that final gate.