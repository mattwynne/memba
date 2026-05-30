# Implementation TODO

- [x] 001 Use TDD with PhoenixTest as the preferred high-level LiveView test API. Start by writing failing PhoenixTest coverage for the real route flows listed in the acceptance criteria.
- [x] 002 Add browser routes under the existing browser pipeline:
- [x] 003 Add `POST /webhooks/postmark` under an appropriate non-browser pipeline for webhook requests.
- [ ] 004 Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:
- [ ] 005 Build `MembaWeb.ClubsLive.Index`, `MembaWeb.ClubsLive.Show`, and `MembaWeb.MessagesLive.Show` with simple forms/actions for club creation, person creation, membership, club message sending, and receipt viewing.
- [ ] 006 Build the Postmark webhook controller/handler to parse Postmark-style event payloads and call the public Messaging status-reporting functions.
- [ ] 007 Give important forms, controls, rows, and status displays stable IDs or accessible labels suitable for Playwright and PhoenixTest.
- [ ] 008 Update Playwright/Cucumber step definitions to drive the real LiveView routes for `homepage.feature` and `member_message_deliverability.feature`; delivery/open report steps should make HTTP requests to `POST /webhooks/postmark`.
- [ ] 009 Add `@todo-web` tags to operator deliverability scenarios that are intentionally not browser-backed in this iteration.
- [ ] 010 Configure `acceptance-tests/cucumber.js` so the default browser Cucumber command uses `tags: "not @todo-web"`.
- [ ] 011 Verify the Elixir/domain acceptance path used by `dev check` still runs every shared scenario regardless of `@todo-web` tags.
- [ ] 012 Run the browser acceptance suite and `dev check`, fixing any issues.
