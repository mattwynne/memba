Implemented task 001 and left it unchecked for independent review.

1. Selected task

`- [ ] 001 Add a public authenticated custom-group admission use case and actor-bearing command handled by Membership.Club.`

2. Changes made

- Added the actor-bearing [`AddCustomGroupMember`](/workspace/memba/web/lib/memba/membership/commands/add_custom_group_member.ex:1) command.
- Added public `Membership.add_custom_group_member/2` request translation in [`membership.ex`](/workspace/memba/web/lib/memba/membership.ex:86).
- Registered the command with the Membership router, targeting `Membership.Club`, in [`router.ex`](/workspace/memba/web/lib/memba/membership/router.ex:43).
- Added Club aggregate handling, typed identity validation, and admission event generation in [`club.ex`](/workspace/memba/web/lib/memba/membership/club.ex:139).
- Added dispatch coverage in [`add_custom_group_member_dispatch_test.exs`](/workspace/memba/web/test/memba/membership/add_custom_group_member_dispatch_test.exs:1).
- Updated command-shape, router-registration, and public API contract tests.
- No acceptance feature files were changed.

The detailed actor/target authorization rules remain task 002’s responsibility; this task establishes the authenticated actor-bearing write path and aggregate boundary.

3. Validation

- TDD red run confirmed the command was initially missing.
- Focused test run:
  `PATH="$PWD/bin:$PATH" dev test test/memba/membership/app_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/public_api_test.exs`
  — 39 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  — 1,412 tests, 0 failures.
- `git diff --check`
  — passed.
- Full `dev check` was not run because final full-suite validation remains explicit task 016 and the workflow’s final gate.

4. Todo state

Still exactly:

`- [ ] 001 Add a public authenticated custom-group admission use case and actor-bearing command handled by Membership.Club.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0002: admission is represented as a Commanded command handled by an event-sourced aggregate.
- ADR 0007: the write remains inside the Membership bounded context and public Membership API.
- ADR 0011: all identities remain caller-generated typed UUIDs.
- ADR 0024: the command routes by `club_id` and is handled by `Membership.Club`, keeping admission decisions at the authoritative Club consistency boundary.