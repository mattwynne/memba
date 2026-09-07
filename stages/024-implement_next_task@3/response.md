Implemented and checked off task 003. The final worktree passes the required per-task quality gate.

1. Selected task

   `003 It must return plain presentation summaries (group ID, name, key, optional email slug/address information, and active member count) in stable display order, and validate club/group/person relationships within Membership rather than leaking projection schemas.`

2. Changes

   - Enhanced [`Membership.list_active_groups_for_member/2`](/workspace/memba/web/lib/memba/membership.ex:976) to:
     - Return `group_id`, `name`, `group_key`, `email_slug`, optional `email_address`, and `active_member_count`.
     - Order groups deterministically by name and group ID.
     - Count only active group memberships backed by matching active club memberships and projected people.
     - Validate club, group, membership, and person relationships through Membership-owned joins.
     - Continue returning plain maps rather than projection structs.
   - Extended [`ClubInboundEmailAddress`](/workspace/memba/web/lib/memba/club_inbound_email_address.ex:13) with `address/2` for generic group addresses while preserving `address/1` as the Everyone-compatible API.
   - Added focused summary, ordering, count, optional-address, cross-club, inactive-membership, and encapsulation coverage in [`query_test.exs`](/workspace/memba/web/test/memba/membership/query_test.exs:361).
   - Added generic group-address normalization and invalid-input coverage in [`club_inbound_email_address_test.exs`](/workspace/memba/web/test/memba/club_inbound_email_address_test.exs:17).

3. Validation

   - TDD red phase:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/club_inbound_email_address_test.exs test/memba/membership/query_test.exs`
     - Failed on the missing `address/2` API and missing summary behavior.
   - Focused passing suite:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/club_inbound_email_address_test.exs test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs`
     - 39 tests, 0 failures.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" mix format ...`
   - Final per-task quality gate:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - 1,144 tests, 0 failures.
   - `git diff --check` passed.

4. Todo check-off

   Checked off only [`task 003`](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:5).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 004 remains the first unchecked task.

6. ADR conformance

   - ADR 0007: callers receive Membership-owned plain summaries and do not access Membership projection schemas.
   - ADR 0009: aggregation and relationship validation use Membership’s Ecto read models behind its public query API.
   - ADRs 0021–0022: no projector, committed-change publication, or projection-barrier behavior was altered; test fixtures continue to dispatch commands with strong consistency before querying.