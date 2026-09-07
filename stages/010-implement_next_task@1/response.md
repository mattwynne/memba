Implemented and checked off task 019:

> Authorise the current person via an active group with the conversation's required access level, not merely via club membership or current rail state.

The implementation was recovered from the previous failed Fabro checkpoint, inspected, and validated:

- [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:541) now exposes person-level conversation authorization. It resolves root and reply IDs, validates club ownership, obtains active groups through Membership’s public API, and applies read/write grant semantics.
- In-app follow and unfollow now require effective read access at action time; replies require effective write access.
- [member_message_detail.ex](/workspace/memba/web/lib/memba_web/member_message_detail.ex:27) resolves the signed-in person through Membership, verifies active club membership, and returns not found unless one of that person’s active groups grants conversation access. URL `group_id` state is not used as authority.
- Existing tests cover private-group detail access, no-disclosure denial, reply resolution, read-versus-write grants, inactive group membership, follow/unfollow, delivery pages, and Everyone regressions.

Validation:

- Focused suite: 55 tests, 0 failures.
- Full `PATH="$PWD/bin:$PATH" dev check`: passed.
- `git diff --check`: passed.
- The first focused invocation used workspace-prefixed test paths, which the `dev test` wrapper rejected; rerunning with paths relative to `web/` passed.

Exact check-off made in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:21):

```markdown
- [x] 019 Authorise the current person via an active group with the conversation's required access level, not merely via club membership or current rail state.
```

No tasks were split, added, reordered, or otherwise checked off. Task 020 remains pending for explicit multi-group/shared-conversation proof.

ADR conformance:

- ADR 0002: authorization remains in query/application services; state changes still dispatch commands.
- ADR 0005: recipient resolution and aggregate responsibilities are unchanged.
- ADR 0007: Messaging uses Membership’s public API and does not query Membership projection schemas.
- ADR 0015: detail and delivery remain LiveView surfaces behind the shared authorization loader.
- ADR 0021: LiveView refreshes re-enter the same authorization loader after committed read-model notifications.
- ADR 0023: `group_id` remains navigation state, while effective access is recomputed independently from active membership and conversation grants.