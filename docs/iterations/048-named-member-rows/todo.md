# Implementation TODO

- [ ] 001 In the Members `section-panel` of `web/lib/memba_web/controllers/page_html/club.html.heex` (added in 045), replace the avatar-stack card with a `member-list` container.
- [ ] 002 Render each of `@members` as a `member-row`: avatar initials + the member's name.
- [ ] 003 Add a meta line per row and mark the **current member** with a "You" indicator.
- [ ] 004 Preserve the existing members **empty state** and the **Invite member** action from 045.
- [ ] 005 Port the `member-list` and `member-row` CSS (and its children) from `design-system/` (`memba.css` / `styles.css`) into `web/assets/css/app.css`, names 1:1 with the mirror.
- [ ] 006 Update the LiveView/controller test: members render as named rows; the current member's row is marked "You"; the Invite action and empty state still behave as before.
- [ ] 007 Run `./bin/dev gallery-walk` and compare the Members tab to `club-home.html` (named rows).
- [ ] 008 Run `dev check` and confirm it is green (no feature-file changes).
