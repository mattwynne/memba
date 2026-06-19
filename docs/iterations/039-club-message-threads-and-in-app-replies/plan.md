# Club message threads and in-app replies

Date: 2026-06-19
Status: draft

## Goal

Let a club member reply to a club message and follow the conversation **inside Memba**, so replies are tracked as part of the original message's thread instead of scattering to private inboxes. This is the foundation slice of the reply feature: the thread/reply domain model, in-app reply posting and reading, and stored follow state. No reply emails yet (iteration 040) and no inbound email replies yet (iteration 041).

After this iteration:

- A current member can post a reply to a club message; the reply belongs to that message's **thread**.
- Members can read the thread (original message + replies in order) in Memba.
- The original sender follows the thread automatically; anyone who replies follows it automatically.
- Other recipients are **not** following by default and can opt in / out (state stored; emails come in 040).
- Only current members of the club can reply.

## Background / Context

Today a club message is a one-way broadcast. The message-detail screen is a delivery-receipts dashboard, and replies sent by email go to the original human sender and are not tracked (iteration 024). The design sketch [`docs/superpowers/specs/2026-06-17-reply-threading-design-sketch.md`](../../superpowers/specs/2026-06-17-reply-threading-design-sketch.md) chose **Model C — thread with opt-in follow**: replies live in a thread attached to the message and are visible in Memba; followers (later) receive them by email; recipients opt in.

Confirmed product decisions: any current member can reply; recipients default to **not** following; the sender and repliers auto-follow. This slice builds the model and the in-app experience; delivery to followers is the next slice.

The reply feature is intentionally split into three sequential, independently shippable iterations: **039 in-app threads/replies**, **040 follow + reply notification emails**, **041 reply-by-email threading**. Bundling all three is the mega-iteration shape that failed historically (see the 001–004 worked example).

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **partially addressed.** This slice delivers "users can reply from the message view," "replies preserve context," and "replies are tracked as part of the thread," and stores the opt-in follow state. The *receiving replies by email* part of "members can opt in to receive replies" is completed in iteration 040; replying from an email client is iteration 041.

## Scope

### In scope

- **Domain model:** a reply that targets an existing club message's thread. The original message is the thread root; replies reference it. Reuse the event-sourced messaging aggregate/commands/events style already in `Memba.Messaging`.
- **Posting a reply:** a command + event for a member posting a reply to a thread, with the same strong-consistency/read-your-writes behaviour as `send_club_message`.
- **Follow state:** a per-(member, thread) follow flag. Auto-follow the thread for the sender (thread root author) and for anyone who posts a reply. Recipients default to not following. Commands/events to follow and unfollow.
- **Authorization:** only a current member of the message's club may reply or follow.
- **Read model + LiveView:** the member message-detail surface shows the original message, the replies in posted order, and a follow/unfollow control reflecting the viewer's follow state; an inline reply composer (body only; the reply inherits the thread subject). Reuse the existing compose validation (non-blank body).
- **Acceptance scenarios:** `acceptance-tests/features/club_message_replies.feature` (added in planning, `@iteration-039 @todo-domain @todo-ui`) becomes executable for this slice; remove/narrow the temporary tags as the domain and browser runners can run each scenario.

### Out of scope

- **Reply notification emails** to followers — iteration 040.
- **Reply-by-email** / inbound email threading (`In-Reply-To`/`References`) — iteration 041.
- Admin-only or sender-configurable reply permissions (decided: any current member).
- Reactions, editing/deleting replies, attachments, rich text.
- Changing the delivery-receipts model; the message-detail screen may demote receipts to a secondary panel per the sketch, but the receipts behaviour itself is unchanged.
- Notifications/badges for unread replies.

## Iteration Type

Behaviour-facing. New user-observable rules: a member can reply to a club message; replies are tracked in a thread and visible in Memba; the sender and repliers follow automatically; recipients opt in to follow; only current members can reply.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

