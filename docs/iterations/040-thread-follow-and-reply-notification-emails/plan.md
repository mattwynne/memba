# Follow a conversation, and send replies only to followers

Date: 2026-06-19
Status: draft

## Goal

Stop emailing every reply to the whole club. Introduce **following a conversation** so that a reply reaches only the people who follow it — the original sender and anyone who has replied (automatically), plus anyone who opts in — instead of all current members. This completes the "members can opt in to receive replies to a conversation" part of the reply problem and turns Memba's replies from interim reply-all (iteration 039) into the opt-in Model C. Builds directly on iteration 039 (conversations, replies, reply-to-all email delivery).

After this iteration:

- A conversation has **followers**. The original sender follows it; anyone who posts a reply follows it; everyone else is **not** following by default.
- Members can "follow this conversation to receive any new replies" and stop following at any time, in Memba and from a reply email.
- A reply is emailed **only to current followers** of the conversation (excluding the reply's author), not to every member.
- Reply emails keep the existing delivery tracking, shared layout/footer, and `<club name> via Memba` sender.

## Background / Context

Iteration 039 makes replies first-class and emails each reply to **all** current members (interim reply-all). That is the noisy mailing-list behaviour Memba otherwise avoids, and it is only acceptable as a short-lived first step. Model C (design sketch) narrows it: replies go to **followers** only. This slice introduces the follow concept and rewires reply delivery from "all current members" to "current followers," with the sender and repliers auto-following so they still hear the conversation, and a clear opt-in control ("follow this conversation to receive any new replies") for everyone else.

Following has no purpose except deciding who is emailed, so the follow model and the narrowed delivery ship together as one coherent capability.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **further addressed.** Completes "members can opt in to receive replies to a conversation." Replying *from* an email client remains iteration 041.

## Designs

- **Reply notification email** — DS card `emails/reply-notification.html` is the **final/canonical** version this iteration completes: it adds the "you're following this conversation · stop following this conversation" footer line that 039 omitted. The new-reply body, "View the conversation" CTA, and standard quoted-thread history are unchanged from 039.
- **Conversation screen follow control** — DS wireframe `wireframes/member-conversation.html` shows the final state including the "Follow this conversation to receive any new replies" toggle under the original message (this iteration adds that toggle to the 039 screen). Also design sketch [`docs/superpowers/specs/2026-06-17-reply-threading-design-sketch.md`](../../superpowers/specs/2026-06-17-reply-threading-design-sketch.md) §4.1 and §4.3 (email footer follow/unfollow).

## Scope

### In scope

- **Follow model:** a per-(member, conversation) follow state. Event-sourced, consistent with `Memba.Messaging`. Commands/events to follow and unfollow.
- **Auto-follow:** the conversation's original sender follows it; any member who posts a reply follows it. Everyone else defaults to **not** following.
- **Narrow reply delivery:** change reply fan-out from "every current member" (039) to "current followers of the conversation," excluding the reply's author. Non-followers receive no reply email.
- **Follow control + copy:** an in-app "follow this conversation to receive any new replies" / unfollow control on the message-detail surface, reflecting the viewer's state.
- **Unsubscribe from email:** a stop-following link in the reply email, consistent with the in-app unfollow; unfollowing halts further reply emails for that conversation.
- **Reply email design:** per the DS design `emails/reply-notification.html` — a branded new-reply body + "View the conversation" CTA + a footer with "you're following this conversation · stop following this conversation". **Earlier messages are emitted as a standard quoted thread** (`blockquote.gmail_quote` + "On <date>, <name> wrote:" attributions) so email clients fold it natively ("See more" in Apple Mail, "•••" in Gmail) and thread it via headers (041) — rather than building a custom fold (unreliable: `<details>` is stripped by Gmail) or inlining a branded full history (which would double the thread in clients that thread by headers).
- **Acceptance scenarios:** revise `club_message_replies.feature` to replace the 039 "reply emailed to every current member" rule with a "followers receive replies" rule, and add follow/auto-follow/unfollow scenarios, tagged `@iteration-040`.

### Out of scope

- Reply-by-email / inbound threading — iteration 041.
- Digest/batching of replies; each reply emails followers individually (a possible follow-up).
- Changing who can reply (set in 039: any current member) or the conversation/reply model itself.
- Per-conversation notification preferences beyond follow/unfollow (e.g. mute-but-stay).

## Iteration Type

Behaviour-facing. Changed user-observable rule: a reply is emailed to the conversation's followers rather than to every member; following (auto for sender/repliers, opt-in for others) determines who receives replies; unfollowing stops them.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

Revise `acceptance-tests/features/club_message_replies.feature`: the 039 rule "A reply is emailed to every current member of the club" is **replaced** by "A reply is emailed to the conversation's followers," and new rules cover auto-follow (sender + repliers), opt-in default (a non-engaged member is not following), follow/unfollow, and unfollow-stops-email. Tag ahead-of-implementation scenarios `@iteration-040 @todo-domain @todo-ui` until the runners can execute them; preserve the 039 conversation/reply/membership rules.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`:
  - **Replace** the `@iteration-039` rule/scenario "A reply is emailed to every current member of the club" with a `@iteration-040` rule "A reply is emailed to the conversation's followers" (the documented narrowing of who receives replies).
  - **Add** `@iteration-040` scenarios for auto-follow (sender and repliers), the opt-in default, following/unfollowing, and unfollow-stops-email.
  - Preserve the 039 rules that a member can reply, replies join the conversation in order, and only current members can reply.

## Acceptance Criteria

- A conversation's original sender is following it; a member who posts a reply is following it; a member who has not engaged is not following it.
- A member can follow ("follow this conversation to receive any new replies") and unfollow, in Memba and from a reply email; the stored state reflects this.
- A reply is emailed only to the conversation's current followers, excluding the reply's author; non-followers receive no reply email.
- After unfollowing, a member receives no further reply emails for that conversation.
- Reply emails keep the existing delivery tracking, shared layout/footer, and `<club name> via Memba` sender.
- The revised/added `@iteration-040` scenarios pass with temporary tags removed/narrowed; the 039 conversation/reply/membership scenarios stay green (with the reply-audience rule now superseded by the followers rule).
- `dev check` passes.

## Open Business Decisions

None outstanding on audience. **Reply-To is decided:** the conversation reply address `<club-slug>+c.<token>@clubs.memba.io` is introduced in iteration 041 (inbound routing). Since 040 ships before that routing exists, 040 sets the reply email `Reply-To` to a **no-reply / "reply in Memba" guidance**, and 041 switches it to the conversation address. This avoids shipping a `Reply-To` whose inbound handling does not yet exist. See the email address schema in [iteration 041's plan](../041-reply-by-email-threading/plan.md).

Confirmed: only followers receive replies; sender + repliers auto-follow; everyone else opts in (default off).

## Implementation Plan

1. Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
2. Rewire the reply delivery introduced in 039 from "all current members" to "current followers of the conversation," excluding the author.
3. Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state.
4. Add a stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
5. Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
6. Run `dev check`.

## Open Technical Decisions

- Follow storage: a dedicated follow projection vs. a field on a conversation-membership read model. Pick the one that makes "is viewer following?" and "who follows this conversation?" cheap.
- Unsubscribe token mechanism (reuse existing auth/token helpers vs. a dedicated follow token).
- Whether to keep reusing 039's delivery path (now filtered to followers) or factor a shared "deliver to recipients" helper; note any interaction with iteration 038's email-handoff boundary if landed.

These are implementation details and should not need product decisions.

## New Capability

Replies reach exactly the people who want them: the sender and repliers automatically, plus anyone who chooses to follow — and no one else — removing the interim reply-all and realising Model C, with unfollow always available.

## Validation Plan

- Domain/integration tests: auto-follow (sender + replier), opt-in default, follow/unfollow, reply fan-out to followers only, replier excluded, unfollow stops delivery.
- Email tests: only followers emailed; stop-following link works; footer, `<club> via Memba`, conversation context preserved.
- Acceptance: the `@iteration-040` scenarios green; 039 conversation/reply/membership scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **This slice is what removes the 039 reply-all noise** — sequence it close behind 039 so production does not sit long on reply-all.
- Per-reply emails could be noisy on busy conversations; digest/batching is a follow-up, not this slice.
- Depends on 039's conversation model exposing participants and supporting a cheap follower set.
- If iteration 038 (email-handoff boundary) has landed, route reply emails through that boundary.
- Sits behind 039 in the queue; planning ahead.
