# Club message conversations and replies

Date: 2026-06-19
Status: merged

## Goal

Let a club member reply to a club message, keep the reply in that message's **conversation** in Memba, and have it reach the club by email — so replies are tracked instead of scattering to private inboxes. This is the foundation slice of the reply feature: the conversation/reply model, in-app reply posting and reading, and reply emails reusing the existing club-message delivery path. A reply is emailed to **every current member** in this slice; narrowing that to opt-in followers is the next slice (040), and replying from an email client is iteration 041.

After this iteration:

- A current member can post a reply to a club message; the reply belongs to that message's conversation.
- Members can read the conversation (original message + replies in posted order) in Memba.
- A reply is emailed to every current member of the club (excluding the reply's own author), reusing the existing send + delivery-receipt machinery.
- Only current members of the club can reply.

## Background / Context

Today a club message is a one-way broadcast. The message-detail screen is a delivery-receipts dashboard, and replies sent by email go to the original human sender and are not tracked (iteration 024). The design sketch [`docs/specs/2026-06-17-reply-threading-design-sketch.md`](../../specs/2026-06-17-reply-threading-design-sketch.md) chose **Model C — conversation with opt-in follow** as the end state.

We are reaching Model C in steps. **039 ships the simplest honest increment:** a reply is "a club message that belongs to a conversation," emailed to all current members (reusing `send_club_message`'s delivery path and receipts). There is deliberately **no follow concept yet** — that means 039 emails replies to everyone (interim reply-all). **040 then introduces "follow this conversation to receive any new replies"** and narrows delivery to followers (sender + repliers auto-follow; others opt in), reducing noise. **041** adds replying from an email client.

The reply feature is split into three sequential, independently shippable iterations for exactly this reason: bundling them is the mega-iteration shape that failed historically (the 001–004 worked example).

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **partially addressed.** This slice delivers "users can reply from the message view," "replies preserve context," and "replies are tracked as part of the conversation," and gets replies to members by email. The *opt-in control over who receives replies* is iteration 040; replying from an email client is iteration 041.

## Designs

The implementer must build against these existing designs:

- **Conversation message-detail screen** — DS wireframe `wireframes/member-conversation.html` (final version) plus design sketch [`docs/specs/2026-06-17-reply-threading-design-sketch.md`](../../specs/2026-06-17-reply-threading-design-sketch.md) §4.1: the message-detail screen reframed as a conversation (original message → inline reply composer → replies in order), with the delivery-receipts panel demoted to a collapsed summary. **The DS card shows the follow toggle, which is 040 — 039 builds this screen without it.** §4.2 covers the club-home row gaining a reply-count signal.
- **Reply notification email** — DS card `emails/reply-notification.html` (final version). In 039, render it **without** the "you're following · stop following" footer line (no follow concept yet — see the design sketch §8 "one canonical email design; earlier slices omit elements"). The earlier-messages quoted-thread block and "View the conversation" CTA still apply.
- **Mobile member surfaces** — DS wireframes `wireframes/mobile-message-detail.html` and `wireframes/mobile-compose.html` show the phone-width member layout/style (sage theme, shared components) the conversation screen must match responsively.

## Scope

### In scope

- **Domain model:** a conversation formed by a club message (the root) and its replies; a reply references the conversation. Event-sourced, consistent with the existing `Memba.Messaging` aggregate/commands/events style.
- **Posting a reply:** a command + event for a member posting a reply, with the same strong-consistency/read-your-writes behaviour as `send_club_message`, and the same non-blank-body validation as compose.
- **Reply delivery:** emailing the reply to every current member of the club (excluding the reply's author), reusing the existing outbound send + delivery-receipt machinery so reply delivery is tracked like a club message. Reply email uses the shared transactional layout, standard footer, and `<club name> via Memba` sender, and preserves context (the conversation subject / what is being replied to).
- **Authorization:** only a current member of the message's club may reply.
- **Read model + LiveView:** the member message-detail surface shows the original message and the replies in posted order, with an inline reply composer (body only; the reply inherits the conversation subject).
- **Acceptance scenarios:** `acceptance-tests/features/club_message_replies.feature` (added in planning, `@iteration-039 @todo-domain @todo-ui`) becomes executable for this slice; remove/narrow the temporary tags as the domain and browser runners can run each scenario.

### Out of scope

- **Follow / opt-in** (the "follow this conversation to receive any new replies" control, auto-follow, narrowing delivery to followers) — iteration 040.
- **Reply-by-email** / inbound email threading (`In-Reply-To`/`References`) — iteration 041.
- Admin-only or sender-configurable reply permissions (decided: any current member).
- Reactions, editing/deleting replies, attachments, rich text.
- Changing the delivery-receipts model; the message-detail screen may demote receipts to a secondary panel per the sketch, but the receipts behaviour itself is unchanged.

## Iteration Type

Behaviour-facing. New user-observable rules: a member can reply to a club message; replies are tracked in a conversation and visible in Memba; a reply is emailed to the club; only current members can reply.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

`acceptance-tests/features/club_message_replies.feature` (new, `@iteration-039 @todo-domain @todo-ui`) expresses: replying joins the conversation; replies render in order; a reply is emailed to every current member (author excluded); non-members cannot reply. Follow/opt-in scenarios are deliberately **not** in this slice — they are added in 040, where they *replace* the "emailed to every current member" rule with a "followers receive replies" rule. Existing `member_message_deliverability.feature` scenarios stay green and unchanged.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: implement the planned `@iteration-039` scenarios, then remove or narrow `@todo-domain`/`@todo-ui` as the domain and browser runners can execute each scenario green. Preserve the rules listed; do not weaken the membership restriction. (Iteration 040 will revise the "emailed to every current member" rule into a followers rule — that change belongs to 040, not here.)

## Acceptance Criteria

- A current member can post a reply to a club message; it is stored in that message's conversation and visible to other members in Memba.
- The conversation shows the original message and its replies in posted order.
- A reply is emailed to every current member of the club, excluding the reply's author, reusing the existing delivery-receipt machinery (so reply delivery is observable).
- The reply email uses the shared transactional layout, standard footer, and `<club name> via Memba` sender, and preserves conversation context.
- A person who is not a current member of the club cannot reply to its messages.
- Reply body validation matches compose (no blank-body reply).
- The new `@iteration-039` scenarios pass with the temporary tags removed/narrowed where the runners can execute them; existing messaging scenarios stay green.
- `dev check` passes.

## Open Business Decisions

None outstanding. Confirmed: Model C is the end state, reached in steps; 039 emails replies to all current members (interim reply-all); any current member can reply; the reply author is not emailed their own reply.

## Implementation Plan

1. Model the conversation/reply in `Memba.Messaging`: decide whether the existing message aggregate is extended to hold replies, or a conversation concept references it; keep it event-sourced and consistent with existing commands/events.
2. Add command(s)/event(s) for posting a reply, with authorization that the actor is a current member of the message's club, and non-blank body validation.
3. Deliver the reply by email to every current member (excluding the author) by reusing the `send_club_message` delivery + receipt path; build the reply email on the shared transactional layout/footer with `<club> via Memba` sender and conversation context.
4. Add/extend projector(s) and read APIs to load a conversation (root + ordered replies).
5. Update the member message-detail LiveView/template: render the conversation and an inline reply composer (body only, inheriting the subject); keep delivery receipts available (demoting them per the sketch is acceptable but optional).
6. Make the `@iteration-039` scenarios executable (domain steps first, then browser), removing/narrowing `@todo-*` as each runner can run them.
7. Run `dev check`.

## Open Technical Decisions

- **Aggregate shape:** extend the existing message aggregate to hold replies, or introduce a conversation aggregate keyed by the root message id. Choose the option that keeps reply ordering and authorization simplest while staying consistent with `Memba.Messaging`, and that makes 040's "who follows this conversation?" a clean add.
- Reuse vs. extend of `send_club_message`'s delivery path for reply fan-out (prefer reuse to inherit receipts and provider handling; note any interaction with iteration 038's email-handoff boundary if it has landed).

These are implementation details and should not need product decisions.

## New Capability

Members can hold a conversation on a club message inside Memba — reply, read it in order, and the reply reaches the club by email with delivery tracking — the groundwork that 040 (opt-in follow) and 041 (reply-by-email) build on.

## Validation Plan

- Domain ExUnit for reply posting, membership authorization, blank-body rejection, and conversation membership of the reply.
- Delivery tests: a reply emails every current member except the author, reusing the receipt machinery; reply email rendering (footer, `<club> via Memba`, conversation context).
- Projection/read tests for conversation loading (ordered replies).
- LiveView tests for rendering the conversation and the reply composer.
- The `@iteration-039` acceptance scenarios green with temporary tags removed/narrowed where runnable.
- Full `dev check` before delivery is complete.

## Risks / Follow-ups

- **Interim reply-all noise.** 039 emails replies to all current members — the noisy model Memba otherwise avoids. 040 narrows this to opt-in followers and follows immediately. Coordinate release so 039 is not long-lived in production without 040, or consciously accept short-term reply-all on club messages.
- **Model choice ripples forward.** 040 (followers get replies) and 041 (inbound threading) depend on the conversation/reply model chosen here. Keep "who is in / follows this conversation?" easy to answer so 040 is a clean narrowing rather than a rework.
- The message-detail screen reframing (receipts → secondary) could grow; keep it minimal and record larger UI rework as follow-up.
- **Conversation-screen design arrived as a fast-follow.** The DS wireframe `wireframes/member-conversation.html` was mocked after 039 implementation began, so align the in-flight build/review to it (it shows the final/040 follow toggle — 039 omits that). Mobile conversation layout is not yet mocked (only the pre-reply `mobile-message-detail.html`); add a mobile conversation card as a follow-up if needed.
- Sits behind the active WIP slot and other queued iterations; this is planning ahead.
