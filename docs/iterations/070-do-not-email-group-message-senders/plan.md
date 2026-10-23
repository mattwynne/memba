# Do not email new group messages to their senders

Date: 2026-10-23
Status: validated

## Goal

When a Person starts a new group conversation, Memba creates email deliveries only for the other eligible Group members. The Sender still sees and follows the conversation but does not receive, or appear to have, a redundant delivery of their own Message.

## Background / Context

Root group Messages currently create an Email delivery for every resolved Group member, including the Sender. Replies already omit their author. The redundant root copy is visible in inboxes, addressed-recipient lists and delivery statuses.

Web composition and accepted inbound email normally converge through `SendClubMessage`, while `RequestGroupAccess` constructs an ordinary root `SendMessage` directly. Every root producer ultimately reaches the existing Messaging `Message` aggregate. Recipient candidates are fixed at posting time under ADR 0025.

## Related Problems

- [Sender receives own group email](../../problems/2026-09-03-sender-receives-own-group-email.md): expected to be resolved by this iteration for every accepted new group Message. Replies and rejected inbound attempts retain their separate existing behaviour.

## Scope

### In scope

- Omit the Sender Person from Email deliveries for every accepted new group Message, whether started on the web, by inbound email, or by an ordinary generated-message workflow.
- Apply the rule uniformly to Everyone, Admin and named Groups.
- Match the Sender by Person identity across verified email addresses.
- Keep the Message, Group access and existing follow outcome when omission leaves zero Email deliveries.
- Remove the Sender from delivery-derived addressed-recipient and delivery-status views.
- Make the web compose recipient summary count the other emailable participants, not the Sender.
- Bring existing acceptance expectations into line without adding duplicate channel- or Group-specific business examples.

### Out of scope

- Posting permission, Group participation, conversation access, authorship or follow-policy changes.
- Reply delivery changes.
- Suppressing rejection notices for inbound attempts that were not accepted as Messages.
- A delivery-skipped event, Sender delivery record, separate persisted audience list or projection migration.
- Special copy or layout for an intentionally zero-delivery Message.
- Provider dispatch/recovery changes or historical event rewrites.

## Iteration Type

Behaviour-facing. The user-observable rule changes from emailing every eligible Group member to emailing every eligible Group member except the Sender of the new Message.

## Acceptance Scenarios / Feature Files

BDD decision: **Required**.

The single stakeholder example is the existing `Alice sends a club message` scenario under the new Rule `A new group message is not emailed to its sender` in [`member_message_deliverability.feature`](../../../acceptance-tests/features/member_message_deliverability.feature). It is tagged `@iteration-070 @todo` during planning. It proves that the Message is created, only Bob, Carol and Dana are shown as addressed and emailed, and Alice has neither her own email copy nor a delivery status.

One example is intentional. The invariant is central to the `Message` aggregate, so separate Everyone/Admin/named-Group and web/email examples would duplicate the same business rule. Focused tests cover the distinct producers, Person identity and zero-delivery edge. Existing scenarios are changed only where their incidental Sender-delivery expectations would contradict the new rule.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: implement `Alice sends a club message`, remove `@todo` when its domain layer passes and retain `@iteration-070`. Add `@iteration-070` to the existing scenarios whose assertions change. In `Alice sees different statuses` and `Bob sees the same shared statuses`, remove the Sender's status while retaining different-recipient/shared-status coverage. In `Alice emails the KMC everyone address`, omit Alice from the addressed delivery recipients. In `Bob emails the KMC Admin address as an Admin member`, expect only Carol to receive the Admin email. Retain the outside-Admin sender, invalid-message and rejection-notice examples unchanged.
- `acceptance-tests/features/custom_group_conversations.feature`: add `@iteration-070` to the two changed scenarios. In the web-started Board example, keep access assertions but email only Alice and Carol. Refocus `Bob receives the ordinary recipient copy of his own Board email` to state that Alice and Carol receive the initial email, Bob does not receive his own copy, and Bob remains following. This is a coherence correction, not a second example of the rule.
- `acceptance-tests/features/group_conversations.feature`: add `@iteration-070` to `Bob starts an Admin conversation in the web app`; preserve Bob and Carol's read access while expecting only Carol's email delivery.
- `acceptance-tests/features/journeys/member_messaging.feature`: add `@iteration-070` to the existing journey and omit Alice from both root Messages' addressed-recipient lists and initial delivery statuses. Preserve the journey's web/email boundary, reply, follow and recipient-status coverage; do not add another journey.

