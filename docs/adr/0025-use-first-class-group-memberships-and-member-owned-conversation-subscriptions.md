# 25. Use first-class group memberships and member-owned conversation subscriptions

Date: 2026-09-22

## Status

accepted

## Related reference guidance

- [Domain-Driven Design](../reference/domain-driven-design.md) for choosing consistency boundaries around immediate invariants and using explicit contracts between bounded contexts.
- [CQRS](../reference/cqrs.md) for keeping command-side authority separate from read projections.
- [Event Sourcing](../reference/event-sourcing.md) for immutable history, replay compatibility, and append-only reconciliation.
- [Responsibility-Driven Design](../reference/responsibility-driven-design.md) for assigning participation, subscription, authorization, and coordination responsibilities to explicit collaborators.

## Context

A club membership and a group membership are different domain relationships.
A `club_membership_id` identifies a person's active relationship with a club and
is the target of club roles. A custom-group admission is a separate,
shorter-lived relationship. Removing someone from Board must end only their
Board participation; it must not remove their club membership or Admin role.
If the person later rejoins Board, that is a new admission rather than
reactivation of the ended relationship.

The existing model does not express that distinction. `Memba.Membership.Club`
stores a reusable active/inactive relation keyed by
`{group_id, club_membership_id}`. Both that write model and the
`membership_group_memberships` projection call the club membership identifier
`membership_id`. `GroupMemberAdded` and `GroupMemberRemoved` toggle the same
relation across removals and re-additions, so they cannot identify the exact
group-membership period that authorized later work.

The existing follow model has the same temporal ambiguity.
`Memba.Messaging.ConversationFollowers` is conversation-owned, records only a
person identifier, and derives auto-follow state directly from `MessageSent`.
When a custom-group membership ends, a Membership event handler scans projected
conversations and sends one unfollow command per conversation. Delayed follow
work, projection lag, handler retries, aggregate restarts, or removal followed
by re-addition can all race that scan. Club-wide generations and projected
conversation cutoffs do not establish which group-membership fact authorized a
subscription.

Iteration 064 requires removal to revoke participation and future delivery,
clear subscriptions authorized only by the ended group membership, and return
only after Messaging has durably processed that revocation. It also requires a
subscription to survive when another current group membership independently
authorizes the same conversation. Projection barriers cannot prove this domain
work completed: as [ADR 0022](0022-use-projection-barriers-for-read-your-writes.md)
states, they prove only that selected read models reached a checkpoint.

## Decision

### Membership owns first-class custom-group memberships

A **club membership** and a **custom-group membership** are separate entities:

- `club_membership_id` identifies the person's club relationship and remains
  the identity used by club roles and club-membership lifecycle rules.
- `group_membership_id` identifies one admission of that club membership to one
  custom group.
- Every genuine custom-group admission receives a new
  `group_membership_id`. Ending and later re-adding the same person to the same
  group never reuses an ended identifier.

Use `Memba.Membership.Club`, routed to the existing stream by `club_id`, as the
consistency boundary for custom-group membership lifecycle. A custom-group
membership is a first-class entity inside that aggregate; it is not a separate
aggregate stream. This boundary serializes group admission/removal with current
club membership, club roles, custom/system group identity, and the complete set
of the club's custom-group memberships. Consequently, one aggregate decision
can enforce the accepted actor and target authorization without projection
preflights:

- an active member of a custom group or an active club Admin may admit an
  eligible active club member;
- an active member of a custom group or an active club Admin may remove a
  current member;
- self-removal and removal of the last custom-group member are allowed; and
- club membership, roles, Admin continuity, group existence, and conversation
  history are unchanged by custom-group removal.

The public write vocabulary is:

- `AddCustomGroupMember`, carrying `club_id`, `group_id`,
  caller-generated `group_membership_id`, target `club_membership_id`,
  `person_id`, and `actor_person_id`;
- `RemoveCustomGroupMember`, carrying `club_id`, `group_id`, the exact
  `group_membership_id`, target `club_membership_id`, `person_id`, and
  `actor_person_id`;
- `CustomGroupMembershipStarted`, carrying those unambiguous identities and
  the admitting actor; and
