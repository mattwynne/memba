### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Current working tree is clean.
  - Recent implementation checkpoint `ff2f471 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `002 Inspect the existing auth sign-in token and staff onboarding flow...` from `- [ ]` to `- [x]`.
  - Prior todo state at `9ae99e7` had task `001` checked and task `002` as the first unchecked task.
  - Current `todo.md` has tasks `001` and `002` checked, with `003`–`016` still unchecked.

- Implementation artifacts found:
  - Added `docs/iterations/028-staff-member-invitations/auth-token-onboarding-inspection.md`.
  - The note documents the current ordinary sign-in token lifecycle, `auth_sign_in_tokens` semantics, `/auth/sign-in/:token` callback, browser session identity shape, Staff-only `/auth/onboard` flow, and the decision not to reuse ordinary auth tokens/routes for membership-granting invitations.
  - Repository inspection corroborates the documented behavior in:
    - `web/lib/memba/accounts.ex`
    - `web/lib/memba_web/router.ex`
    - `web/lib/memba_web/identity_auth.ex`
    - `web/lib/memba_web/live/auth_live/onboard.ex`

- Tests run/results found:
  - Implementation summary reports focused auth/onboarding tests were run in a clean devenv shell:
    - `accounts_test.exs`
    - `auth_persistence_test.exs`
    - `auth_controller_test.exs`
    - `user_auth_test.exs`
    - `auth_gates_test.exs`
    - `onboarding_conversion_test.exs`
  - Reported result: `68 tests, 0 failures`.
  - No new tests were required for this inspection/documentation-only slice.

- ADR/plan conformance notes:
  - Work stays within task `002`; no later invitation behavior was prematurely implemented.
  - The inspection decision matches the plan’s resolved decision to use separate invitation-token storage from ordinary sign-in tokens.
  - No acceptance feature files were changed in the implementation checkpoint.
  - The approach respects relevant ADR constraints: Phoenix remains the app boundary, invitation work is positioned for Membership rather than ordinary auth token overload, and future LiveView/profile-completion work is kept separate from the Staff-only onboarding route.

{"context_updates":{"task_valid":true,"task_retry_available":false}}