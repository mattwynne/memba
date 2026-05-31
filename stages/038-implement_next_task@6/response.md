Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 006 Add web auth helpers/plugs, likely MembaWeb.UserAuth, to:`

2. **Changes made**
   - Added `MembaWeb.UserAuth` with:
     - browser session helpers:
       - `log_in_identity/2`
       - `log_out_identity/1`
       - session key helpers
     - current identity fetching from session:
       - assigns normalized email
       - staff flag from `Memba.Accounts.staff_email?/1`
       - active clubs from `Memba.Accounts.list_active_clubs_for_email/1`
     - browser plugs:
       - `fetch_current_identity/2`
       - `require_authenticated_identity/2`
       - `require_staff_identity/2`
       - `require_active_club_member/2`
     - LiveView `on_mount/4` hooks for equivalent identity assignment/auth gates.
     - unauthenticated redirects to `/auth` with safe return path stored in session.
     - signed-in unauthorized access returns/redirects with forbidden behavior.
   - Updated `MembaWeb.Router` browser and staff browser pipelines to fetch the current identity after session fetch.
   - Added focused tests in `web/test/memba_web/user_auth_test.exs`.

3. **Validation commands run**
   - Red TDD check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba_web/user_auth_test.exs`
     - Failed as expected before implementation because `MembaWeb.UserAuth` did not exist.
   - Focused tests:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba_web/user_auth_test.exs`
     - Passed: `14 tests, 0 failures`.
   - Affected route/page tests:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba_web/user_auth_test.exs test/memba_web/router_test.exs test/memba_web/controllers/page_controller_test.exs`
     - Passed: `25 tests, 0 failures`.
   - Formatting:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted`
     - Passed.
   - Full project check:
     - `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`
     - Passed: `172 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add web auth helpers/plugs, likely MembaWeb.UserAuth, to:`
   - To:
     - `- [x] 006 Add web auth helpers/plugs, likely MembaWeb.UserAuth, to:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: auth helpers live in the Phoenix web app and use Phoenix controller/LiveView/session patterns.
   - ADR 0007: member authorization goes through `Memba.Accounts`/`Memba.Membership` public query APIs; no direct mutation or cross-context storage coupling was introduced.
   - ADR 0013: added focused Phoenix web tests using existing `ConnCase`; no acceptance feature files or acceptance-test files were changed.
   - Project rule: no new HTTP client usage; no HTTPoison/Tesla/:httpc introduced.