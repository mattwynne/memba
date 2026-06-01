# Task 001 inspection notes

## Current `GET /` club-home flow

- `MembaWeb.Router` routes `GET /` through `[:browser, :club_member_context]` to `MembaWeb.PageController.home/2`.
- `MembaWeb.UserAuth.require_active_club_member_if_club_id_present/2` preserves public access by allowing logged-out `GET /?club_id=...` through, but delegates signed-in `club_id` requests to `require_active_club_member/2`.
- `PageController.home/2` currently branches:
  - signed-in with `club_id`: calls `render_club_home/2`;
  - logged-out with known `club_id`: `live_render`s `MembaWeb.ClubMarketingLive`;
  - no `club_id`: renders the generic home / My clubs page.
- `render_club_home/2` authorizes by finding the selected club in `conn.assigns.current_identity_clubs`, then loads active members, current member, member-name lookup data, and recent messages before rendering `page_html/club.html.heex`.

## Current club-home template and selectors

- `web/lib/memba_web/controllers/page_html/club.html.heex` renders inside `<Layouts.club_site>`.
- Stable member dashboard container: `#member-club-home[data-club-id]`.
- Compose entry points are links to `/messages/new?club_id=...`:
  - `#member-compose-shortcut`;
  - `#member-send-message-link`.
- No inline compose form is present in the current template; tests assert absence of legacy `#member-message-form`, sender select, subject input, and body textarea.
- Message rows expose acceptance selectors:
  - `[data-testid="club-message-row"]`;
  - `data-message-id`;
  - `data-message-subject`;
  - `a[data-testid="club-message-link"]`.
- Active member rows expose:
  - `[data-testid="club-member-row"]`;
  - `data-member-id`;
  - `data-member-name`.

## Current tests and browser helpers that depend on club home

- `web/test/memba_web/controllers/page_controller_test.exs` covers:
  - logged-out `GET /?club_id=...` public club marketing page;
  - signed-in member club page rendering;
  - CTA links to `/messages/new?club_id=...`;
  - no inline compose form;
  - message row/link selectors;
  - active-member row selectors.
- `web/test/memba_web/router_test.exs` currently asserts member message routes and the removed legacy inline `POST /`; it does not yet assert the `GET /?club_id=...` LiveView dispatch shape.
- `web/test/memba_web/user_auth_test.exs` covers `require_active_club_member/2` for active members, non-members, missing `club_id`, and unauthenticated redirects. It does not currently have focused tests for `require_active_club_member_if_club_id_present/2`.
- Browser acceptance helpers in `acceptance-tests/features/support/member_message.js` depend on:
  - `openMemberClubHome/3` waiting for `#member-club-home[data-club-id=...]`;
  - `openMemberComposeFromClubHome/3` clicking `#member-send-message-link`;
  - send flow waiting for `[data-testid="club-message-row"][data-message-id=...]`;
  - `assertMemberSeesMessageInClub/4` waiting for `[data-testid="club-message-row"][data-message-subject=...]`.
- `acceptance-tests/test/member_message_steps.test.js` has fake-browser expectations for those same selectors and the `/?club_id=...` URL shape.

## ADR 0015 implications for later tasks

ADR 0015 is accepted and states member application pages, including the club home / member dashboard, should use LiveView by default. The current public/logged-out marketing flow may remain controller/LiveView-rendered separately because ADR 0015 allows logged-out marketing pages to remain non-member app surfaces.
