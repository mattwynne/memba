# Group audience foundation: Everyone and Admin

Date: 2026-09-02
Status: validated

## Goal

Replace Memba's hidden club-wide conversation audience with explicit, event-sourced
conversation groups, without changing what any member can currently see, post, or
receive.

Every club will have two built-in conversation groups:

- **Everyone** — all active club members belong automatically.
- **Admin** — members who hold the existing Admin role belong automatically.

Groups are for conversation audiences and access. Roles remain the mechanism that
grants permissions. The Admin role continues to grant `club.manage_members`; the
Admin group does not grant that permission. A domain policy keeps the Admin group
aligned with holders of the Admin role.

## Background / Context

Today, Messaging resolves a new message's recipients directly as every active member
of its club. There is no audience identity on a conversation and no group membership
or group-access model. The only accepted inbound address is the hard-coded Everyone
route, and reply authorisation asks only whether a person is an active club member.

The product vision in [`docs/specs/2026-09-02-groups-and-conversation-access-vision.md`](../../specs/2026-09-02-groups-and-conversation-access-vision.md)
sets the intended destination: groups are conversation audiences; roles and groups
overlap but remain distinct; a conversation grants groups read or write access. This
iteration establishes the two system groups and the message-access seam, while
leaving custom groups and all new visible behaviour for subsequent slices.

The current role model remains in place. In particular, `Admin` remains a
club-scoped role and source of membership-administration authority. The new Admin
group is a conversation cohort derived from that role, not a replacement permission
model. General roles within groups are intentionally deferred.

## Related Problems

- [`docs/problems/2026-06-17-cqrs-event-sourcing-design-drift.md`](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): **partially addresses one concern.** This iteration introduces one explicit Membership policy/process for keeping system-group membership aligned with membership and role facts. It does not attempt the larger application-service or side-effect-boundary cleanup described in the problem.
- [`docs/problems/2026-06-02-send-club-message-by-email.md`](../../problems/2026-06-02-send-club-message-by-email.md): **preserves its resolution.** The existing `everyone@<club>.clubs.memba.io` route remains the only accepted inbound route and now resolves to the explicit Everyone group.
- [`docs/problems/2026-06-04-rejected-inbound-emails-not-visible.md`](../../problems/2026-06-04-rejected-inbound-emails-not-visible.md): **intentionally unresolved.** This iteration does not add group email addresses or a rejected-inbound inbox.
- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **preserves current reply behaviour.** Reply routing, follower delivery, and email threading remain unchanged; only the authorisation seam changes from active-club membership to the Everyone access grant.

## Scope

### In scope

- Introduce Group and Group Membership as Membership-context concepts, with typed
  group IDs and event-sourced commands/events/projections.
- Make the existing Club aggregate own club-scoped system-group definitions and
  group memberships. It already owns club-scoped role definitions and assignments;
  using the same consistency boundary avoids introducing a second aggregate for two
  built-in groups.
- Add two deterministic group identities per club:
  - `Everyone`, created when a club is created;
  - `Admin`, created when a club is created.
- Add Membership events and commands sufficient for this slice:
  - `GroupCreated`;
  - `GroupMemberAdded`;
  - `GroupMemberRemoved`.
- Add `Memba.Membership.Policies.SystemGroupMembership`, a strongly consistent,
  stateless Commanded event handler with idempotent commands, that independently:
  - adds an active member to Everyone after `MemberAdded`;
  - removes the member from system groups after `MemberRemoved`;
  - adds/removes the member from Admin when their existing Admin role is assigned or
    removed.
  The handler starts at `:current` on deployment; it does not replay historic events
  to create backfill facts. The release backfill seeds historic state, while the
  handler keeps both newly created and already-existing memberships aligned after
  deployment.
- Project `membership_groups` and `membership_group_memberships` read models with
  one current-state row per `(group_id, membership_id)`, containing `club_id`,
  `person_id`, and `active`. Add/remove events toggle `active`; a later re-add
  reactivates the same row. The event stream, not duplicated projection rows,
  preserves membership history. Projectors simply project Group events; they must
  not infer special group names or policies.
