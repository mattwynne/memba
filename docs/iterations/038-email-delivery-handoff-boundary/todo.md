# Implementation TODO

- [x] 001 Inspect current outbound send paths and tests:
- [x] 002 Update the `EmailDelivery` projection/read model so newly created records start with status `pending` and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.
- [x] 003 Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.
- [x] 004 Introduce a named dispatch module/process, probably `Memba.Messaging.EmailDeliveryDispatcher`, under the application supervision tree.
- [x] 005 Make the dispatcher subscribe to `Memba.ReadModelChanges.topic()` and treat relevant `EmailDeliveryCreated`/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.
- [x] 006 Implement claiming logic that moves a pending delivery to `dispatching` before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.
- [ ] 007 Move request-building/provider-call logic out of `Memba.Messaging` into the dispatcher or a focused collaborator used by the dispatcher.
- [ ] 008 On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.
- [ ] 009 Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.
- [ ] 010 Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.
- [ ] 011 Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.
- [ ] 012 Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.
- [ ] 013 Add/update focused tests for the acceptance criteria above.
- [ ] 014 Run `dev check` and fix any regressions.
