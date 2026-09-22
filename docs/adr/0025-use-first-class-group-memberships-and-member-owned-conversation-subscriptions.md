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

- `CreateCustomGroup`, extended with caller-generated
  `creator_group_membership_id`;
- `AddCustomGroupMember`, carrying `club_id`, `group_id`,
  caller-generated `group_membership_id`, target `club_membership_id`,
  `person_id`, and `actor_person_id`;
- `RemoveCustomGroupMember`, carrying `club_id`, `group_id`, the exact
  `group_membership_id`, target `club_membership_id`, `person_id`,
  `actor_person_id`, and caller-generated `removal_operation_id`;
- `RemoveClubMember`, extended with caller-generated
  `removal_operation_id`;
- `CustomGroupMembershipStarted`, carrying those unambiguous identities, the
  admitting actor, and admission source `group_creation`,
  `explicit_admission`, or `legacy_reconciliation`; and
- `CustomGroupMembershipEnded`, carrying those identities,
  `removal_operation_id`, the removing actor when there is one, and exactly one
  of `self_left`, `removed_by_group_member`, `removed_by_club_admin`, or
  `club_membership_ended`.

All first-class admission paths follow the caller-generated typed UUID rule
from [ADR 0011](0011-use-caller-generated-uuid-aggregate-identities.md).
`CreateCustomGroup` receives `creator_group_membership_id` from its application
service at the same time as `group_id`; both identifiers are retained unchanged
across dispatch retries. Its one Club decision appends `GroupCreated`,
`GroupEmailSlugAssigned`, and `CustomGroupMembershipStarted` for the creator.
The start event identifies the creator's current `club_membership_id` and uses
admission source `group_creation`. An exact creation retry whose group,
normalized name, creator, allocated slug, and creator group-membership identity
all match emits no events. Reusing either identifier with different creation
data, including a different creator group-membership identity, is a conflict.
The creator is therefore never admitted through a later best-effort policy.

The Club aggregate enforces at most one current custom-group membership for
each `{group_id, club_membership_id}` pair. `AddCustomGroupMember` generates
its `group_membership_id` before dispatch. An exact retry for the same current
identity and the same club, group, club membership, person, and admitting actor
emits no event. Reusing that identity for different data is rejected. If the
pair already has a different current `group_membership_id`, a command carrying
a fresh identifier is rejected as a duplicate current admission; it does not
create a parallel membership and is not treated as a retry. After the current
membership ends, a genuine re-admission must carry a fresh identifier; every
ended identifier remains reserved permanently.

`RemoveCustomGroupMember` selects the first-class relationship by
`group_membership_id`, not merely by person and group. The aggregate derives
the end reason deterministically: self-removal is `self_left`; otherwise a
current group member takes precedence as `removed_by_group_member`; an actor
who is not a current group member but is a club Admin produces
`removed_by_club_admin`. An exact retry with the same
`removal_operation_id`, actor, target, and already-ended identity emits no
event. Reusing the operation identifier for different data is rejected. A
delayed retry with an old group-membership identity therefore cannot end a
newer admission.

`RemoveClubMember` is the other termination path. Extend it with a
caller-generated `removal_operation_id`. After enforcing ADR 0024's
final-member and Admin-continuity invariants, one Club decision appends one
`CustomGroupMembershipEnded` with reason `club_membership_ended` for every
current custom-group membership owned by the departing `club_membership_id`,
followed by `ClubMemberRemoved`. The events are ordered by
`group_membership_id`, and `ClubMemberRemoved` records that same operation
identifier plus the complete sorted `ended_group_membership_ids` outcome.
System-group consequences remain downstream and are not included in that set.
An exact retry of the recorded club-removal operation emits no events and
returns the previously recorded outcome through Membership's public
operation-status API; a different operation against the ended club membership
is not a second removal. Thus club departure ends zero, one, or many exact
custom-group memberships atomically without weakening the existing club or
role invariants.

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
full legacy replay proves is active at the membership reconciliation fence.
Dispatch `ReconcileLegacyCustomGroupMembership` to the Club stream with:

- `group_membership_id` deterministically derived from
  `{club_id, group_id, club_membership_id}`;
- the explicit `club_id`, `group_id`, `club_membership_id`, and `person_id`;
  and
