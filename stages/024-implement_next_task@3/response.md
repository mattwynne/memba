Implemented and checked off task 003:

> Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.

Changes made:

- Extended the Messaging access regression in [conversation_group_access_projection_test.exs](/workspace/memba/web/test/memba/messaging/conversation_group_access_projection_test.exs:306) to prove that an active club member:

  - can discover an unjoined group;
  - does not receive that group from `list_active_groups_for_member/2`;
  - cannot read its conversation;
  - cannot follow or unfollow its conversation until actually joining.

- Added an architecture boundary check in [no_crud_spike_test.exs](/workspace/memba/web/test/memba/messaging/no_crud_spike_test.exs:34) requiring Messaging to use `list_active_groups_for_member/2` and prohibiting use of the discovery API.
- No production behavior or acceptance feature files were changed because the existing implementation already preserved the correct boundary.

Validation:

- `mix format ...` — passed.
- Focused Membership and Messaging tests — 48 tests, 0 failures.
- `dev check --quick` on the final diff — 1,261 tests, 0 failures.
- `git diff --check` — passed.

Todo check-off made in [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:5):

```markdown
- [x] 003 Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.
```

No tasks were split, added, removed, or reordered. Task 004 is now the first unchecked task.

This conforms to ADR 0007 by keeping Messaging dependent on Membership’s public participation query rather than its projections. ADR 0009 remains respected because tests exercise the existing Ecto read models without changing projection ownership. ADRs 0021, 0022, and 0024 are unaffected: no publication, synchronization, aggregate, system-group, or membership invariants changed.