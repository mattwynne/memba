# Iteration 066 — domain model

Agreed model for the re-planned iteration 066. Matt requested this plan be submitted for delivery after reviewing the command, email link and GET route.

## Concepts

- **Club member** asks to join a **Group**, such as Board.
- **Admin Group** receives an ordinary **Message** identifying the member and group.
- An authorised member adds the requester using the existing membership operation.
- The request has no identity or lifecycle separate from the message. Its link is message content, not a new domain action or permission.

## Responsibilities

| Owner | Responsibility | Collaborators |
| --- | --- | --- |
| Membership | Decide current club membership, group ownership, group participation and authority to add members. Apply the existing addition operation. | Existing Club write model and public Membership APIs. |
| Messaging | Handle the composite command `RequestGroupAccess`: validate the authenticated requester and target with Membership, compose the fixed message and link, then dispatch existing `SendMessage`. Deliver the ordinary message. | Membership through its public APIs; existing Message and delivery pipeline. |
| Member application | Dispatch the request command with authenticated context, display request feedback, open the targeted Members page, and dispatch the existing addition command on explicit confirmation. | Messaging for the request; Membership for confirmation. |
| Message presentation | Render the body’s management link as a styled email button and supply a plain-text link. Preserve safe treatment of member-authored content. | Existing email rendering and group-member URL helpers. |

The existing internal `custom_group` names remain implementation vocabulary. This iteration does not rename established APIs or change aggregate boundaries.

## Commands and facts

### Ask to join Board

The member application dispatches the composite command `RequestGroupAccess` with the authenticated requester, club and target group. It expresses Eve’s intent and is handled in the Messaging application layer before dispatching its constituent `SendMessage` command to the existing Message aggregate; it is not a separately persisted request aggregate. The browser cannot supply a different sender, destination, subject or body.

Membership supplies the authoritative eligibility facts: the requester is currently active in that club; Board exists in that club and is not a built-in group. Messaging composes the fixed body, including the ordinary member-management link with the requester selected. The destination is that club’s Admin Group, resolved server-side.

The `RequestGroupAccess` handler dispatches its constituent `SendMessage` with the resolved recipients and returns that dispatch outcome. Existing `MessageSent` and delivery events record the message and its email deliveries. No new request event, aggregate, status or approval record is introduced. Existing recipient-based sender-follow behaviour remains unchanged, including where a requester already belongs to Admin.

Use the existing stable authorization checkpoint pattern when handling `RequestGroupAccess`. A club departure observed before the successful checkpoint rejects the send; a later departure can race with an already-authorised send, just as with existing Messaging operations. Do not introduce a distributed transaction between Membership and Messaging.

### Open the email link

The email button and plain-text body both link to `/groups/:group_id/members/add/:person_id` on the club site. This GET page shows the identified person ready to add to the identified group; it is not an endpoint that adds anyone. Require sign-in and current permission to manage that group before showing person or group details. Resolve the target’s current active club membership server-side. The URL carries identities, not authority; opening it emits no membership command or event. Reuse ordinary Members-page presentation and the explicit Add action.

### Add Eve to Board

The member application resolves the selected person’s current active club membership through Membership’s public API. Explicit confirmation on the targeted page dispatches the existing addition command with the current authenticated actor, club, group, person and club-membership identity. The Club write model validates that current membership/person pair and the actor’s authority before applying the existing addition decision. Reuse the existing application addition flow, including its welcome-email follow-up after an actual admission; that follow-up is not automatically triggered merely by emitting `GroupMemberAdded`. An already-active membership is a no-op and sends no new welcome email.

## State and timing

- Before the ask, Eve is outside Board. After message acceptance, she remains outside Board; only an ordinary Admin conversation has been created.
- “Your request has been sent” means the message was accepted. Provider delivery is asynchronous; acceptance does not promise email receipt or reading.
- Recipients are fixed by the existing message-posting rules. Later role changes do not cancel deliveries already created.
- If Dan adds Eve before Alice acts, Alice sees that Eve is already a member. Simultaneous confirmations still use existing duplicate-add protection.
- If Eve leaves the club or the actor loses authority before confirmation, the addition is refused by existing membership rules. The link does not preserve old authority.
- A later deliberate ask is another ordinary message, not an update to a pending request. Existing send identity/retry semantics remain intact; no deliberate-request deduplication is added.
- An old message remains historical correspondence. It is not a current approval or a grant of membership.

## Change from today

Add the `RequestGroupAccess` command and its fixed-message handling, safe body-link presentation and targeted Members-page navigation/feedback. Reuse current message storage, delivery, access, membership and welcome behaviour. Do not widen general non-member composition, replies, following or group access.

## Architecture

The proposed model reuses accepted ADRs [0005](../../adr/0005-message-send-commands-include-resolved-recipients.md), [0007](../../adr/0007-use-separate-membership-and-messaging-commanded-contexts.md), [0023](../../adr/0023-use-url-addressable-liveview-state.md), [0024](../../adr/0024-use-club-as-membership-admin-consistency-boundary.md) and [0025](../../adr/0025-use-current-group-participation-for-access-and-delivery.md). No new domain-model ADR is currently proposed.

## Email link presentation

Keep the normal member-management URL in the stored plain-text message body. It identifies the group and person to show on the Members page. The plain-text email includes that URL; the HTML renderer displays it as a styled link using the existing button helper.

Recognise and validate the member-management URL itself, not a request subject or prose. Escape surrounding text and the link label; validate the application origin and route before rendering the link. Styling conveys no authority or proof of system authorship. Ordinary links to the same destination can receive the same presentation. Existing sign-in and membership checks protect the destination.

No separate HTML body, action metadata, special link syntax or general rich-text support is needed.

## Review status

Review of the revised command and GET route (`thr_gptpwiskik`) confirmed the route's read-only/authorization boundary and identified ambiguity about where the composite command is handled. The model now places `RequestGroupAccess` in the Messaging application layer, with only `SendMessage` dispatched to the existing aggregate. Matt selected “composite command” as the local name for this composition, which currently contains one constituent command. No multi-family consensus is claimed. Matt reviewed the resulting command flow and GET route before requesting delivery.

## Out of scope

Tracked applications, approval/decline status, general replies to outside senders, new membership rules, request-specific failure infrastructure, provider recovery changes and global message-format redesign.
