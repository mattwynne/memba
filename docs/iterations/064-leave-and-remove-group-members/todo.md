# Implementation TODO

- [x] 001 Implement and test the actor-bearing custom-group removal use case at the Club boundary, including custom-group/actor/target validation, self/last-member removal, idempotency, and reuse of `GroupMemberRemoved` without club/role removal.
- [ ] 004 Implement and test explicit custom-group-removal follow cleanup through public Messaging APIs, including manual and auto-follow sources, idempotent stale-safe remove/re-add ordering, unrelated-follow preservation, and unchanged system-group behaviour.
- [ ] 009 Apply current authorization throughout group/conversation queries, actions and queued-delivery handoff.
- [ ] 010 Refresh `MemberDashboardLive`, conversation views and membership panels on relevant read-model events so content disappears after revocation; hiding tabs alone is insufficient.
- [ ] 011 Avoid sending stale queued private content to removed recipients using existing delivery-status/error mechanisms rather than a new UI workflow.
- [ ] 012 Extend shared custom-group member rows with Remove/Leave confirmation and post-removal surfaces.
- [ ] 013 Preserve ordinary member lists, actor role labels, route context, focus handling and the single tab action slot.
- [ ] 014 Empty groups use existing admin additions, with no new lifecycle status.
- [ ] 015 Implement domain/browser examples and focused aggregate, follower-policy, queued-delivery, rapid remove/re-add and LiveView tests.
- [ ] 016 Include replay/idempotency, preserved unrelated follows, delivered-copy limits and existing system/club invariants.
- [ ] 017 Run `dev check` on the exact final delivery state.
