# Implementation TODO

- [x] 001 Inspect the post-iteration-009 route structure and admin pipeline.
- [x] 002 Add persistence for authentication:
- [x] 003 Add an authentication context, likely `Memba.Accounts` or `Memba.Identity`, with functions to:
- [x] 004 Extend `Memba.Membership` query API as needed:
- [x] 005 Add auth email delivery:
- [x] 006 Add web auth helpers/plugs, likely `MembaWeb.UserAuth`, to:
- [x] 007 Add `/auth` UI and callback handling:
- [x] 008 Update the home page:
- [ ] 009 Apply auth gates:
- [ ] 010 Add focused tests:
- [ ] 011 Update operational documentation for auth Postmark environment variables and the required message stream.
- [ ] 012 Run `bin/dev check` and fix regressions.
