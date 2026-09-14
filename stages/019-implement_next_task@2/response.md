Task 002 is implemented and ready for independent review.

1. Selected task

`- [ ] 002 Evaluate actor active club membership, actor group membership or existing admin permission, target active membership and custom-group identity against current aggregate state.`

2. Changes made

The accepted task-001 checkpoint already contained the required production logic in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:142). This task added direct aggregate-level regression coverage in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:1212), proving that `Membership.Club`:

- Authorizes an active custom-group member, then rejects them after their group membership is removed.
- Authorizes an active member through any role carrying `club.manage_members`, then rejects them after club departure or role removal.
- Rejects inactive targets and mismatched membership/person identities.
- Rejects unknown groups and both deterministic system groups.
- Makes these decisions entirely from current event-applied aggregate state.

No production behavior, acceptance feature files, or unrelated files were changed.

3. Validation

- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/add_custom_group_member_dispatch_test.exs`
  - 59 tests, 0 failures.
- `mix format test/memba/membership/club_test.exs --check-formatted`
  - Passed.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,419 tests, 0 failures.
- `git diff --check`
  - Passed.

The project’s `dev` wrapper has no `format` subcommand, so the formatting check was run directly through Mix. Full `dev check` remains explicit task 016.

4. Todo state

Still exactly unchecked:

`- [ ] 002 Evaluate actor active club membership, actor group membership or existing admin permission, target active membership and custom-group identity against current aggregate state.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0002: authorization remains a Commanded aggregate decision based on event-sourced state.
- ADR 0007: the behavior remains wholly within the Membership bounded context.
- ADR 0011: club, group, membership, role, and person identities remain caller-generated typed UUIDs.
- ADR 0024: actor authority, target eligibility, and group identity are evaluated atomically inside the club-scoped aggregate, without projection-backed authorization preflights.