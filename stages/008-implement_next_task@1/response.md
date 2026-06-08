1. **Selected todo line**
   - `- [ ] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

2. **Changes made**
   - Added inspection note:
     - `docs/iterations/029-membership-admin-invitations/staff-invitation-flow-inspection.md`
   - The note records:
     - iteration 028 checkpoint/commit context;
     - Staff invitation aggregate, commands, events, router, projection, and migration;
     - reusable `Memba.Membership` invitation APIs;
     - token rules;
     - Staff routes/UI;
     - email delivery module and URL shape;
     - callback/profile-completion journey;
     - existing tests and acceptance plumbing;
     - implications for iteration 029;
     - ADR conformance evidence.
   - Updated only the selected todo line in:
     - `docs/iterations/029-membership-admin-invitations/todo.md`

3. **Focused validation**
   - Ran:
     - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints and iteration 028 merge commit.
     - `git status --short` before editing — clean tree.
     - Targeted file reads/searches over iteration 028 docs, invitation domain/web/test files, acceptance feature/steps, and relevant ADRs.
     - `git diff -- docs/iterations/029-membership-admin-invitations/todo.md docs/iterations/029-membership-admin-invitations/staff-invitation-flow-inspection.md`
     - `git status --short`
     - `grep -nE '^[-] \[[ x]\]' docs/iterations/029-membership-admin-invitations/todo.md`
   - Result: changes are limited to the inspection note and the selected todo check-off.
   - Did **not** run `dev check` because this task was docs/inspection-only and made no code/config/dependency/migration/acceptance-test/app-behaviour changes, matching repo guidance.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`
   - To:
     - `- [x] 001 Inspect iteration 028's Staff invitation model, commands, acceptance journey, routes, emails, and profile-completion flow.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed and reflected relevant accepted ADRs in the inspection note:
     - ADR 0002 / 0007: Commanded Membership context.
     - ADR 0009: Commanded Ecto projections.
     - ADR 0010: shared feature files with Elixir Cucumber.
     - ADR 0011: caller-generated UUID aggregate identities.
     - ADR 0013: PhoenixTest-style web coverage.
     - ADR 0016: Swoosh/Mailer email boundary.
     - ADR 0022: strong consistency/read-your-writes implications.