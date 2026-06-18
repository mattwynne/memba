# Implementation TODO

- [x] 001 Inventory the member templates/layout and their bespoke markup: `web/lib/memba_web/controllers/page_html/club.html.heex`, `message.html.heex`, the compose template, the public club page template, and `Layouts.club_site` (`--club-site-*`).
- [x] 002 Remove the `--club-site-*` layer: replace its variables/classes with sage tokens + daisyUI classes; simplify or retire the white-label parts of `Layouts.club_site` while keeping the member page chrome (header/footer) working in sage.
- [x] 003 Replace member-page buttons with `<.button>`, mapping each to the right variant/size; preserve `href`/`navigate`/form behaviour.
- [x] 004 Replace member initials avatars with `<.avatar>`, including the club-home stack and "+N".
- [x] 005 Re-map the member delivery-status colours to sage/warning/error in the member presentation/helper used by the receipt mini-bars and the message-read breakdown card (e.g. the member `status_bg_class`/`MemberEmailDeliveryPresentation` path), without touching the staff delivery path. Apply `status_badge` where a pill is the right element.
- [ ] 006 Sweep the four member pages for any remaining hardcoded hex; replace with tokens/daisyUI classes.
- [ ] 007 Add/update component, LiveView, and template tests for button/avatar/status usage and the member delivery-colour mapping; keep existing member tests green.
- [ ] 008 Run `./bin/dev gallery-walk` and review the member screenshots (desktop + mobile) for visual correctness.
- [ ] 009 Run `dev check`.
