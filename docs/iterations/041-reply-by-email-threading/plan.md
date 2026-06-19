# Reply by email

Date: 2026-06-19
Status: draft

## Goal

Let members reply to a club conversation straight from their email client and have that reply land in the right Memba conversation. This is the final reply slice: inbound email replies are matched to their conversation by a **conversation-addressed reply address** (with email headers as a secondary check), posted as replies, and delivered to followers exactly like an in-app reply (per iteration 040). Builds on iteration 039 (conversations/replies) and 040 (follow + follower delivery).

After this iteration:

- A member can reply to a reply notification email from their inbox, and it appears in the Memba conversation.
- Inbound replies are matched to the conversation by the address they were sent to (a typed, tokenised club address), not by guessing from subject text.
- An email reply follows the same rules as an in-app reply: membership-checked, attributed to the sender, auto-follows the replier, fanned out to followers (040), and tracked.
- Inbound mail that can't be matched, or isn't from a current member, is handled safely (rejected/ignored), reusing the existing inbound rejection behaviour.

## Background / Context

Iteration 024 documented that email replies currently go to the sender and aren't tracked. Iterations 039/040 make replies first-class in Memba and emailable to followers. The remaining gap is the natural action: hitting "reply" in your mail client. Memba already has an inbound email pipeline (iterations 019/020, Postmark inbound) and a club inbound address; this slice extends inbound handling to route a reply to its conversation.

This is the largest and riskiest reply slice (inbound parsing, address/header correlation, spoofing/auth concerns), which is why it is sequenced last and kept separate.

### Email address schema (extensible — room for groups/channels)

