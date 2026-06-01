# Implementation TODO

- [x] 001 Inspect the current member message route, controller template, auth plugs, and existing route/feature tests around `PageController.show_message/2`.
- [x] 002 Introduce a member message detail LiveView, for example `MembaWeb.MemberMessageLive.Show`, using Phoenix 1.8 routing conventions and avoiding duplicate scope aliases.
- [x] 003 Route `GET /messages/:message_id` through the existing `:browser` and `:club_member_required` pipelines to the LiveView while preserving the same URL shape and `club_id` query parameter.
- [x] 004 Move the existing message detail loading and authorization logic into a clear LiveView mount path or supporting context/helper:
- [x] 005 Build a receipt presentation model for the LiveView:
- [x] 006 Render the polished message detail page with `<Layouts.club_site>` and Phoenix/Tailwind styling inspired by `receipts.jsx`.
- [x] 007 Add LiveView state for collapsed groups:
- [x] 008 Preserve the existing stable DOM/test attributes for recipient rows.
- [x] 009 Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.
- [x] 010 Add focused LiveView/ConnCase tests covering:
- [x] 011 Run the existing member-message browser Cucumber scenarios and `dev check`.
