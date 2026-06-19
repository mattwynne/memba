1. **Selected todo line**
   - `007 Refresh the club-home and member-messaging/read previews to the post-034 member pages.`

2. **Changes made**
   - Added `design-system/wireframes/club-home.html`
     - Self-contained daisyUI CDN + Memba theme/root tokens.
     - Mirrors `PageHTML.club/1` post-034 member dashboard:
       - Club-site shell.
       - Sage palette.
       - Hero, message CTA, inbound-email note.
       - Recent messages with receipt glance bars.
       - Active members card/avatar stack.
       - Shared-component style via daisyUI buttons/avatar primitives + plain CSS.
   - Added `design-system/wireframes/member-messaging.html`
     - Self-contained daisyUI CDN + Memba theme/root tokens.
     - Mirrors `PageHTML.message/1` / `MemberMessageLive.Show` read view:
       - Back link, message header/body/meta.
       - Delivery summary bar and legend.
       - Grouped delivery receipt sections.
       - Shared status badge treatment.
   - No app code, routes, LiveViews, templates, or `.feature` files changed.

3. **Focused validation run**
   - Static DS validation script:
     - Checked `@dsCard`, `@startingPoint`, daisyUI CDN, root theme tokens.
     - Checked no `--club-site-*`, Tailwind CDN token, `btn--`, or app/shared CSS links.
     - Checked all non-daisy class tokens are locally styled.
     - HTML parser smoke check.
     - Trailing whitespace check for new HTML files.
     - Result: passed for both new previews.
   - `git diff --check`
     - Result: passed.
   - Changed-file guard:
     - Confirmed changed paths are only the two preview files plus `todo.md`.
     - Confirmed no `.feature` files changed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: passed, `799 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 007 Refresh the club-home and member-messaging/read previews to the post-034 member pages.`
   - To:
     - `- [x] 007 Refresh the club-home and member-messaging/read previews to the post-034 member pages.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015’s LiveView member-page direction is respected by mirroring the current LiveView-backed member message surface without changing application behavior.
   - Work is static design-system preview-only and does not alter routing, LiveViews, domain logic, persistence, acceptance features, or tests.