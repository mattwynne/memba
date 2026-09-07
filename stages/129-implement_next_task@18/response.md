Implemented task 018: “Review all member-facing conversation detail, in-app reply, follow/unfollow, receipt/delivery, and direct action paths.”

The review is recorded in [conversation-access-review.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/conversation-access-review.md:1). It documents every relevant route and action, its current authorization boundary, existing test coverage, and the implementation seams for tasks 019–020.

Key findings:

- Conversation detail and delivery pages remain hard-coded to Everyone access. Authorized Admin/custom-group members cannot yet open private conversations.
- In-app reply already checks active membership in any write-granted group.
- In-app follow/unfollow checks only active club membership, not conversation group access.
- Receipt queries rely on the shared detail loader as their web authorization gate.
- URL `group_id` is navigation context and must never become authority.
- Direct email links correctly omit group context, requiring authorization across all active group memberships.
- Signed email stop-follow remains an intentional reduction-only exception.
- Multi-group authorization must succeed through any qualifying active group.

Validation:

- `dev test test/memba_web/member_message_detail_loader_test.exs test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/controllers/conversation_follow_controller_test.exs test/memba/messaging/post_message_reply_test.exs`
  - 25 tests, 0 failures.
- `git diff --check`
  - Passed.

No production behavior or automated tests were changed because task 018 is specifically the review slice; authorization changes remain assigned to tasks 019 and 020. Per the project’s docs-only rule, `dev check` was not rerun for this task.

Checked off only [todo task 018](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:20). No tasks were split, added, removed, or reordered.

The review preserves ADR 0002’s command/query separation, ADR 0005’s recipient-resolution boundary, ADR 0007’s Membership/Messaging public API boundary, ADR 0015’s LiveView surfaces, ADR 0021’s committed read-model refresh pattern, and ADR 0023’s URL-addressable navigation state without treating browser state as authorization.