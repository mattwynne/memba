1. **Selected todo line**
   - `001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

2. **Changes made**
   - Added durable inspection notes:
     - `docs/iterations/029-membership-admin-invitations/staff-invitation-foundation-inspection.md`
   - Documented iteration 028 Staff invitation foundation:
     - `ClubInvitation` aggregate, commands, events, projection, migration constraints.
     - Public Membership invitation APIs to reuse.
     - Invitation token/email behaviour.
     - Staff routes/form and decommissioned direct active-member creation.
     - Callback/profile-completion flow.
     - Relevant test and acceptance coverage.
     - Implications for iteration 029 Membership Admin invitations.
   - Updated only the selected todo line in:
     - `docs/iterations/029-membership-admin-invitations/todo.md`

3. **Focused validation run**
   - `git diff --check`
     - Passed with no whitespace errors.
   - `git status --short`
     - Confirmed only selected-task doc/todo changes:
       - `M docs/iterations/029-membership-admin-invitations/todo.md`
       - `?? docs/iterations/029-membership-admin-invitations/staff-invitation-foundation-inspection.md`
   - Did **not** run `dev check` because this was an inspection/docs-only task and project guidance says not to run it for docs-only edits unless requested.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`
   - To:
     - `- [x] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - Reviewed relevant accepted ADRs:
     - ADR 0002: Commanded/event sourcing by default.
     - ADR 0003: Cucumber at domain and application layers.
     - ADR 0007: separate Membership and Messaging Commanded contexts.
     - ADR 0009: Commanded Ecto projections.
     - ADR 0010: shared feature files with Elixir Cucumber.
   - Inspection confirms iteration 028 foundation conforms: invitation lifecycle is in the Membership Commanded context, uses an event-sourced aggregate with Ecto projections, and is covered by shared feature files plus Elixir/JS step definitions.