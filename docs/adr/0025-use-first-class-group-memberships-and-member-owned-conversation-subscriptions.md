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
- `RecordRootConversationSubscriptionSkipped` /
  `RootConversationSubscriptionSkipped`;
- `EndConversationSubscription` /
  `ConversationSubscriptionAuthorizationEnded` and
  `ConversationSubscriptionEnded`;
- `RevokeGroupMembershipSubscriptions` /
  `GroupMembershipSubscriptionAuthorizationRevoked`,
  `ConversationSubscriptionAuthorizationProvenanceRevoked`, and
  `ConversationSubscriptionAuthorizationEnded`; and
- `GroupMembershipSubscriptionRevocationCompleted`, the durable completion
  receipt.

Each conversation-scoped fact carries the exact applicable subset of this
schema rather than pretending that differently scoped facts share one shape:

- `ConversationSubscriptionPrepared` carries `person_id`, `club_id`,
  `conversation_id`, `subscription_id`, `subscription_intent_id`, source
  (`manual`, `root`, `reply`, or `legacy_reconciliation`), expected
  `message_id` for auto-follow, `club_membership_id`, authority kind, and the
  complete non-empty set of server-resolved
  `authorizing_group_membership_ids` for custom-group authority.
- `ConversationSubscriptionAuthorized` carries those person, club,
  conversation, subscription, intent, source, and provenance fields plus
  `subscription_authorization_id`, deterministically derived from
  `subscription_intent_id`. It records one immutable grant, including all
  group memberships that authorized that intent.
- `ConversationSubscriptionIntentCancelled` carries the person, club,
  conversation, subscription, intent, source, expected message when present,
  immutable `club_membership_id`, authority kind and authorizing
  group-membership provenance from preparation, reason (`send_rejected`,
  `unfollowed`, or `authorization_revoked`), and the applicable
  `unfollow_operation_id` or `revocation_id`.
- `ConversationSubscriptionAuthorizationProvenanceRevoked` carries the person,
  club, conversation, `subscription_id`, `subscription_intent_id`,
  `subscription_authorization_id`, source, immutable `club_membership_id`,
  authority kind and original authorizing group-membership set of one grant,
  the exact removed `group_membership_id`, and the `revocation_id`. It never
  changes the immutable grant; replay subtracts that one provenance.
- `ConversationSubscriptionAuthorizationEnded` carries the person, club,
  conversation, `subscription_id`, `subscription_intent_id`,
  `subscription_authorization_id`, source, immutable `club_membership_id`,
  authority kind and original authorizing group-membership set of one grant,
  reason `unfollowed` or `authorization_revoked`, and the applicable
  `unfollow_operation_id` or `revocation_id`.
- `ConversationSubscriptionEnded` is the explicit-unfollow tombstone. It
  carries `person_id`, `club_id`, `conversation_id`, `subscription_id`, the
  caller-generated `unfollow_operation_id`, and the complete sorted
  `ended_subscription_authorization_ids` and
  `cancelled_subscription_intent_ids` outcome.

The membership-wide `GroupMembershipSubscriptionAuthorizationRevoked` has a
deliberately different schema: only `person_id`, `club_id`, `group_id`,
`group_membership_id`, and `revocation_id`. It is the permanent member-stream
tombstone for that group membership and does not name a conversation,
subscription, intent, or grant. The completion receipt carries that same
membership-wide schema. No fact uses the ambiguous field `membership_id`.
System-group authorization is represented separately by
`club_membership_id` and an explicit authority kind.

A stable `subscription_id` can therefore own multiple immutable authorization
grants. An exact activation retry for the same `subscription_intent_id` finds
the same deterministic `subscription_authorization_id` and emits no event. A
different successfully activated intent appends its own
`ConversationSubscriptionAuthorized` even while another grant already makes
the subscription effective. The subscription remains effective while at least
one ordered grant retains effective provenance and has not ended.
`ConversationSubscriptionAuthorized`,
`ConversationSubscriptionAuthorizationProvenanceRevoked`,
`ConversationSubscriptionAuthorizationEnded`, and
`ConversationSubscriptionEnded` are the conversation-scoped facts from which
the aggregate and current follow projection derive that state.
`GroupMembershipSubscriptionAuthorizationRevoked` prevents old provenance from
being admitted again. `MessageSent` is no longer interpreted independently as
a follow fact.

### Provenance is server-resolved and follow intent is durable

