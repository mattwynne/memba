Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `016 Add /my/settings LiveView under the club-member/authenticated browser surface as a global personal settings page, with /my/settings/profile, /my/settings/clubs, and /my/settings/emails sub-routes so the selected tab is URL-addressable via handle_params/3 per ADR 0023 (see Designs — do not implement tab switching as client-side-only JS).`

2. **Changes made**
   - Added `web/lib/memba_web/live/my_settings_live.ex`
     - New `MembaWeb.MySettingsLive`.
     - Mounted under the existing authenticated club-member LiveView session.
     - Resolves the selected club from the club-site LiveView session.
     - Requires the signed-in identity to resolve to a Membership Person.
     - Renders a global “Account settings” shell with Profile / Clubs / Emails tabs.
     - Uses `handle_params/3` and `@live_action` to restore the selected tab from the URL.
     - Uses `<.link patch={...}>` for tab changes; no client-side-only JS.
   - Updated `web/lib/memba_web/router.ex`
     - Added:
       - `/my/settings`
       - `/my/settings/profile`
       - `/my/settings/clubs`
       - `/my/settings/emails`
   - Added `web/test/memba_web/live/my_settings_live_test.exs`
     - Covers default `/my/settings` profile tab.
     - Covers direct tab route restore.
     - Covers LiveView patch navigation to the Emails tab.
   - Updated `web/test/memba_web/router_test.exs`
     - Covers all new settings routes through `[:browser, :club_member_required]`.
   - Updated `docs/iterations/053-my-settings-email-addresses/todo.md`
     - Checked off only task `016`.

3. **Validation commands run**
   - TDD/failing first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/my_settings_live_test.exs test/memba_web/router_test.exs`
     - Failed as expected before implementation: settings routes returned 404 / route info was `:error`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba_web/live/my_settings_live.ex lib/memba_web/router.ex test/memba_web/live/my_settings_live_test.exs test/memba_web/router_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/my_settings_live_test.exs test/memba_web/router_test.exs`
     - Passed: `19 tests, 0 failures`.
   - Full validation on the final current worktree including todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 016 Add ...`
   - To:
     - `- [x] 016 Add ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and followed ADR 0015: implemented the member application surface as a LiveView.
   - Read and followed ADR 0023: tab state is URL-addressable via explicit routes, `handle_params/3`, and `<.link patch={...}>`.
   - Did not add client-side tab-switching JavaScript.
   - Kept later UI/menu/PubSub/email-management work for the later unchecked tasks.