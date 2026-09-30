Packet `task-001-2bcb025-inventory-revision-2` is `ready_for_review`.

Revised [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md:78) to close all five review gaps:

- Added `Memba.Messaging.Projectors.MembaStaffEmailDelivery`, including exact message/delivery scope derivation, broad fallback, independently committed projector convergence, and conversation/delivery-detail proof gaps.
- Separated represented-member role-label and badge interests from current-actor permission invalidation, including the missing open-view badge-refresh proof.
- Distinguished exact role assignment/removal from membership-removal compatibility events lacking `role_id`.
- Corrected `ConversationAccessGrantedToGroup` to account for upserting an existing grant whose previous access level is unavailable.
- Corrected dashboard ordering: replies update derived counts, latest replier, and participants without reordering root-time-ordered conversations.

The required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1) was updated with matching packet identity and successful validation evidence.

Validation passed with exit status `0`:

- Required matrix and fully qualified projector check
- Semantic checks covering all five corrections
- `git diff --check`
- Worker-result JSON and packet-identity validation
- Final `git status --short`

Final status contains only:

```text
 M docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json
 M docs/iterations/067-live-projection-queries/migration-matrix.md
```

This was the packet’s documentation-only revision, so `dev check` was intentionally not run; the workflow’s later deterministic gate owns the full suite. The todo line remains unchecked as required.