1. **Selected todo line**
   - `006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`

2. **Changes made**
   - `web/lib/memba/membership.ex`
     - Added `Membership.invite_club_member_as_club_member/2`.
     - The new member-facing application service:
       - Requires `actor_person_id`.
       - Authorizes the actor with `club.manage_members`.
       - Delegates to existing `invite_club_member/2`, preserving the shared Staff invitation lifecycle rules.
   - `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Added focused domain/application coverage proving Membership Admin invitations reuse:
       - Pending invitation creation.
       - Duplicate pending invitation resend with a single invitation record.
       - Token hash/rotation lookup behaviour.
       - Profile completion acceptance flow.
       - Duplicate active member rejection.
       - Ordinary member authorization rejection.
   - `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off only task `006`.

3. **Focused validation commands run**
   - Attempted:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Failed before tests due sandbox `PGHOST` mismatch.
   - Passed:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Result: `10 tests, 0 failures`.
   - Passed:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/club_member_invitation_lifecycle_test.exs`
   - Passed:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `736 tests, 0 failures`.
   - Passed:
     - `git diff --check`

4. **Exact todo check-off made**
   - From:
     - `- [ ] 006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`
   - To:
     - `- [x] 006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - Relevant accepted ADRs were respected:
     - ADR 0002: kept invitation lifecycle behaviour in the Commanded-backed Membership application service.
     - ADR 0007: kept Membership invitation rules inside the Membership context.
     - ADR 0009: tests assert through projected read models after strongly consistent dispatch.
     - ADR 0011: tests continue using caller-generated aggregate IDs.
     - ADR 0022: validation uses strong consistency/read-model assertions for read-your-writes behaviour.