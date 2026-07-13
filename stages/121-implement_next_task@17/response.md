Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `018 Build the settings UI following design-system/templates/account-settings.html (side-tab Profile/Clubs/Emails, grouped email-row list, checkmark-icon Verified badges), using existing app shell/card/form/badge patterns, with stable IDs for LiveView tests.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/my_settings_live.ex`
     - Replaced placeholder settings panels with the designed Account settings UI.
     - Added `‹ Back to club` link.
     - Converted tabs to side-tab layout while preserving URL-addressable LiveView patch navigation.
     - Added Profile panel with avatar initials and Person name.
     - Added Clubs panel with current membership chips and “Member since …” copy.
     - Added Emails panel with grouped email-address rows:
       - primary row with `Primary` + checkmark `Verified` badges and no actions;
       - verified non-primary rows with `Make primary` / `Remove` buttons;
       - pending rows with dot `Pending verification` badge and `Resend verification` / `Remove` buttons.
     - Added stable IDs for rows, badges, buttons, form, and panels.
   - Updated `web/lib/memba/membership.ex`
     - `list_person_email_addresses/1` now returns `verified_at`.
     - Added `list_active_club_memberships_for_person/1` for settings membership chips.
   - Updated `web/assets/css/app.css`
     - Added local Account settings card/list/row CSS classes matching the design reference.
   - Updated `web/test/memba_web/live/my_settings_live_test.exs`
     - Added assertions for back link, profile basics, side-tab layout, club chips, grouped email rows, verified checkmark badges, pending badges, contextual actions, and add-email form.

3. **Validation commands run**
   - TDD/failing first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/my_settings_live_test.exs`
     - Failed as expected before implementation on missing back link / side-tab UI.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/live/my_settings_live.ex lib/memba/membership.ex test/memba_web/live/my_settings_live_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/my_settings_live_test.exs test/memba_web/app_shell_css_test.exs`
     - Passed: `7 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 018 Build the settings UI...`
   - To:
     - `- [x] 018 Build the settings UI...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015: `/my/settings` remains a LiveView member application surface.
   - ADR 0023: Profile/Clubs/Emails remain URL-addressable via LiveView routes, `handle_params/3`, and `<.link patch={...}>`; no client-side-only tab switching or inline script was introduced.