Manual follow and root/reply auto-follow use the same authoritative preparation
and activation commands, but root preparation has a different ordering because
the conversation and its access grant do not exist before the root succeeds.
Product, UI, and message callers provide intent and relevant
person/conversation identifiers; they may not provide trusted
`authorizing_group_membership_ids`, `club_membership_id`, or authority kind.
Messaging resolves the conversation's groups and current authorization through
Membership's public API, then sends trusted internal commands.

The three sequences are:

1. **Manual follow.** The application service generates
   `subscription_intent_id`, resolves current authority, and dispatches
   `PrepareConversationSubscription`. It then immediately dispatches
   `ActivateConversationSubscription` for the same intent. Preparation records
   the server-resolved provenance; activation appends its immutable grant.
2. **Reply auto-follow.** Because the conversation and its access already
   exist, the service generates `message_id` and `subscription_intent_id`,
   resolves current authority, and prepares an intent whose source is `reply`
   and whose expected message is that exact `message_id`. A durable send
   coordinator dispatches the same reply command until the correlated
   `MessageSent` commits or a terminal rejection is known. A strong, retrying
   policy activates only from that exact success correlation. Terminal
   rejection appends `ConversationSubscriptionIntentCancelled` with reason
   `send_rejected`; transient failures keep retrying.
3. **Root auto-follow.** The service generates `message_id` and
   `subscription_intent_id` but does not prepare a subscription. It sends the
   root first, carrying the intent as correlation. Server-side root audience
   resolution also puts a `sender_auto_follow_candidate` on `MessageSent`: the
   sender's exact `club_membership_id`, authority kind, and root-time
   `authorizing_group_membership_ids`, or explicit `none` when the sender was
   outside the addressed group. This is an immutable send outcome, not
   caller-supplied provenance or a follow fact. One aggregate append orders
   root `MessageSent` before its
   `ConversationAccessGrantedToGroup`; both identify the root conversation and
   the sent fact carries the intent and candidate. A durable root-follow
   coordinator consumes that exact pair only after both facts are committed,
   then verifies through Membership's public contract that the candidate's
   exact identities still provide the sender's resulting conversation
   authority. If authorized, it prepares and activates the correlated
   source-`root` intent with only that captured provenance. If the candidate is
   `none`, or its exact membership ended before preparation, it appends
   `RootConversationSubscriptionSkipped` carrying `person_id`, `club_id`,
   `conversation_id`, `message_id`, `subscription_id`,
   `subscription_intent_id`, source `root`, and reason
   `sender_not_authorized_at_root` or `authorization_ended`. The root remains
   successful but an outside-group sender gains neither conversation access nor
   a follow. A later re-add has a different group-membership identity and
   cannot satisfy the captured candidate. A rejected root emits neither root
   fact, so it leaves no prepared intent or skip fact.

The reply send coordinator does not acknowledge its prepared-event position
until the matching success or cancellation has committed. The root-follow
coordinator does not acknowledge the correlated root facts until their
activation or exact skip marker has committed. After a crash each resumes with
the same message, intent, and deterministic authorization identifiers. A
matching send or coordinator retry is event-free after its terminal facts;
conflicting reuse is rejected. No root policy may run from `MessageSent` alone
or before the root audience grant.

`EndConversationSubscription` carries caller-generated
`unfollow_operation_id`. In one member-stream append it deterministically
orders all currently effective grants by `subscription_authorization_id` and
appends one `ConversationSubscriptionAuthorizationEnded` with reason
`unfollowed` for each; orders all earlier prepared incomplete intents by
`subscription_intent_id` and appends one
`ConversationSubscriptionIntentCancelled` with reason `unfollowed` for each;
then appends `ConversationSubscriptionEnded` last. The final tombstone closes
every causally prior grant and intent even when none was active. An exact
operation retry emits no events and returns the recorded sorted outcome. A
fresh intent prepared after that tombstone may establish a new grant.

A delayed activation for a cancelled, unknown, mismatched, revoked, or
unfollow-closed intent emits no event. Activation of a valid different intent
still appends a grant when the stable subscription is already effective; it is
not collapsed into the existing grant.

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

1. appends the membership-wide
   `GroupMembershipSubscriptionAuthorizationRevoked` tombstone;
2. for each affected grant, ordered by
   `{conversation_id, subscription_intent_id,
   subscription_authorization_id}`, appends
   `ConversationSubscriptionAuthorizationProvenanceRevoked` for that exact
   grant/provenance pair;