Decided up front so the schema is not flat and can grow. One inbound domain (`clubs.memba.io`, today's Postmark MX). The **local part is a typed, dot-segmented routing path** under the club slug, separated by `+`:

| Address | Routes to | Status |
|---|---|---|
| `<club-slug>@clubs.memba.io` | the club — club-wide message | today, unchanged |
| `<club-slug>+c.<token>@clubs.memba.io` | a **conversation** (reply target); `c` = conversation | this iteration |
| `<club-slug>+g.<group>@clubs.memba.io` | a **group/channel** | **reserved**, not built |
| `<club-slug>+g.<group>.c.<token>@…` | a conversation within a group | **reserved**, not built |

- The inbound parser splits the local part on `+`, then reads typed segments (`c.` = conversation; future `g.` = group). No suffix ⇒ club-wide (today's behaviour). Unknown/garbled ⇒ existing rejection/fallback.
- `<token>` is an opaque, unguessable routing token mapped to the conversation (not the raw conversation id), so the address is stable and safe to expose.
- Email headers (`In-Reply-To`/`References`) are a **secondary** confirmation, not the primary match, because the conversation is encoded in the address itself.
- Setting `Message-ID`/`In-Reply-To`/`References` also lets email clients **thread and fold the quoted history natively** (Apple Mail "See more", Gmail "•••"), which is why the reply email (designed in 040, `emails/reply-notification.html`) emits earlier messages as a standard quote rather than a custom fold or inlined branded history.
- The `+g.` type tag and the segment grammar are **reserved now** so adding groups/channels later is additive — no schema rewrite.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **expected to resolve.** With 039 (conversation + in-app reply), 040 (follower emails + opt-in follow), and this slice (reply from the inbox), all four "Expected" bullets are met end to end.

## Scope

### In scope

- Implement the conversation reply address `<club-slug>+c.<token>@clubs.memba.io` and switch the 040 reply email `Reply-To` to it (replacing the interim no-reply/guidance from 040).
- Persist the mapping from conversation routing `<token>` ↔ conversation so inbound mail can resolve the target.
- Extend the inbound pipeline (iterations 019/020 Postmark inbound) to parse the typed local part, resolve the conversation, and post the inbound mail as a reply (reusing the 039 reply path), attributed to the sending member, with basic quoted-history stripping.
- Apply the same authorization as in-app replies: the sender must be a current member of the conversation's club; auto-follow the replier (040); fan out to followers (040).
- Safe handling of unmatchable inbound mail, non-member senders, and ambiguous addresses — reuse the existing inbound rejection/ignore behaviour and rejection email (iterations 019/031), with conversation context where possible.
- Acceptance scenarios for inbound reply routing, tagged `@iteration-041`.

### Out of scope

- Building groups/channels — the `+g.` namespace is reserved, not implemented.
- Quoting/trimming heuristics beyond what's needed to store a usable reply body (basic quoted-history stripping is acceptable; perfect quote parsing is a follow-up).
- Attachments in replies.
- Changing in-app reply behaviour, follow defaults, or who may reply (set in 039/040).
- New provider integrations beyond the existing inbound path.

## Iteration Type

Behaviour-facing. New user-observable rule: replying to a Memba conversation email from your own mail client posts your reply into that conversation (subject to membership), the same as replying in-app, and it reaches the conversation's followers.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

Extend `acceptance-tests/features/club_message_replies.feature` with `@iteration-041` scenarios: a member replying by email lands in the conversation and reaches followers; a reply email from a non-member is rejected; inbound mail that can't be matched to a conversation is handled safely. Tag ahead-of-implementation scenarios `@iteration-041 @todo-domain @todo-ui` until runnable.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: add `@iteration-041` inbound-reply scenarios; implement and remove/narrow `@todo-*` as runners can execute them. Preserve all 039/040 rules.

## Acceptance Criteria

- The 040 reply email `Reply-To` is the conversation address `<club-slug>+c.<token>@clubs.memba.io`.
- A current member replying by email to a conversation has their reply posted into that conversation and fanned out to followers (per 040), attributed to them, and they auto-follow.
- An inbound reply from someone who is not a current member of the club is rejected/ignored safely (no post), reusing existing inbound rejection behaviour.
- Inbound mail to an unknown/garbled address or `<token>` is handled by the existing inbound fallback and does not create a stray/misfiled reply.
- A bare `<club-slug>@clubs.memba.io` email with no typed suffix still behaves as today (a new club-wide message), confirming the schema is backward-compatible.
- The `@iteration-041` scenarios pass with temporary tags removed/narrowed; existing scenarios stay green.
- `dev check` passes.

## Open Business Decisions

- **Fallback when an inbound reply can't be matched:** reject with a conversation-aware rejection email, or silently drop. Recommendation: reuse the existing inbound rejection email path so the sender gets feedback; confirm copy during implementation.

Confirmed (from 039/040): membership required; auto-follow on reply; followers receive replies. Address schema: typed local-part with reserved `+g.` group namespace.

## Implementation Plan

1. Add the conversation routing token ↔ conversation mapping; generate a token per conversation.
2. Set the 040 reply email `Reply-To` (and `Message-ID`/`References` for header confirmation) to the conversation address `<club-slug>+c.<token>@clubs.memba.io`.
3. Extend the inbound pipeline to parse the typed local part (`+c.<token>`), resolve the conversation, and (with header confirmation as secondary) post the mail as a reply via the 039 reply path; basic quoted-history stripping.
4. Apply membership authorization and the existing rejection/ignore behaviour for non-members, unmatchable, or ambiguous inbound mail; keep bare `<club-slug>@` as today's club-wide path.
5. Make the `@iteration-041` scenarios executable; remove/narrow `@todo-*`.
6. Run `dev check`.

## Open Technical Decisions

- Token format/derivation (random opaque vs. signed) and where the token↔conversation map lives.
- Degree of quoted-text stripping (library vs. simple heuristic) — keep minimal but usable.
- Spoofing/authenticity: how far to trust the `From` for membership matching given the existing inbound path's assumptions; reuse whatever iterations 019/020 established and note hardening as follow-up.

These are implementation details and should not need product decisions.

## New Capability

The conversation closes the loop: a member can reply from wherever they read the message — in Memba or straight from their inbox — and it lands in the same tracked conversation and reaches the people following it. The address schema also leaves room to add groups/channels within a club later without rework.

## Validation Plan

- Tests that the reply email `Reply-To` is the conversation address and the token↔conversation mapping resolves; `Message-ID`/`References` set for secondary confirmation.
- Inbound tests: matched member reply posts into the conversation and fans out (040); non-member rejected; unmatchable handled by fallback; bare club address still creates a club-wide message; basic quote stripping.
- `@iteration-041` acceptance scenarios green; existing scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **Inbound matching is the core risk**, but addressing-by-token (conversation in the address) is far more robust than header-only correlation across mail clients; headers are a secondary check.
- Quoted-history bloat in stored replies; basic stripping now, better parsing as a follow-up.
- Authenticity/spoofing of inbound `From`; lean on the existing inbound pipeline's trust model and note hardening as follow-up.
- Depends on 039 (conversation/reply) and 040 (follower fan-out + reply email shape); sequenced last for that reason.
- The reserved `+g.` group namespace is a design affordance only; building groups/channels is future work, not implied by this iteration.
