Task 005 is implemented and ready for independent review.

1. Selected task

   `- [ ] 005 Make duplicate addition an idempotent no-op and carry sufficient actor/new-transition information for the welcome use case.`

2. Changes made

   - Added [CustomGroupAdmission](/workspace/memba/web/lib/memba/membership/custom_group_admission.ex:1), an explicit use-case result containing the actor and target identities plus:
     - `:member_added` for a committed new transition.
     - `:already_member` for an idempotent retry.
   - Updated [membership.ex](/workspace/memba/web/lib/memba/membership.ex:88) so `add_custom_group_member/2` derives that result from Commanded’s execution result, without projection preflight or projection-only mutation.
   - Preserved explicitly requested Commanded `:returning` modes for existing lower-level callers.
   - Kept `GroupMemberAdded` actor-free and backward-compatible; the actor belongs to the admission result rather than the shared event used by trusted system-group operations.
   - Added aggregate and dispatch coverage in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:1249) and [add_custom_group_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_custom_group_member_dispatch_test.exs:96). The tests prove a duplicate emits no event and reports `:already_member`.
   - No acceptance feature files were changed.

3. Focused validation

   - Initial TDD run failed as expected while the actor/new-transition contract was absent.
   - Final focused run:

     `PATH="$PWD/bin:$PATH" dev test test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/club_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/group_projection_test.exs`

     Result: 72 tests, 0 failures.

   - `mix format --check-formatted ...` passed for all touched Elixir files.
   - `git diff --check` passed.
   - Full `dev check` was not run because it remains explicit task 016.

4. Todo state

   Still exactly unchecked and ready for independent review:

   `- [ ] 005 Make duplicate addition an idempotent no-op and carry sufficient actor/new-transition information for the welcome use case.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002: transition status is derived from the aggregate’s persisted event decision.
   - ADR 0007: the result remains owned by Membership’s public application-service boundary.
   - ADR 0009: no projection mutation or projection-based transition inference was introduced.
   - ADR 0011: caller-generated typed identities are preserved in the result.
   - ADR 0024: duplicate detection remains serialized inside `Membership.Club`; the application service only interprets its execution result.