Packet `001-af147c6-01` is implemented, but the worker result is `replan` because the required full `./bin/dev check` exceeded Fabro’s hard 600-second command limit and produced no final exit status.

Implemented:

- Added the actor-bearing [`RemoveCustomGroupMember`](/workspace/memba/web/lib/memba/membership/commands/remove_custom_group_member.ex) command and registered it on the Club route.
- Exposed `Membership.remove_custom_group_member/1` and `/2`.
- Added authoritative Club-aggregate authorization and identity validation.
- Supports member removal, outside-admin removal, self-removal, final-member removal, and event-free exact retries.
- Real removals emit only `GroupMemberRemoved`; club membership, Admin roles, and management authority remain intact.
- Preserved the trusted actor-free `RemoveGroupMember` path.
- Added aggregate, command-shape, router, public API, projection, idempotency, and invariant coverage.

Validation:

- Aggregate/API/router suite: 108 tests, 0 failures.
- Admission/removal dispatch suite: 15 tests, 0 failures.
- Combined focused suite: 115 tests, 0 failures.
- `git diff --check`: passed.
- `./bin/dev check`: terminated after 602 seconds while passing browser scenarios were still running; no successful final exit was available.

The required result is recorded in [`latest-worker-result.json`](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json). `todo.md` and acceptance feature files remain untouched.