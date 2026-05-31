# Implementation TODO

- [x] 001 Inspect the post-iteration-009 route structure and admin pipeline.
- [ ] 001a Reconcile the missing post-iteration-009 admin route structure before auth gates: move the existing harness LiveViews under `/admin/*`, introduce a `:staff_browser` seam, update links/tests, and preserve `POST /webhooks/postmark`.
- [ ] 002 Add persistence for authentication:
- [ ] 003 Add an authentication context, likely `Memba.Accounts` or `Memba.Identity`, with functions to:
- [ ] 004 Extend `Memba.Membership` query API as needed:
- [ ] 005 Add auth email delivery:
- [ ] 006 Add web auth helpers/plugs, likely `MembaWeb.UserAuth`, to:
- [ ] 007 Add `/auth` UI and callback handling:
- [ ] 008 Update the home page:
- [ ] 009 Apply auth gates:
- [ ] 010 Add focused tests:
- [ ] 011 Update operational documentation for auth Postmark environment variables and the required message stream.
- [ ] 012 Run `bin/dev check` and fix regressions.
