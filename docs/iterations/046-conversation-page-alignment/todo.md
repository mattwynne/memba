# Implementation TODO

- [x] 001 Add a private `format_message_time/1` helper (near `conversation_entry_card` in `web/lib/memba_web/controllers/page_html.ex`) that formats a `%DateTime{}` like the design ("3 Jun, 7:02am").
- [x] 002 In `conversation_entry_card` (`page_html.ex`), render `@entry.message.inserted_at` via that helper in the card head, beside the sender name — a timestamp on the original and every reply.
- [x] 003 Port the follow-toggle CSS (`follow-toggle` and its children) and the `detail-head` title row from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
- [x] 004 In `message.html.heex`, wrap the subject `<h1>` and the follow control in a `detail-head` row so the follow control sits compactly beside the title.
- [x] 005 Replace the `#member-conversation-follow-control` card + Follow/Stop buttons with a compact follow **toggle** (checkbox/switch) that reads as following/not-following from `@following_conversation`.
- [x] 006 Wire the toggle to the existing `follow_conversation` / `unfollow_conversation` events (fire the matching event from the toggle's change), unchanged server-side.
- [x] 007 Preserve the non-member state: when `!@can_follow_conversation`, show the existing "Only current club members can follow…" explanation instead of an interactive toggle.
- [x] 008 Move the `#member-message-reply-composer` block to render **after** `#member-conversation-replies` (composer below the replies), keeping "Replying as {name}" and the posted / validation-error states.
- [x] 009 Apply the boxed message-card treatment to the original and reply cards in `conversation_entry_card` so they match the design (`message` / `message--original`).
- [ ] 010 Update `MemberMessageDetailLive` tests: follow toggle reflects and changes following state via the existing events; the composer renders after the replies; original + replies show a timestamp.
- [ ] 011 Run `./bin/dev gallery-walk` and compare the conversation screenshot to `design-system/wireframes/member-conversation.html`.
- [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
