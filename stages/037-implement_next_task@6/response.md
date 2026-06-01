Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Render compose form based on compose.jsx:`

2. **Changes made**
   - Updated `web/lib/memba_web/live/member_message_live/new.ex` to render the focused compose form:
     - Club home back link.
     - “New message” eyebrow.
     - Active-member recipient note with “There’s no list to pick…” copy.
     - Non-editable sender summary showing current member, initials, and “Sending as yourself”.
     - Subject/body Phoenix form component inputs with wireframe-aligned placeholders.
     - “Send to all members” submit button.
     - Cancel link back to club home.
   - Added helper functions for:
     - Club home path generation.
     - Active-member count summary.
     - Sender initials.
   - Updated `web/test/memba_web/live/member_message_live/new_test.exs` with a focused LiveView test for the compose form affordances.
   - Ran `mix format` on changed Elixir files.

3. **Focused validation**
   - Initial direct test attempt outside devenv failed before assertions because Postgres socket env was unavailable:
     - `cd web && MIX_ENV=test mix test test/memba_web/live/member_message_live/new_test.exs`
   - Focused compose render tests inside devenv:
     - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/live/member_message_live/new_test.exs'`
     - Result: `5 tests, 0 failures`
   - Focused compose + submit tests:
     - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs'`
     - Result: `6 tests, 0 failures`
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `237 tests, 0 failures`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 006 Render compose form based on compose.jsx:`
   - To:
     - `- [x] 006 Render compose form based on compose.jsx:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs:
     - `docs/adr/0015-use-liveview-for-member-application-pages.md`
     - `docs/adr/0013-use-phoenix-test-for-feature-style-web-tests.md`
     - `docs/adr/0001-use-phoenix-for-the-core-application.md`
   - Conforms by keeping the member compose surface as a LiveView, using Phoenix/LiveView form conventions, and adding focused LiveView tests for user-visible UI affordances.