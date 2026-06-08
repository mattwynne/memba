1. **Selected todo line**
   - `010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

2. **Changes made**
   - Updated `web/test/memba/membership/public_api_test.exs`.
   - Added Membership public API coverage that:
     - Membership Admin invitation rejects an already-active club member by normalized email, including alternate email.
     - Membership Admin duplicate pending invite resends the original invitation, rotates the token, increments resend count, and does not create a duplicate invitation projection.
   - Strengthened the existing authorization/Staff preservation test to assert the Staff/system `invite_club_member/2` path still works without a club-member actor and creates the expected pending invitation.
   - Existing ordinary-membership assignment coverage from the previous checked task remains in the same focused test file and was included in the validation run.
   - Checked off only task `010` in `docs/iterations/029-membership-admin-invitations/todo.md`.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/public_api_test.exs`
     - Initially failed due indentation; fixed with a targeted patch.
     - Re-run passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/public_api_test.exs`
     - Failed due sandbox PostgreSQL readiness/lock mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/public_api_test.exs`
     - Passed: `24 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `739 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`
   - To:
     - `- [x] 010 Add or update domain/application tests for authorization, duplicate active member rejection, duplicate pending resend, ordinary membership assignment, and Staff-flow preservation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan.
   - Tests exercise the `Memba.Membership` public application service API rather than bypassing the bounded context.
   - Event-sourced behaviour is verified through Commanded execution results and projections.
   - The Staff/system actor path remains separate from the Membership Admin actor-authorized path.
   - No feature files, routes, LiveView/UI, dependencies, or unrelated behaviour were changed.