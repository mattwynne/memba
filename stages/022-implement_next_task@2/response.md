Implemented task 013 and left it unchecked for independent review.

1. Selected task

   `- [ ] 013 Existing last-member/last-Admin invariants stay intact.`

2. Changes made

   Strengthened the aggregate regressions in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:256):

   - The final-member test now gives that member an active custom-group membership and proves removal still returns `{:error, :last_active_member}`.
   - The sole-Admin test now gives that Admin an active custom-group membership and proves removal still returns `{:error, :last_membership_administrator}` while another ordinary club member remains.
   - Both tests verify the custom membership is active before removal is attempted, exercising the new departure-cleanup path rather than only the old baseline path.

   No production change was necessary. [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:150) already evaluates the last-member and last-Admin guards before constructing club or custom-group removal events.

3. Focused validation

   - Club aggregate baseline before editing: 50 tests, 0 failures.
   - Club, write API, role authorization, and lifecycle policy regression set: 68 tests, 0 failures.
   - Membership-administration domain scenarios and Club replay tests: 19 tests, 0 failures.
   - `mix format --check-formatted test/memba/membership/club_test.exs`: passed.
   - `git diff --check`: passed.

4. Todo state

   The selected line remains exactly unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:15):

   `- [ ] 013 Existing last-member/last-Admin invariants stay intact.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002: the invariant remains an aggregate decision backed by event-sourced Club state.
   - ADR 0024: Club remains the serialized consistency boundary for active membership, final-member protection, and Admin continuity.
   - ADR 0011: typed caller-generated membership identities remain unchanged.
   - ADRs 0007, 0021, and 0022 are unaffected; this task introduced no cross-context work, projections, or synchronization behavior.