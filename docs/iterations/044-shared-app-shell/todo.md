# Implementation TODO

- [x] 001 Port the app-shell CSS classes (`app-frame`, `app-card`, `app-bar` and its children, `app-menu`, `app-foot`) verbatim from `design-system/` (`memba.css` / `styles.css`) into `web/assets/css/app.css`, keeping names 1:1 with the mirror (daisyUI `dropdown` already exists).
- [x] 002 In `Layouts.club_site/1` (`web/lib/memba_web/components/layouts.ex`), replace the header's left side with the app-bar showing the plain `@club_name`.
- [x] 003 In the same app-bar, add the right-side member identity dropdown (avatar initials + member name), gated with `:if={@current_identity}` so it only renders when signed in.
- [x] 004 Make the identity dropdown open to a **Sign out** control that posts to the same `DELETE /auth` form/action as today (unchanged behaviour).
- [x] 005 Wrap `@inner_block` in the `app-frame` / `app-card` frame; keep the existing "Powered by Memba" `app-foot` footer and the `flash_group`.
- [x] 006 Add an optional `member_name` assign (default `nil`) to `club_site`, and a private `Layouts.initials/1` helper that derives avatar initials from a name.
- [x] 007 Render the identity dropdown's avatar + label from `member_name`, falling back to the `current_identity` email local-part (label and initials) when `member_name` is `nil`.
- [x] 008 Pass `member_name` (current member display name) into `club_site` from `page_html/club.html.heex` and `page_html/message.html.heex`.
- [x] 009 Pass `member_name` into `club_site` from `member_message_live/new.ex` (compose) and `member_invitation_live/new.ex` (invitation).
- [x] 010 Leave `public_club_page_live.ex` passing neither `current_identity` nor `member_name`, so the signed-out public page keeps the identity dropdown gated off.
- [x] 011 Update LiveView/layout tests: app-bar renders `@club_name`; identity dropdown gated on `@current_identity`; Sign out posts to `DELETE /auth`; content sits in the app-card.
- [ ] 012 Add/adjust a test that every `club_site` surface still renders under the new shell (club home, conversation, compose, invitation, public club page).
- [ ] 013 Run `./bin/dev gallery-walk` and compare the club-home and conversation screenshots to `design-system/wireframes/club-home.html` / `member-conversation.html`.
- [ ] 014 Run `dev check` and confirm it is green (no feature-file changes).
