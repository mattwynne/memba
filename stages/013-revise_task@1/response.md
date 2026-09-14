Task 001 is revised and ready for independent review. The public admission path now performs authoritative authorization inside the Club aggregate instead of accepting any well-formed actor UUID.

1. Selected task

`- [ ] 001 Add a public authenticated custom-group admission use case and actor-bearing command handled by Membership.Club.`

2. Changes made

- Preserved the existing public API, actor-bearing command, router registration, and `GroupMemberAdded` event path.
- Updated [`Membership.Club`](/workspace/memba/web/lib/memba/membership/club.ex:142) to require, from current aggregate state:

  - An existing custom group, rejecting Everyone and Admin system groups.
  - An active actor who is either an active member of that custom group or holds `club.manage_members`.
  - An exact active target membership/person identity in the same club.

- Missing, inactive, forged, and unauthorized actors now return `{:error, :unauthorized}`.
- Missing and cross-club targets return `{:error, :member_not_active}`; mismatched membership/person tuples return `{:error, :membership_person_mismatch}`.
- Kept trusted raw `AddGroupMember` commands available for system-group policies and backfills.
- Updated API and command documentation in [`membership.ex`](/workspace/memba/web/lib/memba/membership.ex:86) and [`add_custom_group_member.ex`](/workspace/memba/web/lib/memba/membership/commands/add_custom_group_member.ex:1).
- Expanded [`add_custom_group_member_dispatch_test.exs`](/workspace/memba/web/test/memba/membership/add_custom_group_member_dispatch_test.exs:14) to cover:

  - Admission by an ordinary custom-group member.
  - Admission by an outside Admin without implicitly joining.
  - Forged, unauthorized, and departed actors.
  - Missing, mismatched, and cross-club targets.
  - System-group bypass denial.
  - Continued trusted-command access to system groups.

No acceptance feature files were changed.

3. Focused validation

- TDD red run: 6 tests, 3 expected failures demonstrating the missing actor, target, and system-group checks.
- Focused regression run:

  `PATH="$PWD/bin:$PATH" dev test test/memba/membership/add_custom_group_member_dispatch_test.exs test/memba/membership/club_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs test/memba/membership/app_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/public_api_test.exs`

  Result: 98 tests, 0 failures.

- Broad quick gate:

  `PATH="$PWD/bin:$PATH" dev check --quick`

  Result: 1,416 tests, 0 failures.

- Touched-file formatting and `git diff --check` passed.
- Full `dev check` remains explicit task 016 and was not run in this per-task node.

4. Todo state

Still exactly unchecked in [`todo.md`](/workspace/memba/docs/iterations/063-add-custom-group-members/todo.md:3):

`- [ ] 001 Add a public authenticated custom-group admission use case and actor-bearing command handled by Membership.Club.`

5. Todo changes

None. Tasks were not split, added, reordered, or checked off. The minimum authorization and system-group safeguards overlapping tasks 002–003 were necessary to make task 001 a safe authenticated public write and directly address the independent revision verdict.

6. ADR conformance

- ADR 0002: admission remains a Commanded command and event-sourced aggregate decision.
- ADR 0007: the mutation remains within Membership’s public API and bounded context.
- ADR 0011: club, group, membership, and person identities remain caller-generated typed UUIDs.
- ADR 0024: actor authority, target eligibility, system-group identity, and membership transition are all decided from serialized `Membership.Club` state without projection-backed authorization preflights.