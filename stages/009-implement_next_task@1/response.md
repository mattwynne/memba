1. **Selected todo line**
   - `001 Read the shipped surfaces to mirror them accurately: member_invitation_live/new.ex, admin/club_member_invitations_live/, club_member_invitation_html/profile.html.heex, and auth_live/sign_in.ex; note the real fields, states, copy, and delivery-progress states.`

2. **Changes made**
   - Added `docs/iterations/036-ds-catchup-member-management-and-auth/surface-notes.md`.
   - Captured shipped-source notes for:
     - member-admin invite-a-member surface
     - staff/admin invite-a-member surface
     - invited-member profile completion
     - sign-in / check-email / auth-email progress states
   - Notes include real routes, IDs, fields, labels, button text, user-visible copy, validation/error states, and auth delivery-progress status/message mapping.
   - No app code, routes, templates, tests, or feature files changed.

3. **Focused validation**
   - `git diff --check` — passed with no whitespace errors.
   - `git status --short` — confirmed only the iteration docs/todo changes are present.
   - `dev check` was not run because this task made docs-only iteration notes; AGENTS.md says not to run `dev check` for docs-only edits unless explicitly requested.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 ...`
   - to:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan.
   - Inspected relevant accepted ADRs:
     - ADR 0006: preserved simplified member-facing delivery language and avoided provider-specific failure detail in requester-facing progress notes.
     - ADR 0015: notes reflect the existing LiveView member application surfaces rather than proposing controller/app behaviour changes.
     - ADR 0016: notes keep auth delivery progress provider-neutral and aligned with switchable provider boundaries.