Packet `001-da2964e-02` is `ready_for_review`.

The carried task-001 implementation was verified as complete:

- Public actor-bearing custom-group removal routes through `Membership.Club`.
- Current group members and active outside admins can remove members.
- Ordinary and inactive outsiders, invalid identities, mismatched targets, and system groups are rejected.
- Self-removal, final-member removal, and event-free retries—including self-retry after leaving—are supported.
- Real removals emit only `GroupMemberRemoved`.
- Club membership, Admin role, and management permission remain intact.
- The trusted actor-free removal path remains separate.

One focused-test isolation issue was corrected in [public_api_test.exs](/workspace/memba/web/test/memba/membership/public_api_test.exs:39): the test now explicitly loads `Memba.Membership` before checking exported functions.

Validation:

- Focused aggregate/API/router suite: `115 tests, 0 failures, 108 excluded`
- Admission/removal dispatch suite: `15 tests, 0 failures`
- `git diff --check`: passed
- Worker-result JSON structure and packet identifiers: validated

The required artifact is at [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json:1), with no unresolved items. `todo.md` and acceptance features were untouched. Per packet constraints, the iteration-wide `dev check` was not run in this worker; the deterministic workflow gate owns it.