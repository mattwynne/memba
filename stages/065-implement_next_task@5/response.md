Implemented packet `task-008e-94fa7d7-delivery-detail-query-1` with result `ready_for_review`.

Changes:

- Added [member_message_delivery_query.ex](/workspace/memba/web/lib/memba_web/member_message_delivery_query.ex:1), defining `:member_message_delivery` on the `:delivery_detail` assign with stable `club_id`, `message_id`, and `authenticated_email` inputs.
- The query composes the accepted fresh-authorized detail loader, preserves `:forbidden`/`:not_found`, and registers exact club, membership, Person, group-participation, conversation/access, requested/root-message, delivery-collection, delivery-ID, sender, and recipient interests.
- Added seven focused tests in [member_message_delivery_query_test.exs](/workspace/memba/web/test/memba_web/member_message_delivery_query_test.exs:1), covering authorization refresh, reply/root scope, both delivery projectors, unrelated-message isolation, independent status/reason convergence, represented identities, and zero-recipient presentation.
- Wrote the required result artifact at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

Validation passed:

- Focused combined suite: 58 tests, 0 failures.
- `bin/mix format --check-formatted`: exit 0.
- `git diff --check`: exit 0.
- Worker-result JSON parses and satisfies the required identity/result fields.

Task 008E remains unchecked. No LiveView wiring or excluded files changed. Per the packet, the full `dev check` was not run; the deterministic workflow owns that final gate.