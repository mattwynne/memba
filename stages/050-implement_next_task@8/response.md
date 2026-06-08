Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`

2. **Changes made**
   - Added `MembaWeb.ClubMemberInvitationSender` as a shared web-facing sender for club member invitations.
     - Both Staff and Membership Admin flows now go through `Membership.invite_club_member/2`.
     - Email delivery uses the same `ClubMemberInvitationEmail` and same `/invitations/club-members/:token` callback link.
   - Updated Staff invitation LiveView to use the shared sender instead of duplicating invite/resend/email URL logic.
   - Updated member-facing invitation LiveView to include an email-only submit form and send Membership Admin invitations through the shared sender.
   - Added focused Membership Admin send coverage in:
     - `web/test/memba_web/live/club_member_invitations_live/send_test.exs`
     - Verifies pending invitation creation, no person/member creation before acceptance, email delivery, and token lookup via the shared invitation lifecycle.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format ...` — passed after fixing file ownership from tool-created files.
   - `PATH="$PWD/bin:$PATH" bin/mix test ...` — failed before tests due known sandbox `PGHOST` readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/club_member_invitations_live/send_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs` — passed, `11 tests, 0 failures`.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, including `69 scenarios (69 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`
   - To:
     - `- [x] 006 Reuse the iteration 028 invitation command/application service where possible so Staff and Membership Admin invitations share duplicate-active-member, duplicate-pending-invitation, email, one-use-link, acceptance, and profile-completion rules.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 / 0015: member-facing invitation remains Phoenix LiveView-based.
   - ADR 0002 / 0011: invitation creation continues through Commanded application services with caller-generated invitation IDs in `Membership.invite_club_member/2`.
   - ADR 0007: Membership-owned invitation lifecycle stays in the Membership context; web layer only orchestrates form submission and email delivery.
   - ADR 0009 / 0022: projected invitation/read-model behaviour remains exercised through existing Membership projection-backed APIs.
   - ADR 0016: email delivery continues through the existing Swoosh/Mailer boundary; no new HTTP client/provider code introduced.