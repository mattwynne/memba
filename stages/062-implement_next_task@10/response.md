Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 010 Add focused tests:`

2. **Changes made**
   - Added focused callback safety tests in `web/test/memba_web/controllers/auth_controller_test.exs`:
     - expired magic-link callbacks redirect to `/auth`,
     - expired callbacks do not establish a session,
     - expired tokens remain unconsumed,
     - already-consumed magic-link callbacks redirect to `/auth`,
     - already-consumed callbacks do not establish a session.
   - Added focused member-authorization coverage in `web/test/memba_web/auth_gates_test.exs`:
     - signed-in users with only an inactive membership are forbidden from `/?club_id=...`.
   - Updated the test helper in that file to allow inactive membership setup.
   - Checked off the implemented todo line in `docs/iterations/010-shared-magic-link-auth/todo.md`.

3. **Validation commands run**
   - `cd web && mix format --check-formatted test/memba_web/controllers/auth_controller_test.exs test/memba_web/auth_gates_test.exs`
     - Passed.
   - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `192 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: a direct `mix test ...` run outside the `dev` environment failed because Postgres was not running at the expected dev socket; validation was rerun through `dev check`, which starts required services and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add focused tests:`
   - To:
     - `- [x] 010 Add focused tests:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no explicit ADRs, and no `docs/adr/` files were present.
   - Changes are test-only except for the todo check-off.
   - Acceptance feature files were not changed.
   - No HTTP client usage or architecture-affecting code was introduced.