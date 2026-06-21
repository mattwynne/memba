# Implementation TODO

- [x] 001 Inspect the current inbound address helper, destination resolver, Postmark/Resend inbound parsers, member dashboard/compose display, reply email generation from iteration 041, production smoke-test config, and Postmark docs.
- [x] 002 Update the inbound address helper so a club slug renders as `everyone@<slug>.<configured inbound domain>`, where the production/default inbound namespace remains `clubs.memba.io`.
- [x] 003 Update destination resolution to parse `local_part@host` where `host` is `<club-slug>.<configured inbound domain>`.
- [x] 004 Accept only `local_part == "everyone"` for now.
- [x] 005 Resolve `<club-slug>` through the existing Membership slug lookup.
- [x] 006 Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address using the existing inbound rejection pathway where possible.
- [x] 007 Update member dashboard and member compose copy/mailto links to display the new address.
- [ ] 008 After integrating with 041's result, update reply notification email `Reply-To` / reply destination generation to use the new address while preserving 041's `Message-ID` / `In-Reply-To` / `References` header behaviour.
- [ ] 009 Update provider parser or provider-neutral inbound email tests where recipient-address normalization assumes the old flat address.
- [ ] 010 Update acceptance step support to generate and submit new-address inbound webhook payloads; remove/narrow `@todo-domain` / `@todo-ui` tags as scenarios become executable.
- [ ] 011 Update `docs/postmark-email.md` and any production cutover/runbook text that describes inbound club-message email.
- [ ] 012 Update `smoke-tests/lib/config.js`, smoke-test assertions, and `smoke-tests/README.md` so the default smoke address is `everyone@test.clubs.memba.io` and Postmark diagnostics look for that recipient.
- [ ] 013 Run `dev check`.
- [ ] 014 After Matt confirms Postmark/DNS are configured for `*.clubs.memba.io`, run the production inbound smoke test and record/report the result.