`acceptance-tests/features/club_message_replies.feature` (new, `@iteration-039 @todo-domain @todo-ui`) expresses the rules: replying joins the thread; replies render in order; sender and repliers auto-follow; recipients default to not following and can follow/unfollow; non-members cannot reply. Email behaviour is deliberately excluded here (covered in 040). Existing `member_message_deliverability.feature` scenarios stay green and unchanged.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: implement the planned `@iteration-039` scenarios, then remove or narrow `@todo-domain`/`@todo-ui` as the domain and browser runners can execute each scenario green. Preserve the rules listed above; do not weaken the membership restriction or the opt-in default.

## Acceptance Criteria

- A current member can post a reply to a club message; it is stored against that message's thread and visible to other members in Memba.
- The thread shows the original message and its replies in posted order.
- The thread-root sender is following the thread; a member who posts a reply is following the thread.
- A recipient who has not acted is not following; a member can follow and unfollow, and the stored state reflects this.
- A person who is not a current member of the club cannot reply to its messages.
- Reply body validation matches compose (no blank-body reply).
- No reply emails are sent in this slice.
- The new `@iteration-039` scenarios pass with the temporary tags removed/narrowed where the runners can execute them; existing messaging scenarios stay green.
- `dev check` passes.

## Open Business Decisions

None outstanding. Confirmed: Model C; any current member can reply; recipients default to not following; sender and repliers auto-follow.

## Implementation Plan

1. Model the thread/reply in `Memba.Messaging`: decide whether the thread root is the existing message aggregate extended with replies, or a thread concept referencing it; keep it event-sourced and consistent with existing commands/events.
2. Add command(s)/event(s) for posting a reply, with authorization that the actor is a current member of the message's club, and non-blank body validation.
3. Add follow/unfollow command(s)/event(s) and a per-(member, thread) follow read model; auto-follow on thread creation (sender) and on reply (replier).
4. Add/extend projector(s) and read APIs to load a thread (root + ordered replies) and a viewer's follow state.
5. Update the member message-detail LiveView/template: render the thread and an inline reply composer (body only, inheriting the subject) and a follow/unfollow control; keep delivery receipts available (demoted per the sketch is acceptable but optional).
6. Make the `@iteration-039` scenarios executable (domain steps first, then browser), removing/narrowing `@todo-*` as each runner can run them.
7. Run `dev check`.

## Open Technical Decisions

- **Aggregate shape:** extend the existing message aggregate to hold replies, or introduce a thread aggregate keyed by the root message id. Choose the option that keeps reply ordering and authorization simplest while staying consistent with `Memba.Messaging`.
- **Follow storage:** a dedicated follow projection vs. a field on a thread-membership read model. Pick the one that makes "is viewer following?" and (in 040) "who follows this thread?" cheap.
- Reuse vs. extend of `send_club_message` strong-consistency path for reply posting.

These are implementation details and should not need product decisions.

## New Capability

Members can hold a conversation on a club message inside Memba: reply, read the thread in order, and choose to follow it — the groundwork that 040 (email notifications) and 041 (reply-by-email) build on.

## Validation Plan

- Domain ExUnit for reply posting, auto-follow (sender + replier), follow/unfollow, membership authorization, and blank-body rejection.
- Projection/read tests for thread loading (ordered replies) and viewer follow state.
- LiveView tests for rendering the thread, the reply composer, and the follow control.
- The `@iteration-039` acceptance scenarios green with temporary tags removed/narrowed where runnable.
- Full `dev check` before delivery is complete.

## Risks / Follow-ups

- **Model choice ripples forward:** 040 (followers get emails) and 041 (inbound threading) depend on the thread/follow model chosen here. Keep "who follows this thread?" easy to answer so 040 is a clean add.
- Keep this slice in-app only — resist adding email here; that scope is 040 and is what keeps this iteration shippable.
- The message-detail screen reframing (receipts → secondary) could grow; keep it minimal and record larger UI rework as follow-up.
- Sits behind the active WIP slot (034) and the queued 035–038; this is planning ahead.
