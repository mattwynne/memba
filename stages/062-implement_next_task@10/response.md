Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Keep the Admin invitation form email-only.`

2. **Changes made**
   - Added focused LiveView test coverage in:
     - `web/test/memba_web/live/club_member_invitations_live/send_test.exs`
   - New test asserts the Membership Admin invitation form:
     - contains the email field: `invitation[email]`
     - does not contain any other `invitation[...]` input fields
     - does not contain `invitation[...]` textarea/select controls
   - No application code changes were needed; the LiveView already filters/renders the form as email-only.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Initially failed due formatting; fixed manually because files are root-owned and formatter could not write.
     - Re-run passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Hit sandbox PGHOST readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Passed: `2 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `735 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Keep the Admin invitation form email-only.`
   - To:
     - `- [x] 008 Keep the Admin invitation form email-only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR/project conformance**
   - Kept the selected task scoped to UI/form contract coverage only.
   - Followed LiveView testing guidance by asserting against stable DOM IDs/selectors via `has_element?/2`.
   - Did not alter invitation lifecycle, authorization, role assignment, acceptance flow, routing, acceptance feature files, or later task behavior.
   - No new dependencies or external HTTP clients introduced.