3. appends `ConversationSubscriptionIntentCancelled` with reason
   `authorization_revoked` for each prepared intent left with no authorization;
4. appends `ConversationSubscriptionAuthorizationEnded` with reason
   `authorization_revoked` for each grant left with no effective provenance;
   and
5. appends one `GroupMembershipSubscriptionRevocationCompleted` with the same
   `revocation_id` last.

All consequences and the receipt are one atomic member-stream append. There is
one membership-wide tombstone and receipt per revocation, zero or more
conversation-scoped provenance, cancellation, and grant-end facts, and no
conversation identity on either membership-wide fact. The aggregate retains
revoked membership and completed revocation identifiers, so an exact handler
retry emits no events and an old delayed intent cannot become authorized after
restart. The receipt exists even when the ended membership authorized no
intent or grant.

The following outcomes are independent of command arrival order:

- If an old intent is authorized first, later revocation records removal of
  the ended membership from that exact immutable grant and ends the grant only
  if no effective provenance remains.
- If revocation arrives first, a later prepare or activation carrying that
  ended identifier is rejected.
- Revoking one identifier preserves any surviving provenance on the same grant
  and every separate grant authorized by another current custom-group
  membership or applicable system-group authority.
- Re-addition has a new `group_membership_id`; it does not un-revoke the old
  identifier, restore an ended grant, or make a queued delivery bound to that
  grant eligible again.
- An explicit follow after re-addition resolves the new identifier and can
  establish a new intent and immutable grant on the stable subscription.
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
that immutable prefix derives each person's provable effective follow.
`MessageSent` contributes only when its historic
`sender_follows_conversation` shape is true or defaults to true; an explicit
false is a provable no-follow and creates no candidate. For each followed
person/conversation relation:

- use deterministic `reconciliation_id`, `subscription_intent_id`, and
  `subscription_authorization_id` values based on the historic
  person/conversation relation and one exact authority provenance;
- enumerate one ordered reconciliation candidate per independently applicable
  custom-group membership or system-group authority, so each candidate grant
  has one exact provenance. Bind custom-group candidates only to first-class
  memberships that were current at the fence and remain current when
  dispatched; a later re-addition is not acceptable provenance for an old
  follow;
- re-read the relevant legacy stream through its current tail before dispatch,
  so a source fact omitted by the enumerated page cannot make a stale candidate
  look current;
- resolve those exact memberships through Membership's public contract; and
- dispatch `ReconcileLegacyConversationSubscription` to the person's stream
  with the fence, source stream version, and resolved provenance.

The member aggregate revalidates its complete stream at execution. A merely
prepared intent is not a follow decision, and cancellation reason
`send_rejected` says only that one new message did not complete. Neither may
erase a provable historic follow. The deterministic precedence is:

| Member-stream state when reconciliation executes | Item outcome | Grant result |
| --- | --- | --- |
| No effective canonical grant, tombstone, or relevant revocation; perhaps a prepared intent or `send_rejected` cancellation | `authorized` | Append the deterministic `ConversationSubscriptionAuthorized` grant. |
| An effective canonical grant already exists for the conversation | `superseded_by_canonical_grant` | Append no reconciliation grant. |
| An explicit `ConversationSubscriptionEnded` tombstone exists after canonical cutover | `suppressed_by_unfollow` | Append no grant, regardless of prepared or cancelled intents. |
| `GroupMembershipSubscriptionAuthorizationRevoked` names the historic candidate's exact group-membership provenance | `suppressed_by_relevant_revocation` | Append no grant for that provenance; a later re-add cannot substitute. |
| Revocation names no provenance used by the historic candidate | Continue normal evaluation | The unrelated revocation does not suppress an otherwise provable grant. |
| Source follow or exact fence-time/current provenance is missing or ambiguous | `unproved` | Append no grant. |

Every row appends one `LegacyConversationSubscriptionReconciled` item marker
with `reconciliation_id`, `fence_id`, person, club, conversation,
`subscription_id`, deterministic intent and authorization identifiers, exact
historic provenance, and the terminal outcome. For `authorized`, the marker and
`ConversationSubscriptionAuthorized` grant are one append. An exact item retry
is event-free.