- a deterministic reconciliation identifier equal to that source relation,
  the fence identifier, and the source Club stream version observed during
  enumeration.

The command emits `LegacyCustomGroupMembershipReconciled` and the corresponding
`CustomGroupMembershipStarted` with source `legacy_reconciliation` in one
append. The reconciliation fact means only “this relation was provably current
at the named fence”; it does not claim an admission date or synthesize earlier
membership periods. The aggregate records the deterministic identifier, so a
retry or restart emits no duplicate event. A conflicting deterministic
identity is an error rather than an overwrite.

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
- `CancelConversationSubscriptionIntent` /
  `ConversationSubscriptionIntentCancelled`;
- `EndConversationSubscription` /
  `ConversationSubscriptionEnded`;
- `RevokeGroupMembershipSubscriptions` /
  `GroupMembershipSubscriptionAuthorizationRevoked`; and
- `GroupMembershipSubscriptionRevocationCompleted`, the durable completion
  receipt.

Canonical subscription facts carry `person_id`, `club_id`, `conversation_id`,
`subscription_id`, `subscription_intent_id`, source (`manual`, `root`, `reply`,
or `legacy_reconciliation`), and the complete set of
`authorizing_group_membership_ids` resolved for custom groups. Each successful
activation also has a `subscription_authorization_id` deterministically derived
from `subscription_intent_id`; it identifies that exact canonical grant even
if a later grant makes the same deterministic `subscription_id` active again.
The facts do not use the ambiguous field `membership_id`. System-group
authorization is represented separately by `club_membership_id` and an
explicit authority kind.

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

The operation has prepare, activate, and cancel phases so delayed work cannot
undo an ordinary unfollow:

1. `PrepareConversationSubscription` persists a unique intent and its
   server-resolved authorization in the member stream. For an auto-follow it
   also records the caller-generated `message_id` that is allowed to complete
   the intent.
2. Manual follow activates that prepared intent immediately.
3. Root/reply auto-follow generates `subscription_intent_id` before either
   operation, prepares it, and puts that same identifier on `SendMessage`.
   `MessageSent` persists both `message_id` and `subscription_intent_id`.
   A strong, retrying Messaging policy dispatches
   `ActivateConversationSubscription` from that success fact. Activation must
   match the prepared intent's person, conversation, source, and expected
   `message_id`; no other success or caller assertion can activate it.
4. A durable send coordinator handles each prepared auto-follow intent. It
   dispatches the same `SendMessage` until either the matching `MessageSent` is
   committed or a terminal command rejection is known. A matching
   `SendMessage` retry is successful and event-free after its `MessageSent`;
   conflicting reuse of the message or intent identity is rejected. The
   coordinator does not acknowledge its prepared-event position until success
   exists or cancellation has committed, so a process crash resumes the same
   work rather than abandoning it.
5. On terminal send rejection, the coordinator dispatches
   `CancelConversationSubscriptionIntent` with reason `send_rejected`. That
   command appends `ConversationSubscriptionIntentCancelled`. Transient errors
   are retried and do not cancel. Because one coordinator serializes each
   intent and a matching successful send is recognized on retry, cancellation
   cannot race a successful send for that identity.
6. `EndConversationSubscription` appends
   `ConversationSubscriptionEnded` and one
   `ConversationSubscriptionIntentCancelled` with reason `unfollowed` for every
   earlier prepared intent for that conversation in the same member-stream
   append. During cutover it records the ended tombstone even when no canonical
   authorization is currently active, so stale historic reconciliation cannot
   resurrect an unfollowed conversation.
7. A delayed activation for a cancelled, ended, unknown, mismatched, revoked,
   or already-completed intent emits no event. A later explicit follow has a
   new intent and may succeed after current authority is resolved again.

Prepared, activated, cancelled, and ended intent state is rebuilt entirely
from canonical facts in the member stream after aggregate restart. Command,
policy, and coordinator retries use the same identifiers and are event-free
after the first successful transition. `MessageSent` remains a send-success
fact, not an independently interpreted follow fact; only its exact durable
correlation can request canonical activation.

### Membership revocation is one idempotent cross-context command

When `CustomGroupMembershipEnded` is committed, a strong, retrying Membership
policy sends exactly one logical `RevokeGroupMembershipSubscriptions` command
through Messaging's public API. It does not enumerate conversations. The
command carries `person_id`, `club_id`, `group_id`, `group_membership_id`, and
a `revocation_id` deterministically derived from `group_membership_id`.

