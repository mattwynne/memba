The final whitespace check passed. The only changes are the new application lifecycle test file and the selected todo check-off.Implemented the next unchecked task.

1. **Selected todo line**
   - `012 Add domain/application tests for pending invitation creation, duplicate active block, duplicate pending resend, existing-person acceptance, unknown-person profile completion, abandoned profile completion, and accepted-link reuse.`

2. **Changes made**
   - Added `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
   - New application-level lifecycle tests cover:
     - pending invitation creation without person/member creation;
     - duplicate active member invitation blocked by normalized email;
     - duplicate pending invitation resends and keeps one pending invitation;
     - existing complete person accepts and becomes an active ordinary member;
     - unknown invitee profile completion creates person, membership, and accepted invitation;
     - abandoned profile completion leaves invitation pending and token reusable;
     - accepted invitation token remains lookupable and does not create duplicate membership on reuse.
   - Checked off only task `012` in `docs/iterations/028-staff-member-invitations/todo.md`.

3. **Validation**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed after applying formatter-equivalent fixes.
   - Focused test:
     - Initial direct `PATH="$PWD/bin:$PATH" bin/mix test ...` hit sandbox PGHOST socket mismatch.
     - Re-ran with:
       - `devenv shell -- bin/mix test test/memba/membership/club_member_invitation_lifecycle_test.exs`
       - Passed: `7 tests, 0 failures`.
   - Adjacent Membership invitation/public API tests:
     - `devenv shell -- bin/mix test test/memba/membership/club_invitation_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs test/memba/membership/invitation_token_test.exs test/memba/membership/public_api_test.exs test/memba/membership/club_member_invitation_lifecycle_test.exs`
     - Passed: `40 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `713 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 012 Add domain/application tests...`
   - To:
     - `- [x] 012 Add domain/application tests...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Tests exercise Membership command/event application APIs rather than CRUD shortcuts.
   - ADR 0007: Stayed within the Membership bounded context and public Membership API.
   - ADR 0009: Tests assert Ecto projection outcomes for invitation, person, and membership read models.
   - ADR 0011: Tests use caller-generated UUIDs for invitation/person/membership identities.
   - ADR 0021/0022: Tests use strong consistency for read-your-writes projection assertions.