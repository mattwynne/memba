# Admin group email conversations

Date: 2026-09-03
Status: ready

## Goal

Make the Admin system group a private, email-only conversation audience at
`admin@<club-slug>.clubs.memba.io`.

An active club member can start an Admin conversation by email. Only active Admin
members receive it, can read it, and can reply by email. Existing web conversation
views remain Everyone-only for every member.

## Background / Context

The groups vision introduces groups as club-scoped conversation audiences. Iteration
056 establishes the event-sourced Everyone and Admin system groups, group membership,
and conversation-to-group access grants without changing visible behaviour. This
iteration makes the existing Admin audience useful while deferring group presentation
and web composition.

This plan records a confirmed clarification to the current vision: active club
members may start a new group conversation by email even if they are not members of
the addressed group. They receive neither conversation access nor follow-up email.
Only group members can read or reply. The vision document must be updated separately
before delivery.

## Related Problems

- [`docs/problems/2026-06-02-send-club-message-by-email.md`](../../problems/2026-06-02-send-club-message-by-email.md): **extends its resolution.** The existing Everyone inbound-email capability becomes group-addressable, starting with Admin.
- [`docs/problems/2026-06-04-rejected-inbound-emails-not-visible.md`](../../problems/2026-06-04-rejected-inbound-emails-not-visible.md): **intentionally unresolved.** Rejected group emails remain auditable but gain no staff or club inbox.
- [`docs/problems/2026-09-03-sender-receives-own-group-email.md`](../../problems/2026-09-03-sender-receives-own-group-email.md): **intentionally unresolved.** An Admin sender continues to receive the ordinary recipient copy of their own root email in this slice.

## Scope

### In scope

- Depend on iteration 056 being completed, merged, and available to the delivery run.
- Give each group an immutable, normalised email slug, unique within its club. The
  initial system-group slugs are `everyone` and `admin`.
- Backfill email-slug facts/read models for system groups created before this release,
  and assign the slug whenever a new system group is created.
- Resolve `<group-slug>@<club-slug>.clubs.memba.io` to its club and group. Preserve
  `everyone@<club-slug>.clubs.memba.io` unchanged and add
  `admin@<club-slug>.clubs.memba.io`.
- Apply one fixed group-email posting policy: an active member of the destination club
  may start a new conversation for any addressable group. Do not persist or expose
  policy configuration in this slice.
- Deliver a new Admin conversation only to active Admin-group members, and grant that
  group write access. Write includes read and reply rights.
- A sender outside Admin receives no outbound copy, acknowledgement, conversation
  access, or reply email. They do not automatically follow the conversation.
- Let active Admin-group members use the existing reply-by-email path for an Admin
  conversation. Preserve current follower-only reply delivery.
- Provide group-ID-based Messaging queries for listing and reading conversations
  accessible through a group. Current web surfaces continue to call those queries for
  Everyone only; no Admin conversation appears in the web UI yet.
- Preserve current rejection rules for unknown, inactive, and other-club senders, plus
  attachments and unusable plain-text bodies.

### Out of scope

- Showing groups, group addresses, or Admin conversations in the web app.
- Web composition or posting to a group.
- Configurable `public`, `club_members_only`, or `group_members_only` posting policies.
- Custom-group creation, management, and public email addresses beyond the slug model
  needed for future routing.
- Shared conversations, public reading, visibility defaults, and access changes after
  a conversation starts.
- Suppressing the normal root-message email to a sender who is also in the addressed
  group.
- A rejected-inbound inbox, moderation workflow, or sender confirmation email.

## Iteration Type

Behaviour-facing. The changed rule is: an active club member may start a private Admin
conversation by email, while only active Admin-group members receive, read, and reply
to it.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.** The slice changes inbound authorisation, recipient
privacy, conversation access, and email replies. The examples make the exception for
a non-Admin sender and the continuing Admin reply rule explicit.

Planning adds future-facing scenarios tagged `@iteration-057 @todo-domain @todo-ui`:

- `acceptance-tests/features/member_message_deliverability.feature`
  - an active KMC member outside Admin emails `admin@kmc.clubs.memba.io`; active Admin
    members receive the message, while the sender receives no copy or access and no
    web view exposes it;
  - an active Admin member emails the same address; active Admin members, including
    the sender, receive it;
  - an active member of another club is rejected.
- `acceptance-tests/features/club_message_replies.feature`
  - an active Admin member replies by email to an Admin conversation; the reply joins
    that conversation and follows the existing follower-delivery rule.

The `@todo-domain` and `@todo-ui` tags exclude these scenarios from their respective
runners until delivery supplies the required application and step support. Matt must
review the scenario language as domain language before the plan is treated as final.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: add the three
  Admin inbound-email scenarios above; during implementation, replace or narrow the
  runner-debt tags only as supporting domain/browser coverage becomes executable.
- `acceptance-tests/features/club_message_replies.feature`: add the Admin reply-by-email
  scenario above; during implementation, replace or narrow the runner-debt tags only
  as supporting domain/browser coverage becomes executable.

Existing Everyone inbound-email and reply scenarios remain coverage for the unchanged
club-wide behaviour.

## Designs

No design needed. This iteration changes neither a screen nor a rendered email
surface: it reuses existing message and reply emails, adds no address disclosure, and
keeps all web conversation surfaces bound to Everyone. The Claude Design group display
and web-compose design is a later iteration's input.

## Acceptance Criteria

- Every group has a club-unique immutable email slug; Everyone and Admin use
  `everyone` and `admin` respectively.
