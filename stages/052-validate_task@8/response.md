### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found**
  - Live working tree is clean; `/tmp/fabro-pre-validate-snapshot.md` records clean status at checkpoint time.
  - Recent implement checkpoint `1f256d8` changed exactly one ordinary todo line:
    - `- [ ] 008 Add authorization handling to membership-management operations...`
    - to `- [x] 008 Add authorization handling to membership-management operations...`
  - `git show 1f256d8^:.../todo.md` confirms task `008` was the first unchecked task before the implementation checkpoint.
  - No todo deletion, weakening, split, or reorder was found.

- **Implementation artifacts found**
  - `web/lib/memba/membership.ex`
    - Added `assign_member_role_as_club_member/2`.
    - Added `remove_member_role_as_club_member/2`.
    - Both require `actor_person_id`, authorize via `club.manage_members`, ensure the target membership is active, and then dispatch role assignment/removal commands.
    - Existing staff/system-oriented membership paths remain separate.
  - `web/lib/memba/membership/authorization.ex`
    - Added `authorize_manage_members/2` using the existing projected permission query path.
  - `web/test/memba/membership/member_role_authorization_test.exs`
    - Added focused tests for authorized/unauthorized club-member role assignment and removal, plus active target membership validation.
  - No acceptance `*.feature` files were changed in the implement checkpoint or cumulative task diff.

- **Tests run/results found**
  - Validator reran focused tests successfully:
    - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs test/memba/membership/authorization_test.exs test/memba/membership/public_api_test.exs'`
    - Result: `16 tests, 0 failures`.
  - `git diff --check 1f256d8^ 1f256d8` passed.
  - Implementation summary also reports formatting passed and `dev check --quick` passed with `651 tests, 0 failures`.

- **ADR/plan conformance notes**
  - Matches implementation plan task `008`: club-member role assignment/removal APIs now rely on the permission model while staff/system paths remain separate.
  - Uses projected permission state and Membership public/application-service boundaries rather than direct role-name checks.
  - Preserves event-sourced command flow by authorizing before dispatching existing role assignment/removal commands.
  - Scope is independently useful and leaves later planned work (`009`–`011`, Membership Administrator-specific grant/revoke and last-admin invariant) unchecked.

{"context_updates":{"task_valid":true,"task_retry_available":false}}