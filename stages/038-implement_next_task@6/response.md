Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Add an invitation email module with clear club context and a one-use invitation link.`

2. **Changes made**
   - Added `web/lib/memba/membership/club_member_invitation_email.ex`
     - Builds and delivers club member invitation emails through `Memba.Mailer`.
     - Uses the existing auth email sender/config boundary via `Memba.Accounts.AuthEmailConfig`.
     - Includes clear club context in From, subject, text body, HTML body, and footer.
     - Includes the supplied one-use invitation URL in both text and HTML.
     - Avoids expiry copy, matching the iteration decision that invitation links do not expire in this slice.
     - Adds Postmark message-stream provider options and Resend tags including email kind, auth stream, club ID, and invitation ID when available.
     - Validates recipient email, club name, invitation URL, and config before Swoosh handoff.
   - Added `web/test/memba/membership/club_member_invitation_email_test.exs`
     - Covers Postmark-style delivery, Resend tags, one-use/no-expiry copy, club-context sanitization/HTML escaping, invalid inputs, and missing config.
   - Updated `docs/iterations/028-staff-member-invitations/todo.md`
     - Checked off only task `006`.

3. **Focused validation commands run**
   - Attempted preferred wrapper first:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_member_invitation_email_test.exs`
     - Result: failed before test compilation due sandbox Postgres lock/readiness issue.
   - Used `devenv shell -- ...` afterward for that specific sandbox reason:
     - `devenv shell -- bin/mix test test/memba/membership/club_member_invitation_email_test.exs`
     - Result: `5 tests, 0 failures`
   - Formatting:
     - `devenv shell -- bin/mix format --check-formatted lib/memba/membership/club_member_invitation_email.ex test/memba/membership/club_member_invitation_email_test.exs`
     - Result: passed
   - Focused adjacent email tests:
     - `devenv shell -- bin/mix test test/memba/membership/club_member_invitation_email_test.exs test/memba/accounts/auth_email_test.exs`
     - Result: `13 tests, 0 failures`
   - Broad quick validation:
     - `devenv shell -- dev check --quick`
     - Result: `693 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Result: passed

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 006 Add an invitation email module with clear club context and a one-use invitation link.`
   - To:
     - `- [x] 006 Add an invitation email module with clear club context and a one-use invitation link.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: Invitation email composition remains in the Membership boundary and does not mutate Messaging state.
   - ADR 0016: Uses `Memba.Mailer`/Swoosh provider options rather than direct provider HTTP code.
   - ADR 0002/0009/0022: No event-sourced invitation lifecycle or projection behavior was changed; this task only adds the email handoff module that later web/application flows can call after Membership creates/rotates invitation tokens.
   - ADR 0011: No aggregate identity scheme changes; optional IDs are used only as provider tags/metadata.