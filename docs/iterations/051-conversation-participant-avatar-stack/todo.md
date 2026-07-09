# Implementation TODO

- [ ] 001 Add a participants query (likely alongside `reply_counts_query`/`latest_replies_query` in `Messaging.conversations_for_club_query/1`): distinct `sender_id` per `conversation_id` across replies only (excluding the root sender), ordered by first reply time.
- [ ] 002 Thread participant data through `MemberDashboardPresentation.present_message_rows/2`, capping to the first 3 and computing the distinct-additional-participant count for the overflow badge.
- [ ] 003 Port the row-relevant `.conversation`/`.conversation__*`/`.avatar-stack` classes into `app.css` (mirroring `memba.css`'s definitions for those classes).
- [ ] 004 Rewrite the club-home conversation row in `club.html.heex` to use the ported classes, rendering the avatar-stack via the existing `<.avatar>` component for each participant plus an overflow badge.
- [ ] 005 Add/update acceptance and unit test coverage for participant ordering, the overflow count, and the no-replies-yet case.
- [ ] 006 Run `./bin/dev gallery-walk` and compare against `design-system/wireframes/club-home.html`.
- [ ] 007 Run `dev check` and confirm it is green.
