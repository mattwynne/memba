Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 007 Add /auth UI and callback handling:`

2. **Changes made**
   - Added `MembaWeb.AuthController` with:
     - `GET /auth` sign-in form rendering.
     - `POST /auth` magic-link request handling with neutral success flash.
     - `GET /auth/magic/:token` token consumption, session login, safe redirect handling.
     - `DELETE /auth` sign-out action.
   - Added `MembaWeb.AuthHTML` and `auth_html/new.html.heex` for the `/auth` UI.
   - Updated `MembaWeb.Router` with:
     - `GET /auth`
     - `POST /auth`
     - `GET /auth/magic/:token`
     - `DELETE /auth`
   - Added controller tests covering:
     - sign-in form rendering,
     - neutral response for known/unknown emails,
     - token creation and auth email callback URL,
     - unknown email does not create/send,
     - valid callback signs in and consumes token,
     - invalid callback does not sign in,
     - sign out clears session.
   - Checked off only task `007` in `todo.md`.

3. **Validation run**
   - TDD red check:
     - `mix test test/memba_web/controllers/auth_controller_test.exs`
     - Failed as expected before implementation with missing `/auth` routes.
   - Focused tests:
     - `mix test test/memba_web/controllers/auth_controller_test.exs`
     - Passed: `8 tests, 0 failures`.
   - Affected tests:
     - `mix test test/memba_web/controllers/auth_controller_test.exs test/memba_web/user_auth_test.exs test/memba_web/router_test.exs test/memba_web/controllers/page_controller_test.exs test/memba/accounts_test.exs test/memba/accounts/auth_email_test.exs`
     - Passed: `45 tests, 0 failures`.
   - Formatting:
     - `mix format --check-formatted`
     - Passed.
   - Full project check:
     - `dev check`
     - Passed: `180 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Add /auth UI and callback handling:`
   - To:
     - `- [x] 007 Add /auth UI and callback handling:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: implemented in Phoenix controller/template/router patterns.
   - ADR 0007: authorization/session behaviour continues to use `Memba.Accounts` APIs rather than coupling to membership storage beyond test setup.
   - ADR 0013: added Phoenix web/controller tests; no acceptance feature files were changed.
   - Project HTTP rule: no new HTTP client usage; no HTTPoison/Tesla/:httpc introduced.