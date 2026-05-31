### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - `/tmp/fabro-pre-validate-snapshot.md` shows the implementation checkpoint at `48888dc` with a clean working tree.
  - Live `git status --short` is clean.
  - Recent history shows `48888dc fabro(...): implement_next_task (succeeded)` followed by `d44c3a0 pre_validate_snapshot`.
  - `git show 48888dc^:docs/iterations/010-shared-magic-link-auth/todo.md` confirms task `006 Add web auth helpers/plugs...` was the first unchecked task when implementation started.
  - `git diff 48888dc^ 48888dc -- todo.md` shows exactly one ordinary task line changed from unchecked to checked: task `006`.

- Implementation artifacts found:
  - Added `web/lib/memba_web/user_auth.ex` with browser auth/session helpers:
    - fetch current identity from session,
    - normalize signed-in email,
    - derive staff status,
    - derive active clubs,
    - require authenticated identity,
    - require staff identity,
    - require active club membership for `club_id`,
    - provide matching LiveView `on_mount` hooks.
  - Updated `web/lib/memba_web/router.ex` to import `MembaWeb.UserAuth` and fetch the current identity in browser pipelines.
  - Added focused tests in `web/test/memba_web/user_auth_test.exs`.

- Tests run/results found:
  - Live validation ran `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`.
  - Result: `172 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Matches implementation plan task 006: web auth helpers/plugs fetch session identity and enforce authentication, staff, and member authorization.
  - Uses `Memba.Accounts` public APIs for identity/membership authorization, preserving context boundaries.
  - No acceptance `.feature` files or `acceptance-tests/` files were edited.
  - Scope is appropriate for an independent checkpoint; later `/auth` UI, homepage updates, and route gate application remain unchecked for subsequent tasks.

{"context_updates":{"task_valid":true,"task_retry_available":false}}