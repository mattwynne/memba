# Implementation TODO

- [x] 001 Add a preview element to the club-home conversation row template using `message_row.body`, clamped to one line with CSS (no server-side character truncation).
- [x] 002 Remove `conversation_entry_label/1` and its call site in `page_html.ex`.
- [x] 003 Remove the `#member-message-meta` paragraph in `message.html.heex`.
- [x] 004 Resize the conversation subject heading in `message.html.heex` to match `.page-title` scale.
- [x] 005 Remove the "Recent club messages" heading block from the Conversations panel in `club.html.heex`.
- [x] 006 Remove the "Current members" heading block (including the redundant inline "Invite member" button) from the Members panel in `club.html.heex`; confirm the tab-row "Invite member" action still covers the same permission check (`@current_member_can_manage_members?`).
- [ ] 007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.
- [ ] 008 Run `./bin/dev gallery-walk` and compare the club-home and conversation-page screenshots against `design-system/wireframes/club-home.html` and `member-conversation.html`.
- [ ] 009 Run `dev check` and confirm it is green.
