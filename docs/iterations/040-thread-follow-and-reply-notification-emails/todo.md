# Implementation TODO

- [x] 001 Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
- [x] 002 Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
- [ ] 003 Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
- [ ] 004 Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
- [ ] 005 Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
- [ ] 006 Run `dev check`.