No change is allowed to reply-author exclusion or rejected-inbound-email expectations. Existing reply and rejection examples remain non-regression coverage.

## Designs

Reuse the checked-in [`new-message.html`](../../../design-system/templates/new-message.html) and [`delivery-details.html`](../../../design-system/templates/delivery-details.html) designs. Live DesignSync was unavailable during planning; no new visual pattern or design handoff is needed because the agreed change is data-driven:

- compose recipient counts describe other emailable Group participants and exclude the current Person;
- addressed-recipient, delivery-count and delivery-status lists contain only actual Email deliveries; and
- the existing layout, responsive behaviour, focus order and accessible list semantics remain unchanged.

For a Message with zero deliveries, retain the existing empty delivery-details state and its current copy. Matt deliberately chose no special zero-delivery treatment in this slice, accepting that the existing “not prepared yet” wording is imperfect for this edge case.

## Acceptance Criteria

- An accepted root `SendMessage` never creates `EmailDeliveryCreated` for the Person identified by `sender_id`, even when the candidate uses another verified email address.
- Every other resolved candidate continues to receive one Email delivery with the existing recipient snapshot and delivery identity.
- Root candidate resolution remains fixed at posting time. Later membership or email changes do not change already-created deliveries.
- The unfiltered resolved candidate set continues to determine the existing sender-follow outcome. Sender exclusion does not change access or following.
- A root with only the Sender as candidate still emits `MessageSent` and the normal Group access event, creates zero Email deliveries and leaves the Sender following.
- A genuinely empty or unresolved root candidate set remains invalid; zero resulting deliveries does not weaken command validation.
- `RequestGroupAccess` uses the same aggregate rule. An Admin requester gets no self-delivery, including when they are the only Admin, without a generated-message exception.
- Delivery projections and recipient/status views contain no Sender row for new root Messages. Historical Sender delivery events remain replayable and visible as historical facts.
- Web compose recipient counts exclude the current Person without changing Group member counts elsewhere.
- Valid replies continue excluding their author. Rejected inbound attempts continue sending their existing rejection emails.

## Open Business Decisions

None known.

## Domain Vocabulary

Reuse the canonical terms **Person**, **Group**, **Message**, **Sender** and **Email delivery** from [`docs/problem-domain-terms.md`](../../problem-domain-terms.md). “Addressed recipients” and “delivery status” remain presentation language for actual Email delivery records, not a separate Group-audience fact.

`SendMessage`, `MessageSent`, `ConversationAccessGrantedToGroup`, `EmailDeliveryCreated`, `Message` aggregate, resolved candidate set and `RequestGroupAccess` are solution-domain terms. No vocabulary change or unresolved naming question is required.

## Domain Model

The [agreed domain model](domain-model.md) keeps the resolved root candidate set unchanged through validation and the sender-follow decision. The Messaging `Message` aggregate filters the Sender Person only when mapping those candidates to root `EmailDeliveryCreated` events. This ordering preserves following and permits a valid sole-member root to produce zero deliveries without accepting an empty command audience.

Membership owns current Group participation and supplies candidates through its public query boundary. Web, inbound email and `RequestGroupAccess` remain application-layer producers of ordinary `SendMessage`; none owns a separate suppression rule. `MessageSent` and the existing Group access fact are still emitted when the resulting delivery set is empty. No skip event or Sender delivery record is introduced.

The rule is a forward command decision. Historical events, including old Sender deliveries, replay unchanged. Recipient/status projections continue deriving from `EmailDeliveryCreated`, so they need no new state or backfill.

## Architecture Decisions

None required. The agreed model reuses:

