# Thread follow and reply notification emails

Date: 2026-06-19
Status: draft

## Goal

Deliver replies to the people who follow a thread, by email. This completes the "members can opt in to receive replies to a thread" part of the reply problem: when someone posts a reply (in Memba), every follower of that thread gets a reply notification email, reusing Memba's existing send/receipt machinery. Builds directly on iteration 039 (threads, in-app replies, stored follow state).

After this iteration:

- Posting a reply emails the reply to every current follower of the thread (not the whole club).
- The reply notification email preserves thread context (what's being replied to) and links back to the conversation in Memba.
- Followers can stop following from the email and in-app; unfollowing stops further reply emails.
- Reply emails use the shared transactional layout, footer, and the `<club> via Memba` sender treatment.

## Background / Context

Iteration 039 establishes the thread/reply model and stores per-(member, thread) follow state, but sends no email. Model C (design sketch) requires that **followers** — the sender, anyone who replied, and recipients who opted in — receive replies by email, while non-followers do not, keeping a 142-member club from being flooded. This slice adds the delivery: turn a posted reply into emails to the thread's followers, with receipts, reusing the outbound email path used by `send_club_message` and the transactional templates from iterations 024/031.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **further addressed.** Completes "members can opt in to receive replies to a thread" (the opt-in state from 039 now drives email delivery). Replying *from* an email client remains iteration 041.

## Scope

### In scope

- On a reply being posted (the 039 event), send a **reply notification email** to each current follower of the thread, excluding the replier themselves.
- Reply email content preserves thread context: the new reply, an indication of what it replies to (thread subject / quoted original), and a link to the conversation in Memba. Uses the shared transactional layout + standard footer + `<club name> via Memba` sender.
- Delivery tracking for reply emails reusing the existing receipt/delivery-status machinery (so reply delivery is observable like club-message delivery).
- **Unsubscribe / stop following** from the email (and confirm the in-app unfollow from 039 also stops emails). Unfollowing stops further reply emails for that thread.
- Respect the opt-in default from 039: only followers receive emails; recipients who never followed do not.
- Acceptance scenarios for follower email delivery and unfollow-stops-email, tagged `@iteration-040`.

### Out of scope

- Reply-by-email / inbound threading — iteration 041.
- Digest/batching of replies; each reply emails followers individually (batching is a possible follow-up).
- Changing who can reply or the follow defaults (set in 039).
- Per-thread notification preferences beyond follow/unfollow (e.g. mute-but-stay-member).

## Iteration Type

Behaviour-facing. New user-observable rule: following a thread means you receive its replies by email; unfollowing stops them; repliers and the sender follow automatically (from 039), so they receive replies too.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

Extend `acceptance-tests/features/club_message_replies.feature` with `@iteration-040` scenarios for the email behaviour: a follower receives a reply by email; a non-follower does not; the replier is not emailed their own reply; unfollowing stops further reply emails; the reply email identifies the club and preserves thread context. Tag ahead-of-implementation scenarios `@iteration-040 @todo-domain @todo-ui` until the runners can execute them.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: add the `@iteration-040` email scenarios; implement and remove/narrow `@todo-*` as runners can execute them. Preserve the 039 rules; do not change the opt-in default or who can reply.

## Acceptance Criteria

- Posting a reply sends a reply notification email to every current follower of the thread, except the member who posted that reply.
- A member who is not following the thread receives no reply email.
- The reply email preserves thread context (subject and what is being replied to) and links to the conversation in Memba.
- The reply email uses the shared transactional layout, standard footer, and `<club name> via Memba` sender.
- Reply email delivery is tracked with the existing receipt/delivery-status machinery.
- A follower can stop following from the email and in-app; after unfollowing, no further reply emails are sent for that thread.
- The `@iteration-040` scenarios pass with temporary tags removed/narrowed; existing scenarios stay green.
- `dev check` passes.

## Open Business Decisions

- **Reply-to address on the reply email:** point it at the thread (sets up 041) or at the replier (current behaviour). Recommendation: park inbound handling for 041; for now reply-to may remain the replier or a no-reply, decided in implementation, without blocking this slice.

Confirmed: only followers receive reply emails; sender + repliers auto-follow (039); recipients opt in.

## Implementation Plan

1. Subscribe to the reply-posted event from 039 (or extend its handler) to fan out reply emails to the thread's current followers, excluding the replier.
2. Build the reply notification email on the shared transactional layout/footer with thread context and a Memba conversation link; set the `<club> via Memba` sender.
3. Route reply emails through the existing outbound send + receipt/delivery path so delivery is tracked.
4. Implement stop-following from the email (tokenized unsubscribe link) consistent with the in-app unfollow; ensure unfollow halts future reply emails.
5. Make the `@iteration-040` scenarios executable (domain then browser/email), removing/narrowing `@todo-*`.
6. Run `dev check`.

## Open Technical Decisions

- Whether to reuse `send_club_message`'s delivery pipeline directly or a parallel reply-delivery path; prefer reuse to inherit receipts and provider handling (note any interaction with iteration 038's email-handoff boundary if it has landed).
- Unsubscribe token mechanism (reuse existing auth/token helpers vs. a dedicated follow token).

These are implementation details and should not need product decisions.

## New Capability

Thread followers stay in the loop by email: a reply reaches exactly the people who care (sender, repliers, opt-in followers), with full Memba branding and delivery tracking, and they can stop following at any time.

## Validation Plan

- Domain/integration tests: reply fan-out to followers only, replier excluded, unfollow stops delivery.
- Email rendering tests: thread context, footer, `<club> via Memba` sender, conversation link.
- Delivery-tracking tests for reply emails reusing the receipt machinery.
- `@iteration-040` acceptance scenarios green; existing scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **Noise control depends on the opt-in default holding.** If 039's default ever flips to follow-on-receipt, this becomes a club-wide blast — keep the default off.
- Per-reply emails could be noisy on busy threads; digest/batching is a follow-up, not this slice.
- Depends on 039's follow model exposing "current followers of a thread" cheaply.
- If iteration 038 (email-handoff boundary) has landed, route reply email through that boundary rather than around it.
- Sits behind 039 in the queue; planning ahead.
