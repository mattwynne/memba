Packet `001-15d75fd-02` is `ready_for_review`.

The carried task-001 implementation required no further code changes. Inspection confirmed:

- Actor-bearing `RemoveCustomGroupMember` is routed through the Club aggregate.
- Current group members and outside club managers can remove members.
- Ordinary and inactive outsiders are rejected.
- Self-removal, final-member removal, exact retries, identity validation, and system-group guards are covered.
- Real removals emit only `GroupMemberRemoved`; club membership, Admin authority, the custom group, and the trusted actor-free removal path remain intact.

Validation passed:

- Focused Membership suite: 115 tests, 0 failures.
- Admission/removal dispatch suite: 15 tests, 0 failures.
- `git diff --check`: passed.
- Worker-result JSON: valid.

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json). `todo.md` and acceptance features remain untouched. Per the packet exclusion, the full `dev check` was not run here; the workflow’s deterministic `dev_check` node owns that final gate.