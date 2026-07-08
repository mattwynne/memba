Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Run ./bin/dev gallery-walk and compare the Members tab to design-system/wireframes/club-home.html.`

2. **Changes made**
   - No code/config/test changes.
   - Checked off only task 009 in:
     - `docs/iterations/049-member-role-badges/todo.md`

3. **Validation / comparison**
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev gallery-walk`
   - Result:
     - Passed / exit code 0.
     - Captured `47` gallery screenshots.
     - Wrote:
       - `tmp/gallery/gallery.html`
       - `tmp/gallery/manifest.json`
       - `tmp/gallery/app__member-club-home__desktop.png`
       - `tmp/gallery/app__member-club-home__mobile.png`
   - Compared Members-tab role badge structure against `design-system/wireframes/club-home.html`:
     - Wireframe uses `member-row` rows and role badges such as `member-row__role badge badge-primary badge-soft`.
     - App template renders member rows with `class="member-row"` and role badges with `class="member-row__role badge badge-primary badge-soft"`.
     - Members without roles render no role badge container.
   - I also attempted a supplemental rendered DOM extraction, but the sandbox’s managed-process cleanup path lacks `awk`/`ps`; that attempt was not used as validation. Its generated `core` artifact was removed, and the final ordinary repo diff is only the todo check-off.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Run ./bin/dev gallery-walk and compare the Members tab to design-system/wireframes/club-home.html.`
   - To:
     - `- [x] 009 Run ./bin/dev gallery-walk and compare the Members tab to design-system/wireframes/club-home.html.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs.
   - This task was visual validation only and made no architecture/code changes, so no ADR constraints were implicated.