Serialization also makes every race deterministic. If reconciliation
authorizes before a prepared live intent activates, the later different intent
adds its own grant; if that intent is rejected, its cancellation leaves the
historic grant alone. A later explicit unfollow ends all grants established
before its tombstone. A later relevant revocation ends the one historic grant
for that exact provenance; independently authorized candidate grants survive.
If activation, rejection, unfollow, or revocation lands first, the table above
decides each candidate's reconciliation result. Prepared-only and
`send_rejected` still permit authorization, while unfollow and an exact
relevant revocation prevent restoration of their affected candidates. An
unrelated revocation has no effect in either order.

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

Private delivery moves to provenance-aware dispatch through a durable cutover,
not a compatibility fallback:

1. Quiesce startup dispatch and manual retry and drain in-flight provider
   calls, so every already-provider-accepted delivery is durably distinguishable
   before the fence. Such deliveries remain accepted and are never recalled or
   reclassified.
2. Enable the writer that requires `delivery_authorization` on every new
   private `EmailDeliveryCreated`, then append
   `PrivateDeliveryAuthorizationCutoverFenceRecorded` to the Messaging
   migration stream with `fence_id` and the event-store global high-water mark.
3. Scan every private delivery created at or below the fence whose immutable
   create fact lacks exact authorization. For each delivery not already
   provider-accepted, dispatch
   `MarkLegacyPrivateEmailDeliveryIneligible` with deterministic
   `disposition_id` derived from `{fence_id, delivery_id}` to the
   delivery-owning Message stream. It appends
   `LegacyPrivateEmailDeliveryMarkedIneligible` carrying `fence_id`,
   `disposition_id`, `message_id`, `delivery_id`, `recipient_id`, and reason
   `missing_creation_authorization`. The projection's terminal status is
   `ineligible`; pending, failed/manual-retryable, and startup-recovered
   dispatching work all receive the same disposition.
4. Append `PrivateDeliveryAuthorizationCutoverCheckpointAdvanced` only after
   every item in a page is provider-accepted or has its disposition event, and
   append `PrivateDeliveryAuthorizationCutoverCompleted` after the fenced
   source is exhausted. Both carry `fence_id`. Only then enable the
   provenance-aware startup dispatcher and manual retry boundary.

The disposition event is the replayable source of terminal ineligibility, not
an update to a transient claim alone. Exact command, item, checkpoint, and
completion retries emit no duplicate event; restart resumes at the last
checkpoint. Startup dispatch refuses to claim private work until the matching
completion marker exists and, afterward, refuses any row with missing
authorization or an ineligible disposition. Manual retry applies the same
guard and returns terminal `ineligible`, including for a historically failed
delivery. Thus restart, retry, removal followed by re-addition, or current
access cannot revive an unproved legacy delivery. A provider-accepted delivery
is untouched at every step.

Every queued private delivery captures immutable `delivery_authorization` at
the decision that emits `EmailDeliveryCreated`, and the email-delivery
projection persists the same value. It contains:

- the exact `person_id`, `club_id`, and `conversation_id`;
- the recipient's exact `club_membership_id`;
- authority kind `custom_group` or the explicit system-group kind;
- for custom groups, the non-empty set of exact current
  `authorizing_group_membership_ids` that made the recipient eligible; and
- for followed delivery, one exact `subscription_id`,
  `subscription_authorization_id`, and `subscription_intent_id` from the
  canonical immutable grant plus that grant's captured membership
  authorization. Direct audience delivery leaves those three subscription
  fields absent.

Direct audience resolution captures the complete current custom-group
membership set when more than one membership independently authorizes the
conversation. Followed resolution selects the earliest still-effective grant
by member-stream event position and captures that exact grant's still-effective
membership provenance; it does not add authority that the grant never contained
or fall through to another grant after creation. The immutable payload never
records only a person, conversation, or club-wide generation. Historic
`EmailDeliveryCreated` events without this payload remain readable, but private
deliveries created after cutover require it and cannot be dispatched through a
compatibility fallback.

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
`group_membership_id`, a later `subscription_intent_id`, another grant on the
same stable `subscription_id`, or merely effective subscription state. Removal
followed by re-addition therefore cannot revive old queued work: all of its
captured custom-membership identifiers are ended, and a later follow is a
different canonical authorization. If one of several memberships captured on
that exact grant remains current and the same grant remains effective, that
surviving provenance may still permit the delivery as intended.

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

Two explicit reconciliations, one private-delivery disposition sweep, and their
coordinated cutovers are required. They add operational work, but preserve
immutable source history, are deterministic and restartable, and avoid
asserting lifecycle periods or authorization provenance that old facts cannot
prove.
