Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Inspect the existing auth sign-in token and staff onboarding flow to decide how to reuse or extend it for invitation acceptance without mixing ordinary short-lived sign-in links with membership-granting invitation links.`

2. **Changes made**
   - Added inspection/design note:
     - `docs/iterations/028-staff-member-invitations/auth-token-onboarding-inspection.md`
   - Documented:
     - Existing ordinary sign-in token lifecycle and `auth_sign_in_tokens` persistence.
     - Current `/auth/sign-in/:token` callback behavior.
     - Current browser session identity shape via `IdentityAuth.log_in_identity/2`.
     - Current Staff-only `/auth/onboard` flow.
     - Decision **not** to reuse ordinary auth tokens/routes for invitations.
     - Reuse points for later invitation work: email normalization, session login helper, safe return/club URL conventions, and profile-completion shape.
     - Adjacent auth/onboarding tests future tasks should preserve.

3. **Focused validation**
   - First attempted direct focused tests:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts_test.exs test/memba/auth_persistence_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/user_auth_test.exs test/memba_web/auth_gates_test.exs test/memba/onboarding_conversion_test.exs`
     - Result: failed before tests due stale inherited `PGHOST=/tmp/devenv/postgres` socket mismatch.
   - Re-ran in a clean devenv shell:
     - `env -u DEVENV_DOTFILE -u DEVENV_PROFILE -u DEVENV_ROOT -u DEVENV_STATE -u DEVENV_TASKS -u DEVENV_TASK_FILE -u PGDATA -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/accounts_test.exs test/memba/auth_persistence_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/user_auth_test.exs test/memba_web/auth_gates_test.exs test/memba/onboarding_conversion_test.exs`
     - Result: passed — `68 tests, 0 failures`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 002 Inspect the existing auth sign-in token and staff onboarding flow...`
   - To:
     - `- [x] 002 Inspect the existing auth sign-in token and staff onboarding flow...`

5. **Todo splits/additions/reordering**
   - No todo splits, additions, deletions, or reordering.
   - Only task `002` was checked off.

6. **ADR conformance evidence**
   - Read relevant ADRs:
     - ADR 0001: Phoenix core application.
     - ADR 0002: Commanded/event sourcing by default.
     - ADR 0007: separate Membership and Messaging bounded contexts.
     - ADR 0015: LiveView default for app surfaces.
     - ADR 0022: projection barriers/read-your-writes.
   - The inspection decision keeps invitation state in the Membership invitation flow, preserves ordinary Phoenix auth behavior, avoids mixing auth-only token semantics with membership-granting invitation semantics, and does not change acceptance feature files or app behavior in this task.