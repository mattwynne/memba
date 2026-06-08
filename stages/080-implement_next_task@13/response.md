Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Add browser/LiveView/controller tests for the Staff invite page, invitation email link, profile completion page, and final redirect to the club.`

2. **Changes made**
   - Updated `web/test/memba_web/live/admin/club_member_invitations_live/new_test.exs`.
   - Added a feature-style PhoenixTest browser flow that:
     - signs in Staff;
     - opens the club-scoped invitation page;
     - submits an email-only invite;
     - captures the delivered invitation email link;
     - opens the invitation link as a new invitee browser session;
     - verifies the profile completion page/form;
     - submits the invitee’s name;
     - verifies redirect/landing on the member club home;
     - asserts the person and active club membership were created.
   - Added small local test helpers for extracting the delivered invitation path and starting a fresh PhoenixTest browser connection.
   - Checked off only todo `013`.

3. **Validation run**
   - Initial direct focused test hit the known sandbox PGHOST mismatch:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
   - Re-ran focused tests inside `devenv shell`:
     - `devenv shell -- bin/mix test test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba_web/controllers/club_member_invitation_controller_test.exs`
     - Passed: `13 tests, 0 failures`
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
     - Passed
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `714 tests, 0 failures`
   - Full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `714 tests, 0 failures`
       - Acceptance: `62 scenarios, 421 steps passed`
   - Whitespace:
     - `git diff --check`
     - Passed

4. **Todo check-off**
   - Changed:
     - `- [ ] 013 Add browser/LiveView/controller tests...`
   - To:
     - `- [x] 013 Add browser/LiveView/controller tests...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0013: Used PhoenixTest feature-style web coverage for user-visible behaviour across LiveView/controller/static transitions.
   - ADR 0001/0015: Stayed within Phoenix/LiveView web test conventions for Staff and member-facing app surfaces.
   - ADR 0002/0007/0009: Did not bypass domain/application flow; assertions use Membership public APIs/read models.
   - ADR 0021/0022: No sleeps/polling added; test follows existing strongly consistent invitation path and asserts projected outcomes after browser actions.