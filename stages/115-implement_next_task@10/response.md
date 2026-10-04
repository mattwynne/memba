Implemented packet `task-009d-de561b6-delivery-detail-binding-1` with result `ready_for_review`.

- Migrated [show.ex](/workspace/memba/web/lib/memba_web/live/member_message_delivery_live/show.ex) to `LiveQuery.Binding` and the accepted `MemberMessageDeliveryQuery`.
- `:delivery_detail` is now the sole projection-backed result assign.
- Removed direct `MemberMessageDetail` loading, mount-captured club authorization, manual PubSub subscription, projector allowlist, page-specific predicates, and spread projection assigns.
- Added focused coverage in [show_test.exs](/workspace/memba/web/test/memba_web/live/member_message_delivery_live/show_test.exs) for exact status/reason refreshes, independent-projector convergence in both orders, unrelated-message isolation, represented-Person updates, fresh access loss, coherent assign ownership, route/flash/back-link/disclosure preservation, and existing delivery presentation.
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).

Validation passed:

- Focused delivery/query/source/conversation suite: `88 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted`: exit `0`
- `git diff --check`: exit `0`
- Worker-result artifact parses as valid JSON

Task 009D remains unchecked. No acceptance feature, plan, todo, matrix, or contract file was changed. Per the packet’s explicit constraint, no `dev check` or other unscoped full-suite command was run; the deterministic workflow owns that final gate.