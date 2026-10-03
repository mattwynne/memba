Matt’s guidance: “Repair as planned.”

Selected task: 008A — complete and focused-test the Memba committed-read-model adapter, preserving exact scoped matching, isolating unrelated queries, surfacing malformed recognized notifications as contract violations, and auditing all fallbacks against real projector event shapes.

The validator accepted the latest no-op identity correction: malformed false-auto-follow `MessageSent` and replay-only `EmailDeliveryOpened` notifications now raise the expected contract exception, while complete valid events remain ignored. The adapter suite passed 30 tests with 0 failures.

The candidate remains incomplete because the validator found broader isolation and fallback issues:

- `ConversationFollow` emits both the exact `{:conversation_follow, conversation_id, member_id}` key and `{:conversation, conversation_id}`. The latter can reread another member’s query for the same conversation.
- `Membership` and `GroupMembership` emit `{:person, person_id}`, potentially rereading queries in unrelated clubs or groups merely because they represent the same Person.
- Existing tests show unchanged rendered output but do not prove that those unrelated queries were never reread.
- Some consumers retain generic fallback interests for which the corrected adapter has no evidenced producer.

Matt agreed to a bounded repair that:

- Removes invalidations that do not represent data actually changed by the notifying projector, while retaining exact relationship, collection, and authorization keys.
- Adds refresh-count isolation tests for:
  - the same conversation with a different member;
  - the same Person in a different club.
- Removes inert generic fallback interests, unless a real current or legacy producer can be documented.
- Reconciles the migration matrix if the audited mappings require it.

No new business or architectural constraint was raised. The remaining technical question is evidentiary: whether any real publisher or historical event shape justifies one of the generic fallback interests. If none does, those interests should be removed.

Safe next step: prepare a new bounded task-008A repair packet from the saved checkpoint, implement only the agreed isolation and fallback-audit changes, run focused tests including refresh-count assertions, and submit the result for fresh independent validation. Task 008A remains unchecked; this clarification does not approve the candidate, authorize publication, or launch recovery.