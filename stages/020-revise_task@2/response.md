Packet `004-34d71d9-07` is ready for review.

Implemented:

- Raw `follow_conversation/2` no longer inherits club-wide generation authority or trusts caller-provided source groups.
- Authorized current-member follows capture authoritative groups and membership generation inside the stable authorization checkpoint.
- Generation-less historical cleanup now uses durable EventStore ordering and requires a matching re-add before preserving a later follow.
- The cleanup decision remains replay-safe through the existing Messaging-owned `ConversationUnfollowed.follow_retained` fact.
- Added regressions for unrelated generation advances and actual generation-less `ConversationFollowed` and `MessageSent` histories before removal and after re-add.
- Preserved accepted task-001 removal behavior and system-group safeguards.
- Left `todo.md` unchanged.

Validation:

- Membership-focused suite: 44 tests, 0 failures.
- Messaging-focused suite: 83 tests, 0 failures.
- Formatting check passed.
- `git diff --check` passed.
- Full `dev check` was not run, as the packet assigns that to the deterministic workflow node.

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json) with `result: "ready_for_review"` and no unresolved items.