# Implementation TODO

- [ ] 001 Model the conversation/reply in `Memba.Messaging`: decide whether the existing message aggregate is extended to hold replies, or a conversation concept references it; keep it event-sourced and consistent with existing commands/events.
- [ ] 002 Add command(s)/event(s) for posting a reply, with authorization that the actor is a current member of the message's club, and non-blank body validation.
- [ ] 003 Deliver the reply by email to every current member (excluding the author) by reusing the `send_club_message` delivery + receipt path; build the reply email on the shared transactional layout/footer with `<club> via Memba` sender and conversation context.
- [ ] 004 Add/extend projector(s) and read APIs to load a conversation (root + ordered replies).
- [ ] 005 Update the member message-detail LiveView/template: render the conversation and an inline reply composer (body only, inheriting the subject); keep delivery receipts available (demoting them per the sketch is acceptable but optional).
- [ ] 006 Make the `@iteration-039` scenarios executable (domain steps first, then browser), removing/narrowing `@todo-*` as each runner can run them.
- [ ] 007 Run `dev check`.
