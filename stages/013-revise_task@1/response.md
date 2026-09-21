Packet `004-0bc4306-06` is `ready_for_review`.

Implemented:

- Prevented raw [`follow_conversation/2`](/workspace/memba/web/lib/memba/messaging.ex:207) callers from supplying trusted `authorizing_group_ids`; authoritative current-member and sender boundaries still capture group causality.
- Added a remove-A / forged-B / re-add regression proving no follow event, projected follow, or notifications return until a new authorized follow.
- Updated the surviving-group root test to use `send_club_message_as_current_member/2`, verifying group B is recorded on both `MessageSent` and `ConversationFollowed`.

Validation passed:

- Membership/removal focused suite: 42 tests, 0 failures.
- Messaging focused suite: 82 tests, 0 failures.
- `git diff --check`: passed.

The todo remains unchecked as required. The routing artifact is updated at [`latest-worker-result.json`](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json). No unresolved items. `dev check` was not run because this packet explicitly reserves it for task 017 and the deterministic workflow node.