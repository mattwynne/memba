Implemented task 001 and left it unchecked for independent review.

1. Selected todo line

   `- [ ] 001 Add a thin authenticated Membership use case and actor-bearing custom-creation command, handled by the existing Club aggregate.`

2. Changes made

   - Added the public `Membership.create_custom_group/2` application-service entry point in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:61).
   - Added the required actor-bearing `CreateCustomGroup` command in [create_custom_group.ex](/workspace/memba/web/lib/memba/membership/commands/create_custom_group.ex:1).
   - Routed the command by `club_id` to the existing Club aggregate in [router.ex](/workspace/memba/web/lib/memba/membership/router.ex:48).
   - Added the initial Club command handler and custom-group decision in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:109).
   - Added focused command/use-case coverage in [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:1), including required and correctly typed actor identity.
   - Updated command-registration and public-API contract tests.
   - Kept authorization, same-club checks, name uniqueness, slug allocation, retry behavior, and atomic creator membership for their later unchecked tasks.

3. Validation

   - TDD red run failed as expected because `CreateCustomGroup` did not yet exist.
   - Focused Membership tests: 87 tests, 0 failures.
   - Final custom-group focused test: 2 tests, 0 failures.
   - `mix format --check-formatted` passed for all touched files.
   - `PATH="$PWD/bin:$PATH" dev check --quick`: 1,294 tests, 0 failures.
   - `git diff --check`: passed.

4. Todo state

   The exact selected line remains unchanged and unchecked:

   `- [ ] 001 Add a thin authenticated Membership use case and actor-bearing custom-creation command, handled by the existing Club aggregate.`

5. Todo changes

   No splits, additions, reordering, or checkbox changes were made.

6. ADR conformance

   - ADR 0002: the use case is represented by a command, Club aggregate decision, and existing domain event.
   - ADR 0007: the capability remains inside the Membership bounded context and public Membership API.
   - ADR 0011: the group uses a caller-generated typed identity.
   - ADR 0024: `CreateCustomGroup` routes by `club_id`, keeping authoritative creation decisions within the Club consistency boundary.
   - No projection-backed decision or direct read-model mutation was introduced.