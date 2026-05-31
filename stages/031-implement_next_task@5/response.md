Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Update the homepage links and labels so the primary operational link points to /admin/clubs if retained, or is presented as an internal/admin link rather than a public user journey.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/home.html.heex`:
     - Homepage admin links still point to `~p"/admin/clubs"`.
     - Labels now explicitly present the link as internal/staff:
       - `Internal staff admin`
       - `Open internal staff admin`
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`:
     - Added homepage coverage asserting:
       - Main navigation includes `/admin/clubs`.
       - Homepage includes `/admin/clubs` links.
       - Internal/staff admin labels render.
       - Homepage no longer links to the old public harness path `href="/clubs"`.

3. **Validation**
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev check`
   - Result:
     - Passed: `136 tests, 0 failures`
     - Command exited successfully.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 005 Update the homepage links and labels so the primary operational link points to /admin/clubs if retained, or is presented as an internal/admin link rather than a public user journey.`
   - To:
     - `- [x] 005 Update the homepage links and labels so the primary operational link points to /admin/clubs if retained, or is presented as an internal/admin link rather than a public user journey.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 respected: change stays within Phoenix/HEEx.
   - ADR 0013 respected: added Phoenix web test coverage using existing controller-test style appropriate for rendered controller output.
   - No acceptance feature files changed.
   - No fake club routing, member route, or temporary club resolver introduced.