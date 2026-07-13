Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `017 Add the **Account settings** avatar-menu link and separator in Layouts.club_site/1, promoting the template's proposed .app-menu__item / .app-menu__divider classes into the app's shared CSS (kept in sync with the design-system mirror per app_shell_css_test.exs).`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`
     - Added `Account settings` link in the club-site avatar dropdown.
     - Link navigates to `/my/settings`.
     - Added horizontal separator between `Account settings` and `Sign out`.
     - Added stable IDs:
       - `#club-site-account-settings-link`
       - `#club-site-identity-menu-divider`
   - Updated shared CSS:
     - `web/assets/css/app.css`
     - `styles.css`
     - Added `.app-menu__item` and `.app-menu__divider` rules, kept mirrored for `app_shell_css_test.exs`.
   - Updated tests:
     - `web/test/memba_web/components/layouts_test.exs`
       - Verifies the Account settings menu link, separator, and ordering before Sign out.
     - `web/test/memba_web/app_shell_css_test.exs`
       - Verifies `.app-menu__item` and `.app-menu__divider` are part of the shared shell CSS contract.

3. **Validation commands run**
   - TDD/failing first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs test/memba_web/app_shell_css_test.exs`
     - Failed as expected before implementation: missing `.app-menu__item` CSS and missing Account settings link.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs test/memba_web/app_shell_css_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs test/memba_web/app_shell_css_test.exs`
     - Passed: `13 tests, 0 failures`.
   - Full final validation after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed only:
     - `- [ ] 017 Add the **Account settings** avatar-menu link...`
   - To:
     - `- [x] 017 Add the **Account settings** avatar-menu link...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015: The link targets the existing LiveView-backed member application route `/my/settings`; no controller fallback or separate settings surface was introduced.
   - ADR 0023: No client-side-only JavaScript was added. The menu itself remains transient chrome, while the settings page/tab URL-addressability remains handled by the existing LiveView route work from task 016.