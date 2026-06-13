# Implementation TODO

- [ ] 001 Inspect the existing auth LiveView, auth email module, Postmark webhook controller, read-model change publisher, and current delivery-status LiveViews that subscribe to read-model changes.
- [ ] 002 Add a small persistence model for auth-email requests/progress, with an opaque public request ID, normalized internal email only where needed, status, provider message/correlation data, timestamps, and expiry/cleanup considerations.
- [ ] 003 Update the sign-in request flow so every submitted address creates an opaque request/progress record before navigation.
- [ ] 004 For recognized recipients, send the auth email with Postmark metadata linking it to the auth request. For unknown recipients, do not send email but keep the request's public status neutral.
- [ ] 005 Change `/auth/check-email` to use an opaque request ID, with backward-compatible handling for any old route if needed.
- [ ] 006 Add LiveView progress rendering and subscription. Refresh from persistence after receiving committed-change notifications.
- [ ] 007 Extend Postmark webhook handling to route auth-stream delivery/problem events to auth-email progress updates without weakening member-message delivery-status handling.
- [ ] 008 Publish auth-email progress changes after the relevant DB update commits, using the ADR 0021 discipline. The auth progress record is not a Commanded projection; use a small committed-update publisher with a narrow auth-progress topic and reload from persistence in the LiveView after broadcast.
- [ ] 009 Add tests for known/unknown submissions, metadata, webhook correlation, duplicate webhook idempotency, live update behaviour, expiry, fallback timing, and privacy-preserving copy.
- [ ] 010 Implement or update acceptance step support for the `@iteration-032` scenarios, then remove/narrow `@todo-domain`/`@todo-ui` when they pass.
