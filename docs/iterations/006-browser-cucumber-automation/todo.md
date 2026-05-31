# Implementation TODO

- [x] 001 Inspect the current `acceptance-tests/` Playwright/Cucumber setup and the shared feature files to identify existing step coverage and gaps.
- [ ] 002 Configure the browser Cucumber default command to exclude `@todo-web`, while leaving the Elixir/domain Cucumber runner unfiltered.
- [ ] 003 Build or refine the browser test lifecycle wrapper so it prepares the test database, starts Phoenix, waits for HTTP readiness, captures useful logs, and tears down reliably.
- [ ] 004 Implement homepage browser steps against the real homepage route.
- [ ] 005 Implement member-message browser steps by driving `/clubs`, `/clubs/:club_id`, and `/messages/:message_id` through accessible labels, roles, and stable identifiers supplied by the existing UI.
- [ ] 006 Implement webhook/status browser steps by sending Postmark-style HTTP requests to `POST /webhooks/postmark`.
- [ ] 007 Add bounded polling/waiting around browser-visible projections after commands and webhook posts. Prefer Playwright assertions such as `expect(...).toHaveText`, `expect.poll`, or equivalent Cucumber helper retries over fixed sleeps.
- [ ] 008 Make diagnostics actionable: separate errors for Phoenix readiness, database setup, webhook HTTP failures, timeout waiting for projected UI state, and final assertion mismatches.
- [ ] 009 Verify that `operator_email_deliverability.feature` is excluded only from the browser run and remains covered by the domain runner.
- [ ] 010 Run `npm test` in `acceptance-tests/` and `dev check`, fixing harness/step issues until both pass.