- `CustomGroupMembershipEnded`, carrying those identities, the removing actor,
  and an explicit end reason.

`AddCustomGroupMember` follows the caller-generated typed UUID rule from
[ADR 0011](0011-use-caller-generated-uuid-aggregate-identities.md). Its caller
generates `group_membership_id` before dispatch. An exact retry with an already
started identifier emits no event. Reusing that identifier for different
club, group, club-membership, or person data is rejected. A new admission after
an end must supply a new identifier.

`RemoveCustomGroupMember` selects the first-class relationship by
`group_membership_id`, not merely by person and group. An exact retry after that
relationship ended emits no event. A delayed retry therefore cannot end a
newer admission for the same person. A fresh removal decision validates the
actor and target against current aggregate state and emits
`CustomGroupMembershipEnded` only for the selected relationship.

Membership's public query contract remains authoritative for current group
participation. Its current-state projection exposes both
`club_membership_id` and `group_membership_id` and contains one row for each
current custom-group membership, rather than retaining a reusable
active/inactive relation. Read models may make this authority convenient to
query, but they do not replace the Club aggregate for write decisions.

### Legacy custom-group relations are reconciled conservatively

Historic `GroupMemberAdded` and `GroupMemberRemoved` events remain immutable
and replayable. During Club replay they continue to build the legacy
active-relation state needed for compatibility. New custom-group writes emit
only the first-class events above; the old event family remains available for
the system-group consequences described below.

Run a bounded, restartable reconciliation for every custom-group relation that
full legacy replay proves is active at cutover. Dispatch
`ReconcileLegacyCustomGroupMembership` to the Club stream with:

- `group_membership_id` deterministically derived from
  `{club_id, group_id, club_membership_id}`;
- the explicit `club_id`, `group_id`, `club_membership_id`, and `person_id`;
  and
- a deterministic reconciliation identifier equal to that source relation.

The command emits `LegacyCustomGroupMembershipReconciled`. That event means
only “this relation was provably current at reconciliation”; it does not claim
an admission date or synthesize earlier membership periods. The aggregate
records the deterministic identifier, so a retry or restart emits no duplicate
event. A conflicting deterministic identity is an error rather than an
overwrite.

Inactive legacy relations produce no first-class membership. In particular,
reconciliation must not infer an admission/removal pair from incomplete
history, invent identifiers for unproved periods, or rewrite source events.
Projectors understand the legacy event family plus the reconciliation event
during migration and use first-class events after cutover.

### System-group consequences retain their derived identity

Everyone and Admin are derived system groups, not genuine custom-group
admissions. First-class `group_membership_id` identity does not apply to them
in this decision:

- Everyone participation remains a consequence of active club membership.
- Admin-group participation remains a consequence of the current Admin role.
- Trusted policies may continue to emit and replay `GroupMemberAdded` and
  `GroupMemberRemoved` for those system-group consequences.
- Custom-group commands reject Everyone and Admin and cannot grant or remove a
  club role.

System-group events remain downstream consequences, not the source of club
membership or Admin authority. This preserves the ownership and continuity
rules in [ADR 0024](0024-use-club-as-membership-admin-consistency-boundary.md).
Messaging records the applicable `club_membership_id` and system-group
authority kind when a system-group conversation is followed; custom-group
revocation never fabricates or removes that authority.

### Messaging owns one member subscription stream

Replace the conversation-owned follower aggregate with
`Memba.Messaging.MemberConversationSubscriptions`. Route one aggregate stream
by `person_id`. That stream serializes all conversation subscription intents,
ordinary unfollows, custom-group authorization revocations, and completion
receipts for one person. `subscription_id` is deterministic from
`{person_id, conversation_id}`; each attempt to establish a subscription has a
separate caller-generated `subscription_intent_id`.

Messaging is authoritative for whether the person is subscribed. Membership
is authoritative for whether a `group_membership_id` is current. The
integration follows [ADR 0007](0007-use-separate-membership-and-messaging-commanded-contexts.md):
Messaging uses Membership's public contract and never reads Membership
aggregates, event streams, or projection tables directly.