- Add a public Membership query API for group membership and active group members.
  Messaging must use this API rather than access Membership projection schemas
  directly.
- Introduce the Messaging event `ConversationAccessGrantedToGroup`, containing a
  conversation ID, club ID, group ID, and `read` or `write` access level. For this
  iteration, only `write` is emitted; write includes read.
- Make a new root conversation emit `ConversationAccessGrantedToGroup` for
  Everyone, alongside its existing `MessageSent` and delivery events. Root-message
  send commands carry the resolved audience group ID. Replies do not create a new
  access grant.
- Project `messaging_conversation_group_access` from that event. It is the
  conversation-to-group access read model for later private and shared
  conversations.
- Route existing new-message recipient resolution, inbound Everyone-email sender
  authorisation, and reply authorisation through the Membership group query and
  conversation access grant. Outcomes must remain unchanged: every active member
  can post to Everyone; inactive/non-members cannot.
- Preserve current follower-only reply delivery. Conversation access controls who
  may post; it does not change who receives reply email in this slice.
- Append idempotent, compensating setup events for existing data—never rewrite
  historic events:
  - `GroupCreated` for Everyone and Admin in each existing club;
  - `GroupMemberAdded` for every active membership in Everyone;
  - `GroupMemberAdded` for every active holder of the existing Admin role in Admin;
  - `ConversationAccessGrantedToGroup` granting Everyone write access to every
    existing root conversation.
- Run an operationally safe, restartable backfill automatically from
  `Memba.Release.migrate/0`, after Ecto migrations and application/event-store
  startup. A reusable backfill service paginates authoritative current projections
  and appends only missing facts; it is never an Ecto migration, never runs at
  ordinary application boot, and needs no operator command. Verify that a clean
  projection rebuild produces the same group, membership, and access read models.

### Out of scope

- Custom group creation, deletion, naming UI, or membership-management UI.
- Any new group email address, including `admin@<club>.clubs.memba.io`.
- Any member-visible way to start an Admin-only conversation.
- Conversation read filtering or new pages/sections for groups.
- Public conversation visibility and club/group visibility defaults.
- A UI for selecting one or more groups when composing a conversation.
- Shared conversations with multiple group access grants, although the access model
  must support them later.
- Roles within groups, group-scoped roles, or migration/replacement of the existing
  non-Admin role model.
- Moving `club.manage_members` authority from the existing Admin role to a group.
- Changing email-recipient delivery, follower behaviour, reply threading, or the
  existing Everyone email address.

## Iteration Type

Technical/engineering.

This iteration deliberately introduces no new member-visible rule. It makes the
current Everyone audience and Admin cohort explicit in the event model, projections,
and authorisation seam, while preserving today’s observable club messaging and
membership-administration behaviour.

## Acceptance Scenarios / Feature Files

BDD decision: **Not useful for this slice.**

There is no new stakeholder-visible workflow to describe. Existing feature files
already express the behaviour that must remain true:

- `acceptance-tests/features/member_message_deliverability.feature` — active members
  can send to every active member and use the Everyone inbound address;
- `acceptance-tests/features/club_message_replies.feature` — current members can
  reply and reply delivery remains follower-based;
- `acceptance-tests/features/club_membership_administration.feature` — Admin role
  holders retain membership-administration authority and the last Admin remains
  protected.

No `.feature` files change in this iteration. The new policy, event vocabulary,
projection rebuild, backfill idempotency, and unchanged public APIs need focused
ExUnit/domain tests plus the existing acceptance regression suite.

## Designs

No design needed. This iteration adds no screen, page, component, email, or visible
state. Existing member messaging and Admin-role presentations remain unchanged.

## Acceptance Criteria

- A club has deterministic, projected Everyone and Admin groups after creation.
- Creating a club records the two `GroupCreated` facts in its event stream.
- Adding an active club member records their membership in Everyone through the
  explicit Membership policy; removing the member records their removal.
- Assigning/removing the existing Admin role records the corresponding Admin-group
  membership change through the explicit Membership policy.
- Group membership policies are implemented outside projectors. Projectors project
  Group events and do not branch on a hard-coded Everyone or Admin name/key.
