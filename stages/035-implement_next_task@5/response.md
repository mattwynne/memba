1. **Selected todo line**
   - `005 Render each role as a member-row__role badge badge-primary badge-soft badge in web/lib/memba_web/controllers/page_html/club.html.heex.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`.
   - Added role rendering inside each member row:
     - Only renders when `member.roles != []`.
     - Renders one `<span>` per role.
     - Each role uses exactly:
       - `member-row__role badge badge-primary badge-soft`
   - Kept the HEEx template using presentation data only; no projection queries were added.
   - Did not modify acceptance feature files or later-task test plumbing.

3. **Focused validation commands run and results**
   - `cd web && mix format lib/memba_web/controllers/page_html/club.html.heex`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Full project validation completed successfully, including acceptance tests shown as `85 scenarios (85 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Render each role as a member-row__role badge badge-primary badge-soft badge in web/lib/memba_web/controllers/page_html/club.html.heex.`
   - To:
     - `- [x] 005 Render each role as a member-row__role badge badge-primary badge-soft badge in web/lib/memba_web/controllers/page_html/club.html.heex.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - I checked the relevant local Phoenix/HEEx and frontend guidance.
   - The change preserves the plan’s separation: role data continues to flow through presentation assigns, and the HEEx template does not query projections directly.