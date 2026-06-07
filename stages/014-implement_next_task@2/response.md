Implemented the next unchecked task.

1. **Selected todo line**
   - `002 Design a minimal role/permission model that supports future custom roles:`

2. **Changes made**
   - Added design artifact:
     - `docs/iterations/027-membership-administrator-role/role-permission-model.md`
   - The note defines:
     - app-defined permission primitive `club.manage_members`;
     - club-scoped role definitions;
     - role-to-permission grants;
     - membership/person role assignments;
     - write-side aggregate choice;
     - proposed event vocabulary;
     - normalized and flattened projection shape;
     - public permission-check API shape;
     - staff vs club-member authorization boundary.
   - Updated only the selected task line in:
     - `docs/iterations/027-membership-administrator-role/todo.md`

3. **Focused validation**
   - Ran:
     - `git diff --check`
     - `git diff --check -- docs/iterations/027-membership-administrator-role/todo.md && git diff --check --no-index /dev/null docs/iterations/027-membership-administrator-role/role-permission-model.md || test $? -eq 1`
     - `git status --short`
   - Results:
     - whitespace checks passed;
     - working tree contains only the intended todo update and new design doc.
   - I did **not** run `dev check` because this was a docs/prose-only design task, and repo guidance says not to run it for docs-only edits unless explicitly requested or executable examples/scripts changed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Design a minimal role/permission model that supports future custom roles:`
   - To:
     - `- [x] 002 Design a minimal role/permission model that supports future custom roles:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and applied constraints from:
     - ADR 0002: event-sourced Commanded domain behaviour by default.
     - ADR 0007: Membership owns club/person/membership lifecycle and public query API.
     - ADR 0008: persistent EventStore is the dev/test path.
     - ADR 0009: projections should use Commanded Ecto Projections.
     - ADR 0011: new aggregate identities should be caller-generated typed IDs.
     - ADR 0022: read-your-writes/projection barriers remain relevant for later executable scenarios.
   - The design keeps role/permission behaviour inside the Membership context, avoids cross-context projection access, and preserves staff authorization as separate from club-scoped role membership.