- `admin@<club-slug>.clubs.memba.io` resolves to the destination club's Admin group.
- An active member of that club may begin an Admin conversation by email whether or
  not they belong to Admin.
- An accepted Admin conversation has exactly an Admin write-access grant on creation;
  the root-email delivery audience is the active Admin group only.
- A non-Admin sender receives no root-message delivery, acknowledgement, access, or
  later reply delivery, and is not made a conversation follower.
- An Admin sender receives the normal root-message delivery in this slice; the known
  redundant-copy problem remains deferred.
- An active Admin member can reply by email to an Admin conversation. A non-Admin has
  no reply right through that conversation.
- Unknown, inactive, and other-club senders, unsupported attachments, and unusable
  plain-text bodies retain their existing rejection outcomes.
- Existing web list/detail queries remain Everyone-only, while a public Messaging API
  can list/read conversations by a supplied group ID for the later group UI.
- Existing Everyone inbound-email, reply threading, follower-only reply delivery, and
  delivery behaviour remain unchanged.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed and deferred:

- The current fixed policy is `club_members_only`: active members of the destination
  club can start a new conversation by email.
- Future policies may include `public` and `group_members_only`, but are not stored or
  configurable in this iteration.
- The sender-receives-own-root-email problem is deferred as documented in the related
  problem note.

## Implementation Plan

1. Verify iteration 056's group membership, system-group IDs, conversation access
   grant, public Membership queries, release backfill, and group-aware reply
   authorisation are implemented and passing before starting this plan. Do not recreate
   that foundation in 057.
2. Extend the Membership group write model, events, state, and projections with an
   immutable normalised email slug, unique per club. Evolve new-group creation to carry
   it, and append idempotent email-slug facts for existing Everyone and Admin groups
   without rewriting historic group events.
3. Make new-club system-group creation and the release backfill assign `everyone` and
   `admin` consistently. Expose a public Membership lookup by club and group email
   slug; Messaging must not query Membership schemas directly.
4. Generalise inbound destination resolution from the hard-coded `everyone` local part
   to a group-slug lookup on the existing `<club-slug>.clubs.memba.io` host. Keep
   unsupported routes and unknown club/group slugs on the existing rejection path.
5. Introduce a named fixed group-email posting policy in Messaging. For a new inbound
   conversation it authorises the resolved sender by active membership of the
   destination club, not membership of the addressed group. Do not add a stored policy
   value, policy editor, or policy-specific UI.
6. Carry the resolved audience group through the existing inbound root-message command.
   Resolve deliveries through active group members and emit the group write-access grant.
   If the sender is not a recipient, do not create a delivery, acknowledgement, access,
   or follower relationship for them.
7. Reuse the group-write reply authorisation delivered by 056 for Admin conversations.
   Keep header routing and follower-only reply delivery unchanged; cover direct/forged
   non-member reply attempts with focused domain tests rather than a new stakeholder
   scenario.
8. Add public Messaging queries that list conversations and read a conversation through
   a supplied group ID and its access grant. Refactor current web query callers to pass
   the Everyone group, preserving the existing visual UI and ensuring Admin
   conversations remain absent until the later group display iteration.
9. Add aggregate, policy, projection/replay, release-backfill, inbound-route,
   authorisation, recipient-delivery, sender-non-following, and reply-authorisation
   tests. Cover slug uniqueness and safe re-runs of the slug backfill. Keep existing
   Everyone acceptance regressions passing.
10. Implement the accepted scenarios' domain and browser support, removing or narrowing
    `@todo-domain` / `@todo-ui` only when each runner can execute the relevant scenario.
    Run `dev check`.

## Open Technical Decisions

None expected to block implementation.

- The email slug is an immutable routing key, distinct from a group display name and
  from the deterministic internal system-group identity.
- The initial policy is a fixed named policy boundary, not a persisted group setting.
- Existing email idempotency remains keyed by provider/message identity; the new group
  lookup must not turn provider retries into duplicate conversations or deliveries.

## New Capability

Clubs can use an Admin email address for private Admin conversations. Any active member
can contact the Admin group by email, while only its active members receive and reply to
the conversation. The domain and read APIs are ready for a later UI to list a selected
group's conversations without changing the underlying access model.

## Validation Plan

- Before implementation, run the acceptance configuration tests to confirm the new
  `@todo-domain` / `@todo-ui` scenarios are excluded from their respective default
  runners.
- During implementation, run focused Membership tests for slug persistence, uniqueness,
  backfill, and replay; focused Messaging tests for group destination resolution,
  recipient delivery, sender policy, access grants, and reply authorisation; and the
  existing inbound-email/reply regressions.
- Exercise realistic inbound payloads for Admin messages from an active non-Admin,
  active Admin, inactive sender, other-club sender, and duplicate provider message.
- Confirm group-ID-based Messaging queries return only the requested group's accessible
  conversations and that existing web surfaces request Everyone.
- After step support is complete, remove/narrow runner-debt tags and run the affected
  Cucumber features.
- Run `dev check` on the committed implementation state.

## Risks / Follow-ups

- Iteration 056 is a hard dependency and must be merged before this plan can start.
- The current Groups vision says non-members cannot post to group addresses. Update it
  before delivery to reflect the confirmed `club_members_only` new-conversation rule.
- An email slug becomes externally visible and should be treated as stable once used;
  group rename/slug-change policy is deferred.
- The email sender who is also an Admin receives a redundant root-message copy. This is
  deliberately deferred in the related problem note.
- The current app must not accidentally expose Admin conversations while its views stay
  Everyone-only; the generic group-ID query is preparation, not UI exposure.
