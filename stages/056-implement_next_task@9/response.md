1. **Selected todo line**
   - `008 Keep the Admin invitation form email-only.`

2. **Changes made**
   - `web/lib/memba_web/live/member_invitation_live/new.ex`
     - Added the member-facing Membership Admin invitation form.
     - The form accepts only `invitation[email]`.
     - Sanitizes invitation params down to email only, ignoring crafted extra fields.
     - Validates email input.
     - Submits via `Membership.invite_club_member_as_club_member/2`.
     - Sends the shared club member invitation email.
     - Shows clear success/error flashes.
   - `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Added coverage that the member-facing invitation form has only the email input and no name/role fields.
     - Added coverage that a crafted submit containing `name` and `role` still creates only a pending email invitation, does not create a person or active membership, and sends the invitation email.
     - Kept existing authorization and route-shape coverage.
   - `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off task `008` only.

3. **Validation commands run**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/member_invitation_live/new.ex test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - Direct focused test attempt:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Failed before tests because of the known sandbox `PGHOST` mismatch.
   - Focused test via required workaround:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed: `8 tests, 0 failures`.
   - Related Staff/member invitation LiveView tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_invitation_live/new_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
     - Passed: `13 tests, 0 failures`.
   - Full required check for LiveView/UI changes:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - From:
     - `- [ ] 008 Keep the Admin invitation form email-only.`
   - To:
     - `- [x] 008 Keep the Admin invitation form email-only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant accepted ADRs:
     - ADR 0002: Commanded/event sourcing by default.
     - ADR 0007: Membership owns membership lifecycle rules.
     - ADR 0013: PhoenixTest/LiveView-style web testing.
     - ADR 0015: LiveView for member application pages.
   - The change keeps invitation lifecycle work in the Membership context and uses the existing shared invitation command/application service.
   - The member-facing workflow remains a LiveView.
   - Tests cover user-visible form behavior plus LiveView submit behavior.
   - No acceptance feature files were edited for this task.