The canonical command and event vocabulary is:

- `PrepareConversationSubscription` /
  `ConversationSubscriptionPrepared`;
- `ActivateConversationSubscription` /
  `ConversationSubscriptionAuthorized`;
- `EndConversationSubscription` /
  `ConversationSubscriptionEnded`;
- `RevokeGroupMembershipSubscriptions` /
  `GroupMembershipSubscriptionAuthorizationRevoked`; and
- `GroupMembershipSubscriptionRevocationCompleted`, the durable completion
  receipt.

Canonical subscription facts carry `person_id`, `club_id`, `conversation_id`,
`subscription_id`, `subscription_intent_id`, source (`manual`, `root`, `reply`,
or `legacy_reconciliation`), and the complete set of
`authorizing_group_membership_ids` resolved for custom groups. They do not use
the ambiguous field `membership_id`. System-group authorization is represented
separately by `club_membership_id` and an explicit authority kind.

`ConversationSubscriptionAuthorized`,
`ConversationSubscriptionEnded`, and
`GroupMembershipSubscriptionAuthorizationRevoked` are the sole facts from
which the aggregate and current follow projection derive subscription state.
`MessageSent` is no longer interpreted as a follow fact.

### Provenance is server-resolved and follow intent is durable

Manual follow and successful root/reply auto-follow use one public Messaging
operation. Product, UI, and message callers provide intent and the relevant
person/conversation identifiers; they may not provide trusted
`authorizing_group_membership_ids`, `club_membership_id`, or authority kind.
The operation resolves the conversation's groups and current authorization
through Membership's public API, then sends a trusted internal command.

The operation has prepare and activate phases so delayed work cannot undo an
ordinary unfollow:

1. `PrepareConversationSubscription` persists a unique intent and its
   server-resolved authorization in the member stream.
2. Manual follow activates that prepared intent immediately.
3. Root/reply auto-follow prepares the intent before sending and activates the
   same intent only after `MessageSent` confirms success. A failed send cancels
   or leaves no activatable intent.
4. `EndConversationSubscription` ends the active subscription and cancels all
   earlier prepared intents for that conversation in the same member stream.
5. A delayed activation for a cancelled, ended, unknown, or already-completed
   intent emits no event. A later explicit follow has a new intent and may
   succeed after current authority is resolved again.

This protocol, including prepared and cancelled intent state, is rebuilt from
the member stream after aggregate restart. Handler retries use the same
`subscription_intent_id` and are event-free after the first successful
transition.

### Membership revocation is one idempotent cross-context command

When `CustomGroupMembershipEnded` is committed, a strong, retrying Membership
policy sends exactly one logical `RevokeGroupMembershipSubscriptions` command
through Messaging's public API. It does not enumerate conversations. The
command carries `person_id`, `club_id`, `group_id`, `group_membership_id`, and
a `revocation_id` deterministically derived from `group_membership_id`.

In the person's subscription stream, one aggregate decision:

1. permanently records `group_membership_id` as revoked;
2. removes that identifier from every prepared and active authorization;
3. ends a subscription only when it has no other current authorization; and
4. appends `GroupMembershipSubscriptionRevocationCompleted` with the same
   `revocation_id`.

The revocation fact and completion receipt are appended atomically. The
aggregate retains revoked membership identifiers and completed revocation
identifiers, so an exact handler retry emits no events and an old delayed
intent cannot become authorized after an aggregate restart. The receipt exists
even when the ended membership authorized no subscription.

The following outcomes are independent of command arrival order:

- If an old intent is authorized first, later revocation removes the ended
  membership's authorization.
- If revocation arrives first, a later prepare or activation carrying that
  ended identifier is rejected.
- Revoking one identifier preserves a subscription authorized by another
  current custom-group membership or applicable system-group authority.
- Re-addition has a new `group_membership_id`; it does not un-revoke the old
  identifier or restore an ended subscription.
- An explicit follow after re-addition resolves the new identifier and can
  establish a new subscription.
- Ordinary unfollow cancels earlier prepared work, while a genuinely later
  explicit follow uses a fresh intent and can succeed.

