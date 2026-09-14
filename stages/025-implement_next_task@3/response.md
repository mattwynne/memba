Task 003 is implemented and ready for independent review.

1. Selected task

`- [ ] 003 Preserve trusted system-group commands rather than exposing them directly to web callers.`

2. Changes made

- Added an architectural boundary test in [membership_command_boundary_test.exs](/workspace/memba/web/test/memba_web/membership_command_boundary_test.exs:1). It scans production web-delivery modules and prevents direct references to the trusted actor-free `AddGroupMember`, `CreateGroup`, and `RemoveGroupMember` commands.
- Clarified in [add_group_member.ex](/workspace/memba/web/lib/memba/membership/commands/add_group_member.ex:8) that `AddGroupMember` remains an internal policy/backfill command and that web callers must use the actor-authorized `Membership.add_custom_group_member/2` API.
- Documented the public-versus-internal command boundary in [router.ex](/workspace/memba/web/lib/memba/membership/router.ex:8).
- Preserved the existing trusted command routing and the system-group policy/backfill implementations unchanged.
- Existing focused tests also verify that:
  - `AddGroupMember` remains registered with the Commanded application.
  - System-group policies and backfills can still dispatch it.
  - The public `Membership` API does not export `add_group_member`.
  - The public actor-authorized operation rejects system groups while trusted dispatch remains available.

3. Focused validation

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/membership_command_boundary_test.exs test/memba/membership/public_api_test.exs test/memba/membership/app_test.exs test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs test/memba/membership/system_groups_backfill_test.exs`
  - 53 tests, 0 failures.
- `mix format --check-formatted lib/memba/membership/commands/add_group_member.ex lib/memba/membership/router.ex test/memba_web/membership_command_boundary_test.exs`
  - Passed.
- `git diff --check`
  - Passed.

Full `dev check` remains explicit task 016.

4. Todo state

Still exactly unchecked:

`- [ ] 003 Preserve trusted system-group commands rather than exposing them directly to web callers.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0002: trusted system-group work remains Commanded command dispatch through the existing event-sourced aggregate.
- ADR 0007: web delivery is constrained to Membership’s public context API; internal policy and backfill producers retain their lower-level command path.
- ADR 0011: existing caller-generated typed identities and command fields are unchanged.
- ADR 0024: both trusted and actor-authorized commands continue routing to the Club consistency boundary; no projection-backed authorization path was introduced.