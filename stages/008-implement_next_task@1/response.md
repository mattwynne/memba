1. **Selected todo line**
   - `001 Inspect current Membership event-sourced aggregate boundaries for club creation, membership creation/removal, onboarding conversion, and test-support creation paths.`

2. **Changes made**
   - Added `docs/iterations/027-membership-administrator-role/boundary-inspection.md`.
   - The note documents:
     - current Membership Commanded aggregate/router boundaries;
     - existing commands/events for clubs, people, and memberships;
     - current projection/projector boundaries;
     - onboarding conversion orchestration points;
     - staff/admin membership-management entry points;
     - test-support and seed paths that create membership state;
     - relevant ADR constraints for later role/permission work.
   - Updated only the selected todo line in `todo.md`.

3. **Focused validation**
   - Ran:
     - `git diff --check`
   - Result: passed with no whitespace errors.
   - I did **not** run `dev check` because this was a docs/prose-only inspection artifact, and the repository guidance says not to run `dev check` for docs-only/prose-only edits unless explicitly requested or executable examples/scripts changed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current Membership event-sourced aggregate boundaries...`
   - To:
     - `- [x] 001 Inspect current Membership event-sourced aggregate boundaries...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Inspected and reflected constraints from ADRs:
     - ADR 0002: Commanded/event sourcing default.
     - ADR 0007: Membership bounded context owns clubs/people/memberships; other contexts use public query API.
     - ADR 0008: persistent PostgreSQL EventStore in dev/test.
     - ADR 0009: use Commanded Ecto projections.
     - ADR 0011: caller-generated UUID aggregate identities.
     - ADR 0022: projection barriers/read-your-writes synchronization.
   - No behaviour or architecture changes were made in this task.