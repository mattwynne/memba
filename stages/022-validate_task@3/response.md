### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Live working tree is clean (`git status --short` empty; `git diff` empty).
  - Recent implementation checkpoint `d7e67b7 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `003 Add a minimal club invitation model in the Membership boundary...`
    - from `- [ ]` to `- [x]`.
  - The parent todo state showed tasks `001` and `002` checked and `003` as the first unchecked task.
  - Current `todo.md` has `001`–`003` checked and `004`–`016` still unchecked.

- Implementation artifacts found.
  - Added Membership invitation aggregate/model:
    - `web/lib/memba/membership/club_invitation.ex`
  - Added separate invitation token helper:
    - `web/lib/memba/membership/invitation_token.ex`
  - Added event-sourced commands/events for invite, resend, and accept.
  - Registered invitation commands in `Memba.Membership.Router`.
  - Added typed `:club_invitation` ID support.
  - Added projection, projector, migration, supervision, and event-sourced reset configuration for `membership_club_invitations`.
  - Added focused aggregate, token, dispatch, projection, and app wiring tests.
  - No `*.feature` files were edited in the implementation checkpoint.

- Tests run/results found.
  - Implementation summary reported focused invitation tests passing and `dev check --quick` passing.
  - I reran the focused invitation test set live:
    - `18 tests, 0 failures`.
  - Working tree remained clean after the test run.

- ADR/plan conformance notes.
  - Work implements task `003` directly and preserves later tasks (`004` onward remain unchecked).
  - Invitation lifecycle state is placed in the Membership boundary and uses Commanded/event-sourced aggregate/events/projection consistent with nearby Membership code.
  - Invitation tokens are separate from ordinary auth sign-in tokens.
  - The implementation does not create incomplete people before profile completion and leaves UI/email/callback/API orchestration for the later planned tasks.
  - No plan-required work was deleted, weakened, or silently deferred.

{"context_updates":{"task_valid":true,"task_retry_available":false}}