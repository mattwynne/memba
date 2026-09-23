# 25. Use first-class group memberships and person-owned conversation subscriptions

Date: 2026-09-23

## Status

accepted

## Context

A club membership is a person's enduring relationship with a club. A group
membership is a separate relationship with one group. The reusable active flag
used by legacy group relations cannot identify which group relationship
authorized a conversation subscription. Conversation-by-conversation cleanup
can therefore race delayed follow work, retries, re-addition, and projection
rebuilds.

Iteration 064 requires group departure to end access and future delivery without
changing club membership or club roles. Rejoining must not restore old follows,
while access authorized independently through another current group membership
must survive. Projection barriers cannot prove that this domain work completed;
they prove only read-model visibility.

## Decision

### Model club membership and group membership separately

`ClubMembership` is the enduring club relationship. Its
`club_membership_id` is the existing durable `membership_id` from ADR 0024 and
current club events, renamed only at new boundaries to remove ambiguity. It is
not a second identity and its UUID is never translated or regenerated. New
commands and events use `club_membership_id`; additive adapters map legacy
`membership_id` fields to that same value. Readers accept either field during
migration and reject payloads that contain unequal values in both.

`GroupMembership` is one uninterrupted relationship between that
`ClubMembership` and a group. Every admission creates a new
`group_membership_id`; ending and later rejoining never reuses an ended
identity.

The club/group domain in `Memba.Membership` owns the `GroupMembership`
lifecycle. Messaging owns conversation subscriptions and delivery. A group
write is serialized in the group consistency boundary, routed by `group_id`,
and uses this minimum vocabulary:

- `StartGroupMembership` emits `GroupMembershipStarted` with `club_id`,
  `group_id`, `club_membership_id`, `person_id`, and a caller-generated
  `group_membership_id`.
- `EndGroupMembership` names the exact `group_membership_id` and emits
  `GroupMembershipEnded` with an idempotency key and reason.

At most one current `GroupMembership` exists for a
`{group_id, club_membership_id}` pair. An exact retry emits nothing. Reusing an
identifier or idempotency key for different data is rejected. A delayed command
naming an ended group membership cannot affect a later group membership.
Self-departure, authorized removal, and club departure all end exact current
group memberships; none changes the associated `ClubMembership` except the
existing club-departure operation itself.

When one operation ends several group memberships, a durable club/group-domain
coordinator dispatches the exact end commands in ascending
`group_membership_id` order and records the sorted outcome. Retry resumes that
same list without repeating completed decisions. Existing club-role,
last-Admin, system-group, and custom-group authorization rules remain in force.

### Store subscriptions in a person's Messaging stream

Messaging stores all conversation subscription changes for one person in a
stream routed by `person_id`. A subscription is identified by
`{person_id, conversation_id}` and can contain independent authorization
grants. A custom-group grant names exactly one `group_membership_id`; therefore
one conversation subscription can have grants from several current group
memberships.

Use this compact command/event vocabulary:

- `BeginConversationSubscriptionIntent` emits
  `ConversationSubscriptionIntentStarted` with a caller-generated
  `subscription_intent_id`, source `manual`, `root`, or `reply`, and the exact
  server-issued `authority_decision_id` bound at initiation. The decision's
  immutable result names the club membership and complete sorted set of group
  memberships available to that intent.
- `AuthorizeConversationSubscriptionIntent` uses only that bound decision and
  emits one `ConversationSubscriptionAuthorizationGranted` per still-valid
  authorizing group membership named by it.
- `UnfollowConversation` cancels every earlier open intent, ends every earlier
  grant, and emits `ConversationSubscriptionEnded` last in one append.
- `RevokeGroupMembershipSubscriptions` emits
  `GroupMembershipSubscriptionRevocationRecorded`, zero or more
  `ConversationSubscriptionAuthorizationRevoked` facts, and finally
  `GroupMembershipSubscriptionRevocationCompleted`.

For manual follow and reply auto-follow, Messaging obtains one canonical
authority decision at initiation and records that decision and the intent in the
person's stream before asynchronous authorization or send coordination. Reply
authorization runs only after the correlated send succeeds; terminal send
failure cancels the intent.

Root creation is different because the conversation does not yet exist. The
successful root operation resolves the sender against the root's canonical
audience and records the exact server-issued authority decision with the root
success fact. The root operation retains the same `authority_request_id` and
decision across command retries. If its append conflicts before success, it
revalidates that exact decision and succeeds only if the named authority remains
current; it never resolves replacement authority. The root-follow coordinator
may begin an intent only from the correlated success fact and binds the intent
to that recorded decision. It never asks what authorizes the conversation at an
arbitrary later state. A rejected root creates no subscription intent; a
successful root with no sender authority records no authorizable intent.

An authorization command must name an existing, still-open intent and its
original decision. Before granting, the club/group domain validates the exact
`club_membership_id` and `group_membership_id` values named by that decision;
it never substitutes newer group memberships. Because unfollow and
authorization are serialized in the same stream, an unfollow defeats delayed
work for every intent started before it. A genuinely new follow starts a fresh
intent with a fresh server decision after the unfollow fact and can succeed.

