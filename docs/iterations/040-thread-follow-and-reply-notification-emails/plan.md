# Follow a conversation, and send replies only to followers

Date: 2026-06-19
Status: merged

## Goal

Stop emailing every reply to the whole club. Introduce **following a conversation** so that a reply reaches only the people who follow it — the original sender and anyone who has replied (automatically), plus anyone who opts in — instead of all current members. This completes the "members can opt in to receive replies to a conversation" part of the reply problem and turns Memba's replies from interim reply-all (iteration 039) into the opt-in Model C. Builds directly on iteration 039 (conversations, replies, reply-to-all email delivery).

After this iteration:

- A conversation has **followers**. The original sender follows it; anyone who posts a reply follows it; everyone else is **not** following by default.
- Members can "follow this conversation to receive any new replies" and stop following at any time, in Memba and from a reply email.
- A reply is emailed **only to current club members who currently follow** the conversation (excluding the reply's author), not to every member.
- Reply emails keep the existing delivery tracking, shared layout/footer, and `<club name> via Memba` sender.

## Background / Context

Iteration 039 makes replies first-class and emails each reply to **all** current members (interim reply-all). That is the noisy mailing-list behaviour Memba otherwise avoids, and it is only acceptable as a short-lived first step. Model C (design sketch) narrows it: replies go to **followers** only. This slice introduces the follow concept and rewires reply delivery from "all current members" to "current followers," with the sender and repliers auto-following so they still hear the conversation, and a clear opt-in control ("follow this conversation to receive any new replies") for everyone else.

Following has no purpose except deciding who is emailed, so the follow model and the narrowed delivery ship together as one coherent capability.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **further addressed.** Completes "members can opt in to receive replies to a conversation." Replying *from* an email client remains iteration 041.

## Designs

- **Reply notification email** — DS card `emails/reply-notification.html` is the **final/canonical** version this iteration completes: it adds the "you're following this conversation · stop following this conversation" footer line that 039 omitted. The new-reply body, "View the conversation" CTA, and standard quoted-thread history are unchanged from 039.
- **Conversation screen follow control** — DS wireframe `wireframes/member-conversation.html` shows the final state including the "Follow this conversation to receive any new replies" toggle under the original message (this iteration adds that toggle to the 039 screen). Also design sketch [`docs/specs/2026-06-17-reply-threading-design-sketch.md`](../../specs/2026-06-17-reply-threading-design-sketch.md) §4.1 and §4.3 (email footer follow/unfollow).

## Scope

### In scope

- **Follow model:** a per-(member, conversation) follow state. Event-sourced, consistent with `Memba.Messaging`. Commands/events to follow and unfollow.
- **Auto-follow:** the conversation's original sender follows it; any member who posts a reply follows it. Everyone else defaults to **not** following.
- **Narrow reply delivery:** change reply fan-out from "every current member" (039) to "current club members who currently follow the conversation," excluding the reply's author. Non-followers and former/non-current members receive no reply email, even if a historical follow state exists.
- **Follow control + copy:** an in-app "follow this conversation to receive any new replies" / unfollow control on the message-detail surface, reflecting the viewer's state. Only current members of the club can follow or unfollow in-app; non-members and former members cannot newly follow a conversation.
- **Unsubscribe from email:** a one-click signed stop-following link in the reply email, consistent with the in-app unfollow; unfollowing halts further reply emails for that conversation.
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

Revise `acceptance-tests/features/club_message_replies.feature`: the 039 rule "A reply is emailed to every current member of the club" is **replaced** by "A reply is emailed to current club-member followers," and new rules cover auto-follow (sender + repliers), opt-in default (a non-engaged member is not following), follow/unfollow, current-member recipient eligibility, and unfollow-stops-email from both the app and a reply email. Tag ahead-of-implementation scenarios `@iteration-040 @todo-domain @todo-ui` until the runners can execute them; preserve the 039 conversation/reply/membership rules.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`:
  - **Replace** the `@iteration-039` rule/scenario "A reply is emailed to every current member of the club" with a `@iteration-040` rule "A reply is emailed to current club-member followers" (the documented narrowing of who receives replies while preserving the current-member boundary).
  - **Add** `@iteration-040` scenarios for auto-follow (sender and repliers), the opt-in default, following/unfollowing, follower delivery excluding former/non-current members, valid email stop-follow, and invalid/tampered email stop-follow links changing nothing.
  - Preserve the 039 rules that a member can reply, replies join the conversation in order, and only current members can reply.

## Acceptance Criteria

- A conversation's original sender is following it; a member who posts a reply is following it; a member who has not engaged is not following it.
- A current member can follow ("follow this conversation to receive any new replies") and unfollow in Memba; repeated follow/unfollow attempts are idempotent and do not create duplicate or inconsistent follow state.
- A one-click signed stop-following link in a reply email unfollows only the intended recipient from the intended conversation without requiring sign-in; using it when already unfollowed is a safe success.
- Invalid, tampered, expired-if-the-implementation-explicitly-adds-expiry, or wrong-scope stop-follow links change nothing and show a generic failure that does not reveal whether the club, conversation, or member exists.
- A reply is emailed only to current club members who currently follow the conversation, excluding the reply's author; non-followers and former/non-current members receive no reply email.
- After unfollowing, a member receives no further reply emails for that conversation.
- Reply emails keep the existing delivery tracking, shared layout/footer, and `<club name> via Memba` sender.
- The revised/added `@iteration-040` scenarios pass with temporary tags removed/narrowed; the 039 conversation/reply/membership scenarios stay green (with the reply-audience rule now superseded by the followers rule).
- `dev check` passes.

## Open Business Decisions

None outstanding on audience. **Reply-To is decided:** the conversation reply address `<club-slug>+c.<token>@clubs.memba.io` is introduced in iteration 041 (inbound routing). Since 040 ships before that routing exists, 040 sets the reply email `Reply-To` to a **no-reply / "reply in Memba" guidance**, and 041 switches it to the conversation address. This avoids shipping a `Reply-To` whose inbound handling does not yet exist. See the email address schema in [iteration 041's plan](../041-reply-by-email-threading/plan.md).

Confirmed: only current club-member followers receive replies; sender + repliers auto-follow; everyone else opts in (default off). A valid email stop-follow link may clear that recipient's follow state even if they are no longer a current member, because it only reduces future notifications; former/non-current members cannot newly follow and are never reply-email recipients.

## Implementation Plan

1. Add follow/unfollow command(s)/event(s) and a per-(member, conversation) follow read model; auto-follow the sender on conversation creation and a replier on reply (from the 039 events).
2. Rewire the reply delivery introduced in 039 from "all current members" to "current club-member followers of the conversation," excluding the author and excluding former/non-current members even when a historical follow record exists.
3. Add the in-app follow/unfollow control + copy on the message-detail surface, reflecting the viewer's state and preventing non-current members from newly following.
4. Add a one-click signed stop-following (unsubscribe) link to the reply email, consistent with in-app unfollow; ensure unfollow halts future reply emails.
5. Revise `club_message_replies.feature` per Allowed acceptance feature changes; make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
6. Run `dev check`.

## Email Stop-Follow Behaviour

The reply-email footer contains a one-click signed stop-following link. This is an unsubscribe-style action and does **not** require sign-in.

Required behaviour:

- The token is opaque/signed and scoped to the club, conversation, and intended recipient/member-person; it must not be usable to change any other person's or conversation's follow state.
- The product behaviour is long-lived/non-expiring so old reply emails remain useful; if the chosen implementation helper forces an expiry, use the longest practical expiry and treat expired tokens like invalid tokens.
- A valid link unfollows only that recipient from that conversation and then shows a simple success page/state that offers a path back to the conversation if the viewer can sign in.
- Reusing a valid link after the recipient is already unfollowed is idempotent and shows the same safe success.
- Invalid, tampered, expired, or wrong-scope tokens change nothing and show a generic failure that does not reveal whether the club, conversation, or member exists.
- A valid email stop-follow link may clear a historical follow state for a former/non-current member, because it only reduces notifications. Former/non-current members still cannot newly follow and are never eligible reply-email recipients.

## Open Technical Decisions

None that require product decisions before implementation.

Implementation choices left to the implementer, with constraints:

- Follow storage may be a dedicated follow projection or a conversation-membership read-model field, provided "is viewer following?" and "who are the current club-member followers?" are cheap and deterministic.
- The signed stop-follow token may reuse existing token helpers or use a dedicated token module, provided it satisfies the behaviour above.
- Reply delivery may keep reusing 039's delivery path (now filtered to current club-member followers) or factor a shared "deliver to recipients" helper; note any interaction with iteration 038's email-handoff boundary if landed.

## New Capability

Replies reach exactly the people who want them: the sender and repliers automatically, plus anyone who chooses to follow — and no one else — removing the interim reply-all and realising Model C, with unfollow always available.

## Validation Plan

- Domain/integration tests: auto-follow (sender + replier), opt-in default, follow/unfollow, idempotent repeated follow/unfollow, current-member-only in-app permissions, reply fan-out to current club-member followers only, former/non-current followers excluded, replier excluded, unfollow stops delivery.
- Email tests: only current club-member followers emailed; stop-following link works for the intended recipient/conversation; reused already-unfollowed links are safe; invalid/tampered/expired/wrong-scope links change nothing; footer, `<club> via Memba`, conversation context preserved.
- Acceptance: the `@iteration-040` scenarios green; 039 conversation/reply/membership scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **This slice is what removes the 039 reply-all noise** — sequence it close behind 039 so production does not sit long on reply-all.
- Per-reply emails could be noisy on busy conversations; digest/batching is a follow-up, not this slice.
- Depends on 039's conversation model exposing participants and supporting a cheap follower set.
- If iteration 038 (email-handoff boundary) has landed, route reply emails through that boundary.
- Sits behind 039 in the queue; planning ahead.
