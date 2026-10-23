# Iteration 070 — domain model

Agreed model for omitting a new group message's sender from its email deliveries.

## Problem-domain concepts

- A **Person** sends a new **Message** to a **Group**.
- The sending Person is the **Sender**, regardless of which verified email address they used.
- An **Email delivery** exists only for a Person who should receive an email copy of that Message.
- The Group remains the Message's audience and access boundary. Omitting the Sender's Email delivery does not remove authorship, Group participation, conversation access, or following.

`SendMessage`, `MessageSent`, `ConversationAccessGrantedToGroup`, `EmailDeliveryCreated`, `Message` aggregate and `RequestGroupAccess` are solution-domain names for the existing implementation model.

## Lifecycle and invariants

When a new group Message is accepted, Membership supplies the current delivery-eligible audience candidates. That candidate set continues to include the Sender when the Sender belongs to the destination Group. The candidate set is fixed at posting time.

The Messaging `Message` aggregate records `MessageSent` for every valid new group Message. It determines the existing sender-follow outcome from the unfiltered candidate set, then creates an `EmailDeliveryCreated` event for every candidate except the Person identified by `sender_id`. A candidate's email address is not used to decide whether they are the Sender.

The resulting delivery set may be empty. A sole-member Group therefore produces the Message and its Group access fact while producing no Email delivery. The existing requirement that a root `SendMessage` contain a non-empty resolved candidate set remains: zero resulting deliveries does not mean an empty or unresolved command audience is valid.

There is no delivery-skipped fact or Sender delivery record. Authorship and Group audience provide the audit trail. Delivery projections, addressed-recipient lists and delivery-status views continue to describe actual Email deliveries, so the Sender is absent from them.

## Commands, events and ownership

Membership continues to own current Group participation and to expose recipient candidates through its public query boundary. Web composition, inbound email and `RequestGroupAccess` continue preparing ordinary `SendMessage` commands without duplicating sender-exclusion logic.

The Messaging `Message` aggregate owns the delivery invariant because every root-message producer converges on `SendMessage` and the aggregate already emits the Message and Email delivery facts together. It emits:

- `MessageSent` for the accepted Message, including the existing sender-follow decision;
- `ConversationAccessGrantedToGroup` for the root conversation as today; and
- zero or more `EmailDeliveryCreated` events, never targeting the Sender Person.

No command or event type is added. Historical streams containing a Sender delivery remain valid and replay unchanged because the rule changes future command decisions, not event application.

## Important temporal examples

- Alice is the only eligible candidate: the Message and Group access are recorded, Alice remains following, and no Email delivery is created.
- Alice sends from an alternate verified address: Membership resolves Alice's Person identity, and the aggregate excludes Alice even when the candidate delivery address differs from the raw inbound sender address.
- An Admin member asks to join another Group and is the only Admin: `RequestGroupAccess` still creates the ordinary Admin conversation, the requester remains following under the existing policy, and no Email delivery is created.
- A requester outside Admin sends the same generated Message: current Admin candidates receive it and the requester-follow outcome remains false, as today.
- Later membership changes do not add or cancel deliveries for an already-posted Message.
- A valid reply retains its existing author-exclusion rule. An inbound attempt that is rejected before a Message is accepted may still email its rejection notice to the sender.
- Reply headers from another club that are classified as a new accepted root Message use this root-delivery rule.

## Change from today

Today the root Message aggregate creates one Email delivery per resolved candidate, including the Sender. This iteration changes only the mapping from resolved candidates to root Email delivery events. Candidate resolution, root validation, authorship, access, following, replies, rejection notices and historical replay remain unchanged.

## Deferrals

- No special copy or design for an intentionally zero-delivery Message.
- No delivery-skipped event, audit row or separate persisted audience list.
- No change to reply delivery, rejection-email delivery, posting permissions, conversation access, following policy, membership timing, provider dispatch or recovery.
- No multi-group conversation policy.

## Review status

Matt agreed this model after a bounded ensemble review. The completed panel was Anthropic Claude via Pi (`openrouter/anthropic/claude-opus-4.6`, `thr_ftj3mrfyh5`) and OpenAI Codex (`gpt-6-luna`, `thr_jzupjjfuwh`). Both confirmed aggregate ownership, event-emission ordering, replay compatibility and the focused-test boundary. Google Gemini coverage is not claimed: the first run was aborted (`thr_g3ebdfhpf9`) and the bounded retry did not complete (`thr_gjdwudju2z`).

No consequential architecture choice remains unresolved and no new ADR is required.