Product, UI, and message callers may supply intent plus relevant
person/conversation identifiers and `subscription_intent_id`; they may not
supply `authority_decision_id`, `group_membership_id`, `club_membership_id`, an
authority kind, or any other trusted authorization provenance. Messaging
obtains and binds those values server-side.

A granted fact carries `person_id`, `conversation_id`, a stable
`subscription_id`, `subscription_intent_id`, `authority_decision_id`, a unique
`authorization_id`, and its exact bound authority. Grant facts, rather than
`MessageSent` alone or a follow projection, are the canonical subscription
source. Retries retain their intent, decision, and authorization identities;
exact retries emit nothing, and conflicting reuse fails. A delayed
authorization for a cancelled intent, or one whose bound club membership or
group membership has ended or been revoked, is rejected. Departure followed by
re-addition cannot satisfy the old decision because the new group membership
has a different identity.

A subscription is effective while at least one grant remains effective and its
recorded authority is current. Ending one group membership revokes only grants
that name that exact identity. Grants from other current group memberships are
unchanged. A later group membership has a new identity, cannot un-revoke an old
grant, and cannot reactivate a subscription ended by ordinary unfollow. A new
explicit follow can create new grants.

### Make revocation durable and order-independent

A durable, retrying policy maps each `GroupMembershipEnded` to one
`RevokeGroupMembershipSubscriptions` command. Its `revocation_id` is derived
from `group_membership_id`. Messaging handles the command in the person's
subscription stream as one atomic append:

1. record the group-membership-wide revocation tombstone;
2. revoke affected grants in ascending `{conversation_id, authorization_id}`
   order; and
3. append the durable completion receipt last, including the same
   `revocation_id`.

The receipt is written even when no subscription used the ended group
membership. The tombstone makes revocation win whether stale follow work
arrives before or after it. Replaying the stream reconstructs the same result,
and exact command or policy retries emit no duplicate facts.

A removal operation reports subscription cleanup complete only after the
expected `GroupMembershipSubscriptionRevocationCompleted` receipt or receipts
exist. Projection barriers may then coordinate page or test visibility, but are
not authorization or completion evidence.

### Decide current authority from canonical histories

Subscription authorization and provider handoff use a public, decision-level
club/group-domain contract, never a projection query. Messaging supplies the
conversation's canonical group identifiers from its command-side history and a
unique `authority_request_id`. The club/group domain evaluates the relevant
`ClubMembership` and `GroupMembership` event histories at one event-store
position and durably records `ConversationAuthorityDecided` keyed by the
request. The result contains that position, the unchanged `club_membership_id`,
and the complete sorted set of authorizing `group_membership_id` values.
Retries of the same request return the recorded decision; reuse with different
input fails.

That event-store position is the authorization linearization point. A group
departure ordered before it is observed; one ordered after it is handled by
normal revocation and is considered to have raced after the authorized action.
Subscription initiation keeps this original decision permanently, including
while appending its intent. Retry or append conflict revalidates and reuses it,
appending each bound grant only if that exact authority remains current;
otherwise that grant is rejected. Subscription work never obtains replacement
authority from newer group memberships. Provider
handoff has no durable intent to preserve: an append conflict there obtains a
fresh final authority decision before any external call. No projection barrier,
projected active flag, or cached answer can satisfy this contract.

### Recheck delivery authority and record provider acceptance

Conversation reads, writes, follow actions, delivery creation, queued-delivery
claiming, and the final provider handoff recheck current authority. A queued
private delivery records the exact club membership, group-membership grant or
grants, and subscription authorization that made it eligible. Re-addition or a
new follow cannot make an old queued delivery eligible.

The current `Memba.Messaging.EmailDeliveryProvider` port returns only `:ok` or
an error, and the Postmark and Resend adapters in ADR 0016 use Swoosh; they do
not promise provider idempotency, lookup, or a durable provider reference. The
port is extended narrowly so each adapter classifies a call as
`{:accepted, receipt_or_nil}`, `{:not_accepted, reason}`, or
`{:unknown, reason}`. `accepted` means the synchronous adapter call reported
handoff success; a receipt is optional. Any response or exception that might
have occurred after provider acceptance is `unknown`, not safely retryable.

After a positive canonical authority decision and immediately before the
external call, Messaging appends `EmailDeliveryHandoffStarted` to the
delivery-owning stream. A returned `accepted` result appends
`EmailDeliveryProviderAccepted`; a certain rejection appends
`EmailDeliveryHandoffRejected`; an ambiguous result appends
`EmailDeliveryHandoffUncertain`. If the process crashes after the provider may
have accepted but before a result fact, replay sees the started fact without a
terminal fact and classifies it as uncertain, never pending.

An uncertain handoff is not automatically or manually resent through the same
operation unless that configured provider offers an explicitly implemented
idempotent-retry or reconciliation capability. The current Postmark/Resend
Swoosh ports are not assumed to offer one. A later authenticated webhook or
operator reconciliation may append the accepted or rejected resolution;
otherwise the handoff remains uncertain. This does not claim exactly-once
provider acceptance. It chooses possible non-delivery over an unbounded
post-crash duplicate.

