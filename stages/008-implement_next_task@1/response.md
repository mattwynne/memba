1. **Selected todo line**
   - `001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

2. **Changes made**
   - Added inspection notes:
     - `docs/iterations/029-membership-admin-invitations/staff-invitation-inspection.md`
   - The note documents:
     - Iteration 028 Staff invitation aggregate/commands/events/projection.
     - Public Membership invitation APIs and reuse points.
     - Staff invite route/form.
     - Invitation email module.
     - Acceptance/profile-completion browser journey.
     - Existing test coverage to preserve.
     - Guidance for later Membership Admin invitation tasks.
   - Updated `todo.md` to check off only the selected task.

3. **Focused validation**
   - Ran:
     - `git diff --check`
       - Result: passed, no whitespace errors.
     - `git status --short`
       - Result: expected docs-only changes present.
   - Did **not** run `dev check` because this was docs/inspection-only, matching project guidance.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`
   - To:
     - `- [x] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed `docs/adr/0007-use-separate-membership-and-messaging-commanded-contexts.md`.
   - The inspection confirms iteration 028 keeps invitation lifecycle in the Membership bounded context and uses Membership public APIs/projections, consistent with ADR 0007.
   - Also reviewed the iteration 027 role-permission model note and recorded that future Membership Admin invitation work should authorize via `club.manage_members` without making Staff implicit club members.