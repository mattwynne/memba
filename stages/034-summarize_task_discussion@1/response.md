Matt’s guidance: “repair as planned.”

Selected task: 008A — complete and focused-test the Memba committed-read-model adapter against actual projector/event families and evidenced valid-scope fallbacks.

The validator found one remaining contract gap. Recognized no-op events currently bypass required identity validation:

- `MessageSent` with `sender_follows_conversation: false` returns `:ignore` before validating `club_id`, `message_id`, and `sender_id`.
- `EmailDeliveryOpened` returns `:ignore` before validating `message_id` and `delivery_id`, for both delivery projectors.

As a result, malformed recognized events can be silently ignored instead of raising the stable application-owned `ReadModelContractViolationError`. Existing focused tests pass—28 adapter tests and 8 query-vocabulary tests—but do not cover these malformed no-op paths.

The agreed bounded repair is to validate required identities before applying no-op behavior, then add focused tests for malformed false-auto-follow notifications and malformed `EmailDeliveryOpened` notifications through both delivery projectors. Valid, complete false-auto-follow and replay-only opened events must remain ignored.

There are no unresolved business examples or architectural constraints. The generic package contract remains frozen, and no LiveView, projector, schema, domain event, plan, todo, migration matrix, ADR, or acceptance feature change is proposed.

Safe next step: after a separate explicit resume decision, continue task 008A from the saved checkpoint, implement only this bounded repair, run the focused adapter and accepted query-vocabulary suites, and return the candidate for fresh independent validation. Task 008A remains unchecked; publication and completion are not approved.