Projections derive started, accepted, rejected, and uncertain states only from
those canonical facts, so rebuild cannot turn handed-off work back into pending
work. Provider-accepted delivery is not recalled when authorization later
ends. For a delivery batch, decide and dispatch in ascending `delivery_id`
order. A negative authority decision records an ineligible fact and makes no
provider call.

### Reconcile legacy state at explicit fences

Migration is additive and staged:

1. Deploy tolerant aggregate and projector readers for legacy and new facts,
   including the `membership_id` to `club_membership_id` identity mapping.
2. Close a short group-write gate, drain in-flight legacy group commands and
   their policy writes, record a group-membership reconciliation fence after
   the last possible legacy write, switch product routing to first-class
   commands, and reopen the gate. No legacy group writer runs after the fence.
3. Until reconciliation completes, group command-side readers fold both the
   fenced legacy relation facts and first-class facts. A live removal of an
   unreconciled active relation atomically materializes its deterministic
   `GroupMembershipStarted` and then `GroupMembershipEnded`; a live admission
   cannot bypass an active legacy relation. Thus a write after the fence is
   neither lost nor resurrected by backfill.
4. Reconcile each relation proven active at the fence, deriving
   `group_membership_id` from `{club_id, group_id, club_membership_id}`. The
   idempotent command rechecks the combined command-side history: a later
   first-class start/end wins, otherwise it appends `GroupMembershipStarted`.
   Inactive or ambiguous relations create nothing. This establishes current
   state only; it does not invent historical intervals or rewrite legacy
   events.
5. Stop legacy follow writers, drain their in-flight work, route all new manual,
   root, reply, and unfollow work through the person stream, then record the
   conversation-subscription cutover fence. For each effective legacy follow,
   the canonical authority contract resolves **all** group memberships that
   authorize that conversation at the fence. Messaging binds the deterministic
   reconciliation intent to that decision and atomically appends the sorted
   grant set plus one reconciliation marker. This is a new authorization
   decision at cutover, not a claim about historical causality. No current
   authority means no grant, a later canonical unfollow prevents stale
   reconciliation from restoring it, and retry never substitutes post-fence
   authority.
6. Rebuild projections from canonical facts. Enable provider dispatch only
   after every known provider-accepted legacy delivery has a canonical
   acceptance fact and every excluded legacy delivery has a canonical
   ineligible fact.

Reconciliation work is ordered by `{person_id, conversation_id}`; grant sets
within an item are ordered by `group_membership_id`. Each item has a
deterministic reconciliation key and marker. A checkpoint advances only after
all earlier ordered items have a terminal marker, so retry and restart repeat
no decisions and skip no items. Live writes and reconciliation serialize in
the same owning stream; whichever commits first is visible to the later
decision.

Legacy events remain immutable and readable. Compatibility handlers and old
event shapes are retained additively. Removing old command paths, event
modules, or compatibility readers is deferred until a separately reviewed
migration proves they are no longer required.

## Invariants

- One current `GroupMembership` exists at most per group and club membership;
  every rejoin uses a fresh identity.
- Group departure never ends club membership or changes club roles.
- `club_membership_id` and legacy `membership_id` always denote the same durable
  club membership identity.
- Product callers never assert trusted subscription provenance.
- Explicit unfollow defeats every earlier subscription intent; only a later
  intent with its own server-bound authority decision can establish new grants.
- A subscription intent can use only the exact authority bound at initiation;
  retry, delay, re-addition, or append conflict cannot replace it.
- Every effective custom-group subscription grant names an exact, current group
  membership when granted.
- Revoking one group membership cannot revoke an independent grant.
- An ended group membership can never authorize new work, including after
  replay, retry, or re-addition.
- Every processed group-membership revocation ends with one durable completion
  receipt in the person's Messaging stream.
- Provider handoff state is canonical and replayable; accepted or uncertain
  work is never reconstructed as pending.

## Relationship to earlier decisions

This preserves [ADR 0007](0007-use-separate-membership-and-messaging-commanded-contexts.md):
the club/group domain and Messaging collaborate through public contracts. It
narrows [ADR 0022](0022-use-projection-barriers-for-read-your-writes.md): a
projection barrier proves visibility, while the Messaging receipt proves
revocation completion. It completes the open group-consistency choice in
[ADR 0024](0024-use-club-as-membership-admin-consistency-boundary.md) without
moving conversation subscriptions into the club/group domain.

## Consequences

Exact group-membership identities remove ambiguous reactivation and stale-work
races. Person-owned subscription streams make follow, unfollow, revocation,
retry, and replay ordering explicit without correctness depending on a
conversation projection scan. Durable receipts give callers a precise
completion condition, and canonical provider-handoff facts make delivery
rebuild-safe without promising exactly-once provider acceptance.

The costs are longer person streams, cross-context authorization lookups, an
additive migration, and final authority checks at provider handoff. One
person's revocation work is serialized, which favors correctness over parallel
fan-out. Historical events and compatibility paths remain until later work can
retire them safely.