The Membership removal application service may report cleanup complete only
after it observes the matching
`GroupMembershipSubscriptionRevocationCompleted` domain receipt through
Messaging's public receipt API. A receipt projection or subscriber may make
that fact awaitable, but callers wait for the named receipt; they do not infer
completion by enumerating projected conversations. Projection barriers remain
limited to coordinating visibility of selected read models.

### Historic follows are reconciled once

Before canonical subscription facts become the only live source, run a
restartable reconciliation over historic `MessageSent`,
`ConversationFollowed`, and `ConversationUnfollowed` shapes to derive each
person's provable effective follow at cutover. For each candidate:

- use a deterministic reconciliation and `subscription_intent_id` based on the
  historic person/conversation relation;
- resolve current authorization on the server;
- dispatch `ReconcileLegacyConversationSubscription` to the person's stream;
  and
- append a reconciliation marker plus
  `ConversationSubscriptionAuthorized` only when both the historic follow and
  current authorization are provable.

The persisted marker makes item retries event-free, and a durable job
checkpoint makes enumeration restartable. A missing current authorization,
ambiguous historic state, or a formerly removed custom-group relation does not
produce a subscription. Reconciliation does not assign historic follows to
unproved group-membership periods.

After the cutover checkpoint, live follow paths do not scan legacy messages or
follow projections. Existing events stay replayable as historical facts, but
aggregate and projection replay uses the newly appended canonical subscription
facts for current state.

### Current authorization is required through provider handoff

A subscription is necessary for followed delivery but is never sufficient
proof of current access. Group and conversation reads, writes, follow actions,
notification creation, queued-delivery claiming, and the final email-provider
handoff recheck current authority through Membership's public contract.

If access ended before provider handoff, pending private delivery is skipped or
made ineligible even if a lagging read model still shows a follow. Once a
provider has accepted a delivery, Memba cannot recall it. Projection barriers
may make revoked state visible to pages and tests, but neither authorization
nor delivery eligibility is inferred from barrier completion.

## Relationship to earlier decisions

- This decision preserves [ADR 0007](0007-use-separate-membership-and-messaging-commanded-contexts.md):
  Membership owns participation, Messaging owns subscriptions and delivery,
  and their collaboration uses public contracts.
- It extends [ADR 0011](0011-use-caller-generated-uuid-aggregate-identities.md)
  with caller-generated `group_membership_id` and
  `subscription_intent_id`. It does not restore ADR 0011's superseded
  projection preflight or club-membership stream routing.
- It narrows [ADR 0022](0022-use-projection-barriers-for-read-your-writes.md)
  by making the Messaging receipt, not a projection barrier, proof that
  subscription revocation completed.
- It partially supersedes the statement in
  [ADR 0024](0024-use-club-as-membership-admin-consistency-boundary.md) that
  Club is not the intended owner of arbitrary group membership. Club now owns
  first-class custom-group membership entities because actor authorization,
  target eligibility, role authority, and exact group-membership transitions
  require one serialized decision. ADR 0024's ownership of club membership,
  roles, final-member protection, Admin continuity, and derived system-group
  consequences is otherwise unchanged.

## Consequences

Removal and re-addition now have explicit identities. A stale command or
delayed follow can refer only to the membership period that authorized it, so
it cannot remove or restore a later period. Subscription revocation is one
bounded command instead of a projection-driven conversation fan-out, and its
receipt gives application flows a durable completion condition.

Keeping custom-group memberships in the Club stream makes actor and target
authorization atomic with existing club-role and membership facts. The cost is
that the Club aggregate retains the club's custom-group membership matrix and
its stream grows with those transitions. That trade-off is accepted for the
current invariants and revisited only with a migration that preserves the
first-class identities and concurrency guarantees defined here.

The member-owned Messaging stream grows with one person's subscription
history, prepared intents, and revoked membership identifiers. In return,
follow, unfollow, revocation, retry, and restart ordering is decided from one
event history without conversation enumeration.

Two explicit reconciliations and a coordinated cutover are required. They add
operational work, but preserve immutable source history, are deterministic and
restartable, and avoid asserting lifecycle periods or authorization provenance
that old facts cannot prove.
