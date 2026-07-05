Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Pass member_name (current member display name) into club_site from page_html/club.html.heex and page_html/message.html.heex.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Passes `member_name={@current_member && @current_member.name}` into `<Layouts.club_site>`.
   - Updated `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Passes `member_name={@current_member && @current_member.name}` into `<Layouts.club_site>`.
   - Updated focused LiveView tests:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Tests now assert the shell identity label/avatar show `Alice Adams` / `AA`.
   - Updated browser/smoke support expectations to use known member display names with email-local-part fallback:
     - `acceptance-tests/features/support/authentication.js`
     - `acceptance-tests/features/support/club_member_invitations.js`
     - `acceptance-tests/features/support/request_account.js`
     - `smoke-tests/lib/browser.js`
   - No `.feature` files changed.

3. **Validation commands run and results**
   - TDD red:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected before template changes: shell identity still showed fallback instead of member name.
   - Focused pass:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `28 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/club.html.heex lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Acceptance after support update:
     - `PATH="$PWD/bin:$PATH" dev acceptance --format summary`
     - Passed: `85 scenarios (85 passed), 523 steps (523 passed)`.
   - Final full check on exact final working tree after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Pass member_name (current member display name) into club_site from page_html/club.html.heex and page_html/message.html.heex.`
   - To:
     - `- [x] 008 Pass member_name (current member display name) into club_site from page_html/club.html.heex and page_html/message.html.heex.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - No `docs/adr/*.md` files are present.
   - Changes stay within task 008: only the club home and message detail `PageHTML` templates now pass current member display names into the already-implemented shared shell.