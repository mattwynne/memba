1. **Selected todo line**
   - `010 Leave public_club_page_live.ex passing neither current_identity nor member_name, so the signed-out public page keeps the identity dropdown gated off.`

2. **Changes made**
   - Left `web/lib/memba_web/live/public_club_page_live.ex` unchanged; it already calls:
     - `<Layouts.club_site flash={@flash} club_name={@club.name}>`
     - with neither `current_identity` nor `member_name`.
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`:
     - Public club subdomain test now asserts the app-bar club name renders.
     - Public club subdomain test now refutes identity dropdown/sign-out elements.
     - Signed-in non-member public-page test now also refutes identity dropdown/sign-out elements, proving the public page stays signed-out-shell even when a session identity exists.

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/page_controller_test.exs`
     - Passed: `40 tests, 0 failures`
   - `cd web && mix format --check-formatted test/memba_web/controllers/page_controller_test.exs`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `912 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Leave public_club_page_live.ex passing neither current_identity nor member_name, so the signed-out public page keeps the identity dropdown gated off.`
   - To:
     - `- [x] 010 Leave public_club_page_live.ex passing neither current_identity nor member_name, so the signed-out public page keeps the identity dropdown gated off.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - Change stays within the approved plan scope: public club page remains signed-out chrome with no identity dropdown and no sign-out control.
   - No acceptance `.feature` files were changed.