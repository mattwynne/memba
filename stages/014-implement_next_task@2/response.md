1. **Selected todo line**
   - `002 Introduce a member message detail LiveView, for example MembaWeb.MemberMessageLive.Show, using Phoenix 1.8 routing conventions and avoiding duplicate scope aliases.`

2. **Changes made**
   - Added `web/lib/memba_web/live/member_message_live/show.ex`
     - Introduces `MembaWeb.MemberMessageLive.Show`.
     - Uses `MembaWeb, :live_view`.
     - Renders a minimal club-site LiveView shell at `#member-message-detail`.
     - Documents that the existing `scope "/", MembaWeb` should later route to `MemberMessageLive.Show` to avoid duplicate `MembaWeb` aliasing.
   - Added `web/test/memba_web/live/member_message_live/show_test.exs`
     - Uses `Phoenix.LiveViewTest.live_isolated/3`.
     - Verifies the LiveView renders inside the club-site layout.
     - Verifies the member message detail root element exists.

3. **Validation commands run**
   - Initial focused attempt:
     - `cd web && MIX_ENV=test mix test test/memba_web/live/member_message_live/show_test.exs`
     - Failed because Postgres was not running outside the dev shell.
   - Required full check after implementation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `218 tests, 0 failures`.
   - Focused retry inside dev shell with temporary Postgres:
     - `MIX_ENV=test mix test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `1 test, 0 failures`.
   - Final required check after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `218 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Introduce a member message detail LiveView...`
   - To:
     - `- [x] 002 Introduce a member message detail LiveView...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0006: this task only introduces the LiveView shell and does not expose or alter member-facing/operator receipt status details.
   - ADR 0013: added focused LiveView test coverage using Phoenix LiveView testing for the new member application surface.
   - ADR 0015: follows the accepted direction to use LiveView for member application pages, specifically message detail and receipt views.
   - No acceptance feature files were changed.