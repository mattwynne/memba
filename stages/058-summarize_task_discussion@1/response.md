Run paused at task 008A; the candidate remains incomplete and unapproved.

Matt’s guidance:

- A Membership notification containing a club ID but no recoverable person ID is invalid.
- Do not emit either a club-scoped or global Membership fallback for that malformed notification.
- Treat it as a contract violation and surface it accordingly.
- Membership adapter tests must use actual projector event structs.
- This clarification is not task acceptance, publication approval, or permission to resume implementation.

Selected task:

> 008A Complete and focused-test the Memba committed-read-model adapter against every projector/event family and conservative fallback in the accepted migration matrix, preserving exact scoped matching and ignoring unrelated projectors.

The validator had requested a club-scoped fallback when Membership person identity was unavailable. Matt’s architectural clarification supersedes that proposed repair: actual Membership projector events are expected to carry or permit recovery of the person identity; malformed known notifications must fail the adapter contract instead of causing broad refreshes.

Concrete expected cases:

- Valid actual Membership projector event with recoverable club and person scope: emit exact collection and identity invalidations.
- Known Membership notification with a club ID but no recoverable person ID: surface a contract violation; do not refresh through a fallback.
- Unrelated projectors and malformed non-notification messages remain ignored according to the existing boundary; this clarification specifically concerns malformed notifications claiming to be known Membership publications.

Still unresolved and requiring fresh review:

- Whether `ConversationFollow` should ignore `MessageSent` when `sender_follows_conversation` is `false`.
- Required coverage for unknown Club events.
- Club-only and empty Group fallback behavior.
- Failed legacy Role scope recovery.
- Club-scoped conversation-access and follow fallback behavior.
- The exact mechanism and observable shape used to surface a Membership contract violation should be confirmed against current adapter conventions.

Safe next step: update the plan/worker packet to encode Matt’s Membership contract, then obtain a fresh independent review of task 008A and the remaining validator findings. Only after an explicit decision should implementation resume from the saved checkpoint. Do not accept the candidate, publish it, or launch recovery before that decision and validation.