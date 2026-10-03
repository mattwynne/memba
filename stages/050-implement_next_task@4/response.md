Implemented packet `task-008a-0b2466f-adapter-matrix-1` with result `ready_for_review`.

Changes:

- [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:1) now:
  - Recovers legacy Membership and Role removal scope from committed changes or the inactive membership projection row.
  - Preserves useful exact Group, Membership, Message, and conversation-access keys while adding conservative fallbacks for missing scope.
  - Includes exact conversation identity for follow/unfollow invalidations.
  - Keeps both delivery projectors aligned on exact message/delivery keys.
- [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:1) now explicitly covers every accepted projector/event family, compatibility path, fallback, recovery path, isolation rule, and malformed/unrelated input.
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). Task 008A remains unchecked as required.

| Projector/event family | Locked invalidation behavior |
| --- | --- |
| Club | Exact Club identity; Group and Role no-op compatibility events produce their logical Group/Role invalidations |
| Membership | Symmetric add/remove collection and identity keys for current and legacy events; committed-change/row recovery; global fallback when Person scope remains unknown |
| Person | Exact Person and email-collection keys for all six event families; global Person fallback |
| Group / GroupMembership | Exact club/group collections, identities, participation and Person keys; partial scope retained with scoped/global fallback |
| Role | Definition, permission, current/legacy assignment/removal, and membership-removal compatibility keys; committed-change/row recovery |
| Message / access / follow | Exact message, conversation, collection, access, Group and follow keys; club/global fallback where remaining scope cannot be recovered |
| Both delivery projectors | Compatible exact message-delivery and delivery keys for all six events; committed-change and either projection-row recovery; delivery-family fallback |

Validation passed:

- Adapter tests: `27 tests, 0 failures`
- Dashboard and conversation-detail query vocabulary: `8 tests, 0 failures`
- `bin/mix format --check-formatted`: exit 0
- `git diff --check`: exit 0
- Package boundary scan: no Memba or Commanded references under `packages/live_query`
- Exact unrelated club, group, conversation, Person, message, and delivery tuples remain isolated; unrelated projectors and malformed messages return `:ignore`.

No unresolved matrix mapping remains. Per the packet’s binding exclusion, I did not run `dev check`; the workflow’s deterministic `dev_check` node owns that full gate.