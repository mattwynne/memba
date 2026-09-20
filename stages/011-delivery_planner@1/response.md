Prepared one implementation worker packet for task `001`, bound to checkpoint `af147c6426110ebf4368bf833f52720c316770a0`.

The packet defines a bounded Membership-domain outcome:

- Add the actor-bearing public custom-group removal command and API.
- Authorize against current `Club` aggregate state.
- Support member, outside-admin, self, and last-member removal.
- Reject outsiders, invalid identities, and system groups.
- Reuse only `GroupMemberRemoved`, preserving club membership and Admin roles.
- Cover idempotency and focused aggregate/dispatch/API tests.
- Leave follow cleanup, delivery authorization, LiveView behavior, and UI controls to later tasks.

I consolidated original todo lines `001`–`003` because they form one indivisible use case; their exact lineage is recorded in the execution state.

Artifacts:

- [current-worker-packet.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/current-worker-packet.json)
- [execution-state.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/execution-state.json)
- [planner-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/planner-result.json)
- [todo.md](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/todo.md)

The repository’s deterministic planner validations and `git diff --check` pass. No application code, tests, features, ADRs, or plan content were changed. `dev check` was not run because this handoff contains planning artifacts only.