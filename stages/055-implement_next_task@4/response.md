Implemented packet `task-008d2-621a568-message-compose-query-1` with result `ready_for_review`.

Changes:

- Added [member_message_compose_query.ex](/workspace/memba/web/lib/memba_web/member_message_compose_query.ex), defining `:member_message_compose` on `:compose_context`.
- Added focused coverage in [member_message_compose_query_test.exs](/workspace/memba/web/test/memba_web/member_message_compose_query_test.exs).
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).

The query returns exactly `selected_club`, `current_member`, `audience_group`, `active_member_count`, and `message_audience`. It freshly resolves normalized primary or attached-email identity, active-club authority, membership by Person ID, audience participation, and all selected-group participants. Recipient count includes only primary-email-eligible participants, while exact Person and Person-email interests cover all represented participants—including those currently ineligible.

Focused validation passed:

- Combined compose-query and Membership tests: `40 tests, 0 failures`
- `bin/mix format --check-formatted`: exit `0`
- `git diff --check`: exit `0`

Tests cover default Everyone and explicit audience semantics, `:forbidden` versus `:not_found`, authorization loss, both primary-email eligibility directions, participant entry/exit, complete deduplicated interests, singular/plural presentation, and unrelated identity isolation.

Implementation changes are limited to the two packet-authorized code/test paths. No LiveView wiring, Membership API, adapter, package, projector, schema, command, event, plan, todo, matrix, ADR, or acceptance feature changed. Task `008D2` remains unchecked for independent review. Per packet instructions, the full `dev check` was not run; the deterministic workflow node owns that gate.