In the person's subscription stream, one aggregate decision:

1. permanently records `group_membership_id` as revoked;
2. removes that identifier from every prepared and active authorization;
3. appends `ConversationSubscriptionIntentCancelled` with reason
   `authorization_revoked` for a prepared intent left with no authorization;
4. ends an active canonical grant only when it has no other current
   authorization; and
5. appends `GroupMembershipSubscriptionRevocationCompleted` with the same
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

Every `CustomGroupMembershipEnded` produces one logical revocation and one
receipt, regardless of end reason or whether any subscription used the ended
membership. `revocation_id` is deterministically derived from
`group_membership_id`, so policy redelivery does not produce a second
revocation or receipt.

The Membership removal application service may report cleanup complete only
after it observes the complete expected receipt set through Messaging's public
receipt API. For `RemoveCustomGroupMember`, operation status identifies the one
ended `group_membership_id` and the service waits for its one deterministic
`revocation_id`. For `RemoveClubMember`, the durable
`ended_group_membership_ids` on the recorded operation maps to zero, one, or
many deterministic revocation identifiers. Zero completes immediately; one or
many completes only when every exact receipt is present. Retrying either
application flow reads the same Membership operation outcome and resumes
waiting for the same set. It never enumerates conversations or derives expected
work from a projection of current memberships.

A receipt projection or subscriber may make
`GroupMembershipSubscriptionRevocationCompleted` awaitable, but the named
domain receipt is the completion evidence. Projection barriers remain limited
to coordinating visibility of selected read models.

### Reconciliation uses fenced live-write precedence

Both reconciliations use a recorded source fence and aggregate-local live-write
precedence; a paged database snapshot by itself is not a cutover protocol.

For custom-group membership, the migration coordinator first appends
`CustomGroupMembershipReconciliationFenceRecorded` to its durable migration
stream with a `fence_id` and the event-store global high-water mark. Candidate
legacy relations are derived only from source events at or below that mark.
After the fence is recorded, every product admission and removal uses the
first-class Club path. Each reconciliation command carries the fence and
observed Club stream version, but the Club aggregate revalidates the pair
against its complete current stream when the command executes:

- if the legacy relation is no longer active, the command is a no-op;
- if a canonical start, end, or current first-class membership already exists
  for the pair, that live decision wins and stale backfill cannot overwrite it;
  and
- only a still-current legacy relation with no canonical decision can append
  the deterministic reconciliation start.

A live removal encountered before its legacy pair has been materialized
atomically appends the deterministic `LegacyCustomGroupMembershipReconciled`
and `CustomGroupMembershipStarted` facts followed by the exact
`CustomGroupMembershipEnded`; it therefore leaves a canonical tombstone that a
later stale reconciliation observes. A live admission with a fresh identity
against a still-current legacy pair is rejected by the one-current-membership
invariant. If reconciliation appends first, any later live start or end is
serialized after it and naturally wins.

`CustomGroupMembershipReconciliationCheckpointAdvanced` stores each completed
page and `CustomGroupMembershipReconciliationCompleted` records exhaustion of
the fenced source. Both markers include `fence_id`. The checkpoint advances
only after every candidate in its page has reached a terminal reconciled,
suppressed-by-live-state, or inactive outcome. An identity conflict stops the
job without advancing its checkpoint. The current-state projection is rebuilt
through the same first-class facts before the legacy relation is removed from
live query paths.

Historic follow cutover follows the same shape. The coordinator first routes
all new manual, root, reply, and unfollow work to the canonical member stream;
no legacy follower writer remains enabled. It then appends
`LegacyConversationSubscriptionReconciliationFenceRecorded` with `fence_id`
and the event-store global high-water mark. A restartable scan of
`MessageSent`, `ConversationFollowed`, and `ConversationUnfollowed` at or below
that immutable prefix derives each person's provable effective follow. For
each candidate:

- use deterministic `reconciliation_id`, `subscription_intent_id`, and
  `subscription_authorization_id` values based on the historic
  person/conversation relation;
- bind custom-group authority only to exact first-class memberships that were
  current at the fence and remain current when dispatched; a later re-addition
  is not acceptable provenance for an old follow;
