1. **Selected todo line**
   - `001 Inventory the member templates/layout and their bespoke markup: web/lib/memba_web/controllers/page_html/club.html.heex, message.html.heex, the compose template, the public club page template, and Layouts.club_site (--club-site-*).`

2. **Changes made**
   - Added `docs/iterations/034-member-page-design-system-alignment/inventory.md`.
   - The inventory documents:
     - The four member/public club surfaces in scope.
     - `Layouts.club_site/1` and its `--club-site-*` white-label seam.
     - Bespoke button-like links/buttons.
     - Bespoke initials avatars.
     - Member delivery-status helper coupling and current off-palette mappings.
     - Later-task replacement targets without implementing them.

3. **Focused validation**
   - Ran `git diff --check` — passed with no whitespace/patch issues.
   - Did **not** run `dev check` because this was a docs-only inventory change, matching the project guidance not to run it for docs-only edits.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 ...`
     - to:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None. No todo tasks were split, added, deleted, or reordered.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - I checked for ADR files under `docs/adr/`; none were present.
   - The task was documentation/inventory only and did not alter architecture or behavior.