- [ADR 0004](../../adr/0004-model-message-deliverability-as-a-message-aggregate.md): the Message aggregate owns per-message Email delivery state;
- [ADR 0005](../../adr/0005-message-send-commands-include-resolved-recipients.md): application services supply the resolved candidate set before dispatch;
- [ADR 0007](../../adr/0007-use-separate-membership-and-messaging-commanded-contexts.md): Membership supplies current people/Group facts through its public boundary and Messaging owns delivery decisions; and
- [ADR 0025](../../adr/0025-use-current-group-participation-for-access-and-delivery.md): recipients are fixed when each Message is posted.

Filtering the Sender at the existing aggregate event-emission boundary refines these accepted decisions without changing bounded contexts, aggregate ownership, event schemas or consistency boundaries.

## Implementation Plan

1. In the Messaging `Message` aggregate, retain root candidate validation and calculate `MessageSent.sender_follows_conversation` from the normalized, unfiltered candidate set. For root `SendMessage` delivery emission only, omit candidates whose `person_id` equals `sender_id`; emit the normal Message and Group access events even when no delivery events remain. Leave `PostMessageReply` validation and delivery behaviour unchanged.
2. Strengthen aggregate tests with a sender candidate using a different email address plus another recipient, proving Person-based omission, unchanged following and normal delivery to the other recipient. Cover the sole-candidate case with `MessageSent`, Group access, zero deliveries and following, while retaining rejection of a genuinely empty root candidate list. Preserve replay/application coverage for historical delivery events.
3. Update producer-level tests and expectations for `SendClubMessage` and accepted inbound roots, including a verified alternate inbound address. Update `RequestGroupAccess` coverage so an Admin requester receives no own delivery but keeps the existing follow/access result; cover the requester-as-only-Admin zero-delivery case. Keep non-Admin requester behaviour unchanged.
4. Make `MemberMessageComposeQuery` derive its displayed delivery-recipient count from emailable participants other than the current Person, without changing Group membership counts or live-query interests. Let existing delivery projections and member/staff delivery views reflect the absence of a Sender delivery; update focused query, LiveView, projection and presentation expectations rather than introducing new read state. Retain the agreed existing zero-delivery empty copy.
5. Implement the one `@iteration-070` stakeholder example and apply only the allowed coherence changes to existing feature scenarios. Add or adjust step definitions during delivery only where the agreed wording is not already executable. Run the focused domain acceptance, existing web journey and unchanged reply/rejection examples.
6. Run focused aggregate, producer, projection/query and LiveView tests, then the full `dev check` on the exact delivered state.

## Open Technical Decisions

None known. Module/helper names may follow existing conventions but must preserve the candidate-versus-delivery ordering in the agreed model.

## New Capability

Members can start Group conversations without receiving or seeing a redundant Email delivery for their own new Message, while all existing conversation access and following behaviour remains intact.

## Validation Plan

- Domain acceptance: execute the `@iteration-070` scenario and the coherently updated existing scenarios across member deliverability, custom groups and Admin web composition.
- Browser acceptance: run the existing member-messaging journey with Sender-free recipient/status lists; do not add another journey.
- Aggregate tests: prove Person-ID exclusion with an alternate address, other-recipient delivery, unchanged sender-follow calculation, sole-candidate zero delivery, non-empty candidate validation and historical event application.
- Producer tests: prove both `SendClubMessage` paths and the separate `RequestGroupAccess` path converge on the rule, including an Admin requester who is the only Admin.
- Read-side/UI tests: prove compose recipient counts exclude the current Person and delivery projections/member and staff views have no Sender receipt or status while keeping existing zero-state presentation.
- Non-regression: run unchanged reply-author exclusion and inbound-rejection-email scenarios/tests.
- Run full `dev check` on the final implementation state.

## Risks / Follow-ups

Filtering candidates before computing following would silently stop eligible Senders following their own conversations and could reject sole-member roots. Keep filtering at delivery-event emission.

The existing zero-delivery empty-state copy implies the delivery list may still be preparing. That wording is an accepted limitation for this rare edge and can be revisited separately if it causes confusion.

The internal field name `recipients` now represents the resolved candidate set before Sender exclusion. Do not expose it as a separately persisted audience fact or infer addressed-recipient UI from it; visible addressed recipients remain actual Email deliveries.