- re-read the relevant legacy stream through its current tail before dispatch,
  so a source fact omitted by the enumerated page cannot make a stale candidate
  look current;
- resolve those exact memberships through Membership's public contract; and
- dispatch `ReconcileLegacyConversationSubscription` to the person's stream
  with the fence, source stream version, and resolved provenance.

The member aggregate revalidates its complete stream at execution. It appends
`LegacyConversationSubscriptionReconciled` with outcome `authorized` plus
`ConversationSubscriptionAuthorized` only when the historic follow and exact
current authorization remain provable and no canonical live decision exists
for that conversation. A canonical prepare, authorization, cancellation,
unfollow tombstone, or relevant membership revocation takes precedence and
instead produces terminal outcome `suppressed_by_live_state` without
authorizing. If reconciliation authorizes first, a racing live unfollow or
revocation is serialized after it and ends it. If the live fact lands first,
the reconciliation cannot restore it. Missing or ambiguous source state and
formerly ended memberships produce terminal outcome `unproved`, never a
subscription.

`LegacyConversationSubscriptionReconciliationCheckpointAdvanced` records
completed pages and
`LegacyConversationSubscriptionReconciliationCompleted` records exhaustion of
the fenced prefix. A page advances only after all its deterministic item
markers commit. Marker and checkpoint retries are event-free, so crashes may
resume without changing precedence. After completion, live paths never scan
legacy messages or follow projections. Existing events remain replayable as
historical facts, while aggregate and projection replay derive current state
only from canonical subscription facts.

### Current authorization is required through provider handoff

A subscription is necessary for followed delivery but is never sufficient
proof of current access. Group and conversation reads, writes, follow actions,
notification creation, queued-delivery claiming, and the final email-provider
handoff recheck current authority through Membership's public contract.

Every queued private delivery captures immutable `delivery_authorization` at
the decision that emits `EmailDeliveryCreated`, and the email-delivery
projection persists the same value. It contains:

- the recipient's exact `club_membership_id`;
- authority kind `custom_group` or the explicit system-group kind;
- for custom groups, the non-empty set of exact current
  `authorizing_group_membership_ids` that made the recipient eligible; and
- for followed delivery, the exact `subscription_id`,
  `subscription_authorization_id`, and `subscription_intent_id` from the
  canonical authorization grant. Direct audience delivery leaves those three
  subscription fields absent.

Recipient resolution may capture more than one current custom-group membership
when more than one independently authorizes the conversation. The immutable
payload records the complete resolved set; it never records only a person,
conversation, or club-wide generation. Historic `EmailDeliveryCreated` events
without this payload remain readable, but private deliveries created after
cutover require it and cannot be dispatched through a compatibility fallback.

Immediately before provider handoff, the dispatcher validates the captured
authorization through public Membership and Messaging contracts. The exact
`club_membership_id` must still be current. For custom authority, at least one
captured `group_membership_id` must still be current for that same club
membership and conversation; for system authority, the captured
club-membership/system-kind pair must still apply. A followed delivery also
requires that its exact canonical `subscription_authorization_id` remains
effective with captured authorization, not merely that the deterministic
`subscription_id` is active again.

There is no fallback to a newer club membership, a new
`group_membership_id`, or a later `subscription_intent_id`. Removal followed by
re-addition therefore cannot revive old queued work: all of its captured
custom-membership identifiers are ended, and a later follow is a different
canonical authorization. If one of several captured memberships remains
current and the captured subscription grant remains effective, that surviving
authority may still permit the delivery as intended.

If an exact check fails before provider handoff, pending private delivery is
persistently skipped or made ineligible even if a lagging read model still
shows a follow. Once a provider has accepted a delivery, Memba cannot recall
it. Projection barriers may make revoked state visible to pages and tests, but
neither authorization nor delivery eligibility is inferred from barrier
completion.

## Relationship to earlier decisions

- This decision preserves [ADR 0007](0007-use-separate-membership-and-messaging-commanded-contexts.md):
  Membership owns participation, Messaging owns subscriptions and delivery,
  and their collaboration uses public contracts.
- It extends [ADR 0011](0011-use-caller-generated-uuid-aggregate-identities.md)
  with caller-generated `group_membership_id`, `removal_operation_id`, and
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
