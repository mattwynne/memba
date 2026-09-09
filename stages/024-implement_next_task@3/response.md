Implemented and checked off task 003.

1. Selected task

   `003 Write cutover-check.md with exact one-time read-only production checks for source-fact compatibility and populated clubs without an active Admin, including pre/post-deploy expectations and stop instructions.`

2. Changes made

   Added [cutover-check.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/cutover-check.md:1), containing:

   - An exact Fly/Postgres connection command.
   - An explicitly read-only, repeatable-read transaction.
   - EventStore schema and database identity preflight checks.
   - A source-fact compatibility query that respects native membership lifecycle precedence and historical deterministic-Everyone facts.
   - A populated-club query requiring an active deterministic Admin assignment to an active member, backed by the latest matching Club-stream role fact.
   - Deterministic Group and Role ID derivation matching `Memba.ID.deterministic/2`.
   - Expected zero-violation output, incomplete-state interpretation, pre/post-deployment procedure, and explicit stop/rollback guidance.
   - No automatic repair, projection mutation, event rewriting, or permanent release gate.

3. Validation

   - Extracted and executed the documented SQL against the real local EventStore/read-model schema:
     - Transaction reported `transaction_read_only = on`.
     - EventStore `data` and `metadata` reported `bytea`.
     - Both checks returned `violation_count = 0`, `violations = []`.
   - Exercised rollback-only complete fixtures: both checks returned zero violations.
   - Exercised missing-fact and latest-removal fixtures: both checks correctly returned one detailed violation.
   - Verified SQL-derived deterministic IDs against the application:
     - `grp_d00686bd-4227-e1f5-f95b-43c4ad689e70`
     - `rol_c3f48672-57d6-c82d-5fee-ed3751e805ac`
   - `git diff --check` and the untracked-file whitespace check passed.
   - `dev check` was not run because this is a docs-only task, as required by project guidance.

4. Todo check-off

   Changed only task 003 from unchecked to checked in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:5).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 004 remains the first unchecked task.

6. ADR conformance

   - ADR 0002/0009: compares current projections with authoritative event history without introducing a write path.
   - ADR 0007: the audit remains within Membership context data.
   - ADR 0008: reads the dedicated PostgreSQL `event_store` schema without modifying immutable history.
   - ADR 0011: reproduces the application’s typed deterministic Group and Role IDs exactly.
   - ADR 0014: uses the documented Fly production database.
   - ADR 0017: explicitly verifies and records live production release state before and after cutover.