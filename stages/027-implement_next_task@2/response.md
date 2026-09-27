Implemented packet `002-589c4603-1` with result `ready_for_review`.

Changes:

- Added the application-layer `RequestGroupAccess` intent with the narrow input shape `message_id`, authenticated `club_id`, `requester_person_id`, and target `group_id`.
- Added `Memba.Messaging.request_group_access/2`.
- At the stable authorization checkpoint, it now:
  - resolves authoritative requester, club, and custom-group facts;
  - rejects inactive, invalid, cross-club, built-in, or already-participating requesters;
  - resolves current Admin recipients;
  - derives the fixed subject, body, and club-hosted targeted-add URL;
  - dispatches the existing `SendMessage` and propagates its result.
- Preserved ordinary Admin conversation access, delivery, and sender-follow semantics.
- Ignored forged sender, destination, recipient, content, name, slug, and URL fields.
- Did not add `RequestGroupAccess` to the Messaging router or change general web composition.
- Added focused coverage in [request_group_access_test.exs](/workspace/memba/web/test/memba/messaging/request_group_access_test.exs) and updated the public API inventory.

Validation:

- Messaging-focused command: 17 tests, 0 failures.
- Membership/message-policy regression command: 30 tests, 0 failures.
- Changed Elixir files pass `mix format --check-formatted`.
- `git diff --check` passes.
- Per packet constraints, `dev check` was not run; the workflow’s deterministic `dev_check` node owns that gate.

The required result artifact is at [latest-worker-result.json](/workspace/memba/docs/iterations/066-request-group-access/.delivery/latest-worker-result.json). `todo.md` remains unchanged.