- Existing Admin-role permission checks and the at-least-one-Admin invariant keep
  their current behaviour.
- A new root conversation records an Everyone write grant through
  `ConversationAccessGrantedToGroup`.
- A reply records no additional conversation access grant and is permitted for the
  same active members as before.
- Existing root conversations have exactly one Everyone write grant after backfill.
- Existing club-wide recipient sets, inbound Everyone-email acceptance/rejection,
  reply authorisation, follower delivery, and conversation/email threading remain
  unchanged.
- Membership and Admin-role commands return only after the strong system-group event
  handler and group projectors have made their resulting memberships queryable;
  callers never rely on timing for group access.
- The automatic release backfill is idempotent and restartable: rerunning a failed
  release does not duplicate group, group-membership, or conversation-access
  events/read-model rows.
- A `Memba.EventSourcedCase` replay test clears the relevant projection tables and
  Commanded subscription checkpoints, restarts the group/access projectors, awaits
  them with `Memba.ProjectionBarrier`, and reproduces the post-backfill group,
  membership, and conversation-access read models from the retained event store.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- Groups are conversation audiences; roles grant permissions.
- Everyone and Admin are the only system groups in this slice.
- Active club membership causes membership in Everyone.
- Holding the existing Admin role causes membership in Admin.
- Group membership does not itself grant permissions.
- Existing and new data use appended domain facts and rebuildable projections, not
  projector-only special cases or rewrites of historical events.

## Implementation Plan

1. Inspect the existing Membership Club aggregate, membership lifecycle events,
   Admin-role assignment/removal paths, Commanded router, and projection-barrier
   setup. Add the typed Group ID and the Group command/event modules using the
   project’s existing ID and event conventions.
2. Extend the Club aggregate state and commands so it owns group definitions and
   group memberships. Define deterministic Everyone and Admin group IDs. Make
   `CreateClub` emit `GroupCreated` for both system groups while preserving the
   existing Admin-role creation and permission grant.
3. Add Group aggregate-state validation and idempotent commands for creating a group
   and adding/removing a membership: a group belongs to its club; a membership is
   not added twice; commands carry club, group, membership, and person identities.
   Keep custom-group behaviour unavailable through the public UI/API in this slice.
4. Add `membership_groups` and `membership_group_memberships` migrations, schemas,
   and strong-consistency projectors. `membership_group_memberships` has one
   current-state row keyed by `(group_id, membership_id)`; add/remove toggles its
   `active` flag, so re-add reactivates the row and the event stream retains history.
5. Implement and supervise `Memba.Membership.Policies.SystemGroupMembership` as a
   stateless `Commanded.Event.Handler` with a stable handler name,
   `consistency: :strong`, and `start_from: :current`. It handles each
   `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved`
   independently, dispatching idempotent Club-group membership commands for Everyone
   and the deterministic Admin role. It retains no per-membership workflow state:
   the Club aggregate owns membership state and makes at-least-once handler
   redelivery safe. Configure Group projectors as strong and dispatch affected
   member/role commands with strong consistency, so those commands return only after
   group membership is queryable.
6. Add public Membership queries such as active group members and whether a person
   is an active member of a group. Keep all Membership schema/query details behind
   these APIs, as required by ADR 0007.
7. Add `ConversationAccessGrantedToGroup` and make the root-message path in the
   Message aggregate emit it for the audience group. Add the
   `messaging_conversation_group_access` migration, schema, and strong projector;
   validate access level and make write imply read in the Messaging query API.
8. Change web compose and accepted inbound Everyone-mail command construction to
   resolve the deterministic Everyone group and resolve recipients through the
   Membership group API. Change reply authorisation to require write access through
   an active group membership. Keep reply-recipient/follower delivery unchanged.
9. Implement `Memba.Membership.SystemGroups.Backfill` as a reusable, paginated,
   idempotent service, then invoke it from `Memba.Release.migrate/0` after Ecto
   migrations and application/event-store startup. It scans authoritative current
   projections in dependency order (groups, memberships/Admin assignments, root
   conversations), dispatches only missing commands, logs counts, and aborts the
   release on an unrecoverable error. A subsequent release safely resumes; it is not
   an Ecto migration or an application-boot task. Do not modify or delete historic
   events.
