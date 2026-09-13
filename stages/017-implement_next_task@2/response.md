Implemented and checked off task 010.

1. Selected task

   `010 Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.`

2. Changes made

   Added [conversation_access_boundary_test.exs](/workspace/memba/web/test/memba_web/conversation_access_boundary_test.exs:1), which enforces that member-facing dashboard, compose, conversation-detail, and delivery-detail paths:

   - Do not access Membership or Messaging projection schemas directly.
   - Do not import Ecto queries or access `Memba.Repo`.
   - Resolve discovery through `Membership.list_discoverable_groups_for_member/2`.
   - Resolve participation through `Membership.list_active_groups_for_member/2`.
   - Load conversations through the public Messaging API.
   - Authorize details through `Messaging.member_has_conversation_access?/4`.

   The existing production implementation already conformed, so no production-code changes were necessary.

3. Focused validation

   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/conversation_access_boundary_test.exs test/memba/messaging/no_crud_spike_test.exs test/memba/messaging/conversation_group_access_projection_test.exs`
     - 16 tests, 0 failures.
   - `devenv shell -- mix format --check-formatted test/memba_web/conversation_access_boundary_test.exs`
     - Passed.
   - `git diff --check`
     - Passed.

   The full `dev check` was not run because task 011 explicitly owns the final delivery gate.

4. Todo check-off

   Updated [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:13):

   `- [x] 010 Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.`

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 011 remains unchecked.

6. ADR conformance

   - ADR 0007: Messaging obtains active group membership through Membership’s public query API; web modules do not depend on either context’s projection schemas.
   - ADR 0002: authorization remains in public application/query services rather than being recreated as web-layer database logic.
   - ADR 0009: Ecto projection details remain encapsulated within their owning contexts.
   - ADR 0015: member-facing application surfaces remain LiveViews.
   - ADR 0021: projector module references in LiveViews are limited to committed read-model-change subscriptions, not direct projection queries.