# Implementation TODO

- [x] 001 Extend the Membership group write model, events, state, and projections with an immutable normalised email slug, unique per club.
- [x] 002 Evolve new-group creation to carry it, and append idempotent email-slug facts for existing Everyone and Admin groups without rewriting historic group events.
- [x] 003 Make new-club system-group creation and the release backfill assign `everyone` and `admin` consistently. Expose a public Membership lookup by club and group email slug; Messaging must not query Membership schemas directly.
- [x] 004 Generalise inbound destination resolution from the hard-coded `everyone` local part to a group-slug lookup on the existing `<club-slug>.clubs.memba.io` host.
- [x] 005 Keep unsupported routes and unknown club/group slugs on the existing rejection path.
- [x] 006 Introduce a named fixed group-email posting policy in Messaging.
- [x] 007 For a new inbound conversation it authorises the resolved sender by active membership of the destination club, not membership of the addressed group.
- [x] 008 Carry the resolved audience group through the existing inbound root-message command.
- [x] 009 Resolve deliveries through active group members and emit the group write-access grant.
- [x] 010 If the sender is not a recipient, do not create a delivery, acknowledgement, access, or follower relationship for them.
- [x] 011 Reuse the group-write reply authorisation delivered by 056 for Admin conversations.
- [x] 012 Keep header routing and follower-only reply delivery unchanged; cover direct/forged non-member reply attempts with focused domain tests rather than a new stakeholder scenario.
- [x] 013 Add public Messaging queries that list conversations and read a conversation through a supplied group ID and its access grant.
- [x] 014 Refactor current web query callers to pass the Everyone group, preserving the existing visual UI and ensuring Admin conversations remain absent until the later group display iteration.
- [x] 015 Add aggregate, policy, projection/replay, release-backfill, inbound-route, authorisation, recipient-delivery, sender-non-following, and reply-authorisation tests.
- [x] 016 Cover slug uniqueness and safe re-runs of the slug backfill.
- [x] 017 Keep existing Everyone acceptance regressions passing.
- [x] 018 Implement the accepted scenarios' domain and browser support, removing or narrowing `@todo-domain` / `@todo-ui` only when each runner can execute the relevant scenario. Run `dev check`.