10. Extend `Memba.EventSourcedCase` with the new Group and conversation-access
    projectors/tables. Add a replay-parity test that dispatches representative setup
    and backfill facts, snapshots the group/membership/access queries, calls
    `rebuild_event_sourced_projections!/0`, awaits the new projectors through
    `Memba.ProjectionBarrier`, and asserts the same queries return the same state.
11. Add tests for aggregate decisions; system-group event-handler commands and
    idempotency;
    system-group membership after member/role changes—including future role changes
    and member removal for memberships that were seeded by backfill; sender and reply
    authorisation; recipient/follower-delivery regression; release-backfill reruns;
    and replay parity. Run `dev check`.

## Technical Decisions

- **System-group policy:** `Memba.Membership.Policies.SystemGroupMembership` is a
  stateless Commanded event handler with a stable name. It starts from `:current`,
  uses strong consistency, and handles each membership/Admin-role lifecycle event
  independently. The Club aggregate owns group-membership state; idempotent commands
  make at-least-once handler redelivery safe. Because it holds no process state,
  future role/removal events for memberships seeded by backfill work normally.
- **Membership projection:** `membership_group_memberships` is a current-state
  projection keyed by `(group_id, membership_id)` with `active`; remove/re-add
  toggles that row. The event stream is the membership history. Index current rows
  for group-to-members and person-to-groups access queries.
- **Backfill:** `Memba.Membership.SystemGroups.Backfill` runs automatically from the
  existing release migration flow, after schema migration and app startup. It is a
  paginated, idempotent command dispatcher that logs counts, aborts safely on
  unrecoverable failure, and resumes on the next release. It never runs at normal
  boot and requires no manual operator command.
- **Replay proof:** reuse `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0`
  and `Memba.ProjectionBarrier` in an asynchronous-false ExUnit test after adding
  the new projectors/tables to its reset/restart lists. The test compares query
  results before and after rebuild from retained events.

## New Capability

Memba has explicit, rebuildable Group identities and memberships for its two
existing conversation cohorts, plus a conversation-to-group write-access model.
Current club-wide messages are no longer a hidden special case: they are Everyone
conversations. The next iteration can build a usable Admin-group email route on
this foundation without introducing a second audience model.

## Validation Plan

- Run focused Membership and Messaging ExUnit tests while implementing the aggregate,
  policy, projections, and access change.
- Test a club creation path produces Everyone and Admin facts; member and Admin-role
  lifecycle changes produce the intended group-membership facts once and only once.
- Test that the existing acceptance examples still have the same recipients,
  authorisation results, reply followers, and email threading after the new policy
  is in place.
- Exercise the automatic `Memba.Release.migrate/0` backfill path against
  representative existing clubs, memberships, Admin-role assignments, root messages,
  and replies; interrupt/retry it in tests and assert no duplicate facts or current
  rows.
- Use `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0` and a projection
  barrier to rebuild the relevant Membership and Messaging projections from retained
  events, then compare their group/membership/access query results to the
  post-backfill state.
- Stop only when those focused tests, existing acceptance regressions, replay parity,
  idempotent automatic-backfill coverage, and `dev check` all pass on the committed
  implementation state.

## Risks / Follow-ups

- The new system-group event handler is the main operational risk. It crosses
  existing membership/role lifecycle facts and Club-owned group state; idempotency,
  stable subscription identity, failure visibility, and read-your-writes behaviour
  must be explicit.
- Appending setup facts to historic streams is safer than changing old event meaning,
  but production backfill needs careful batching, observability, and restart safety.
- The Admin group mirrors the existing Admin role; it does not replace role-based
  authorisation. A later role-within-group design must decide how generic roles and
  group memberships relate without conflating conversation access with permissions.
- Group email is deliberately next: `admin@<club>.clubs.memba.io` should be the first
  usable vertical slice, using Admin-group access while adding no custom-group UI.
- Private named groups, group read filtering, public conversations, shared access,
  and group/role management remain separate slices.
