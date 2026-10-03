Result: `ready_for_review` for packet `task-008a-5a0be69-projector-contract-revision-2`.

Implemented the corrected classifier in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:103) and expanded focused coverage in [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:393).

| Projector | Supported event families | Invalidation/recovery behavior |
| --- | --- | --- |
| Club | Club create/update; Group and Role compatibility publications | Exact Club, Group, role, permission, or member-role keys. Membership-removal and other unsupported pairings are contract violations. |
| Membership | Current and legacy member add/remove | Exact club-member, membership, Person, and Person-clubs keys. Only legacy `MemberRemoved` can recover missing scope, using the retained membership row. |
| Person | Person creation and all email-address families | Exact Person and Person-email collection keys. |
| Group | Group creation and email-slug assignment | Exact club-group collection and Group identity. |
| GroupMembership | Member added/removed | Exact group-member, Person, Person-groups, and participation keys. |
| Role | Definition, permission, current/legacy assignment/removal, membership-removal compatibility | Exact role/member keys; legitimate club permission fan-out; membership removal does not invent a role ID. Legacy removal recovery uses the retained membership row. |
| Message | Root and reply `MessageSent` | Exact message/conversation keys plus the legitimate club-conversation collection scope. |
| ConversationGroupAccess | Grant/revoke | Exact group-conversation collection, access relationship, conversation, and Group keys. |
| ConversationFollow | Follow/unfollow and default/true auto-follow `MessageSent` | Exact follow and conversation keys. Explicit `sender_follows_conversation: false` is ignored. |
| MemberEmailDelivery | Created/delivered/delayed/bounced/spam complaint | Exact message-delivery and delivery keys. `EmailDeliveryOpened` is ignored; no changes/row recovery remains. |
| MembaStaffEmailDelivery | Same five state-changing families | Identical exact delivery keys. `EmailDeliveryOpened` is ignored; no changes/row recovery remains. |

Known malformed or unsupported projector/event pairings now return a stable app-owned `read_model_contract_violation` without producing partial or fallback invalidations. Unrelated projectors and malformed outer envelopes remain ignored. The generic package was unchanged.

Validation passed:

- Adapter suite: 25 tests, 0 failures.
- Dashboard/conversation query vocabulary: 8 tests, 0 failures.
- Generic package contains no Memba or Commanded references.
- Formatting check passed.
- `git diff --check` passed.

The required artifact is at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). There are no unresolved conflicts. Task 008A remains unchecked as required. The packet explicitly prohibited running `dev check`; the workflow’s deterministic `dev_check` node remains responsible for the full gate.