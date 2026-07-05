Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 In the same app-bar, add the right-side member identity dropdown (avatar initials + member name), gated with :if={@current_identity} so it only renders when signed in.`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`:
     - Added a signed-in-only app-bar identity dropdown trigger using:
       - `.dropdown.dropdown-end.app-bar__id`
       - `#club-site-identity-menu-button.app-bar__me`
       - `.app-bar__avatar`
       - `.app-bar__who`
     - Kept existing sign-out form/action untouched for the next task.
     - Added private helper functions to derive the current identity label and avatar initials from `current_identity.email`.
   - Updated `web/test/memba_web/components/layouts_test.exs`:
     - Added assertions that the signed-in club-site layout renders the identity dropdown/avatar/label.
     - Added a signed-out layout test proving the dropdown is gated off when `current_identity` is absent.

3. **Validation run**
   - TDD focused test before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Failed as expected on missing `.dropdown.dropdown-end.app-bar__id`.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Full validation after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `85 scenarios (85 passed)` / `523 steps (523 passed)`.

4. **Todo check-off**
   - Changed exactly:
     - From: `- [ ] 003 In the same app-bar, add the right-side member identity dropdown ...`
     - To: `- [x] 003 In the same app-bar, add the right-side member identity dropdown ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 respected: change stays within Phoenix layout/test code.
   - ADR 0015 respected: continues moving member-facing club pages toward a shared LiveView/application shell without changing routing or business behavior.