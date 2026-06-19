# Reply-by-email threading

Date: 2026-06-19
Status: draft

## Goal

Let members reply to a club thread straight from their email client and have that reply land in the right Memba thread. This is the final reply slice: inbound email replies are matched to their thread via standard email headers (`In-Reply-To` / `References`) and posted as replies, then fanned out to followers exactly like an in-app reply. Builds on iteration 039 (threads/replies) and 040 (follower email delivery).

After this iteration:

- A follower can reply to a reply notification email (or the original club-message email) from their inbox, and it appears in the Memba thread.
- Inbound replies are matched to the thread by email headers, not by guessing from subject text.
- An email reply follows the same rules as an in-app reply: membership-checked, attributed to the sender, fanned out to followers (040), and tracked.
- Inbound emails that can't be matched or aren't from a current member are handled safely (rejected/ignored), reusing the existing inbound pipeline's rejection behaviour.

## Background / Context

Iteration 024 documented that email replies currently go to the sender and aren't tracked. Iterations 039/040 make replies first-class in Memba and emailable to followers. The remaining gap is the natural action: hitting "reply" in your mail client. Memba already has an inbound email pipeline (iteration 019, inbound club messages by email) and a club inbound address; this slice extends inbound handling to recognise **replies** to a thread using `Message-ID`/`In-Reply-To`/`References`, so the outbound reply/club-message emails must stamp stable `Message-ID`s that inbound can correlate.

This is the largest and riskiest reply slice (inbound parsing, header correlation, spoofing/auth concerns), which is exactly why it is sequenced last and kept separate.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **expected to resolve.** With 039 (thread + in-app reply), 040 (follower emails), and this slice (reply from the inbox), all four "Expected" bullets are met end to end.

## Scope

### In scope

- Stamp outbound club-message and reply emails with stable `Message-ID`s and thread `References`, so inbound replies can be correlated to a thread. (Coordinate with 040's reply email and the club-message email.)
- Extend the inbound email pipeline to detect a **reply** (has `In-Reply-To`/`References` pointing at a known thread message) and post it as a reply into that thread, attributed to the sending member.
- Apply the same authorization as in-app replies: the sender must be a current member of the thread's club; auto-follow the replier (039); fan out to followers (040).
- Safe handling of unmatchable inbound replies, non-member senders, and ambiguous correlation — reuse the existing inbound rejection/ignore behaviour and rejection email (iteration 019/031), with thread context where possible.
- Acceptance scenarios for inbound reply threading, tagged `@iteration-041`.

### Out of scope

- Quoting/trimming heuristics beyond what's needed to store a usable reply body (basic quoted-history stripping is acceptable; perfect quote parsing is a follow-up).
- Attachments in replies.
- Changing in-app reply behaviour, follow defaults, or who may reply (set in 039).
- New provider integrations beyond the existing inbound path (Postmark inbound from iteration 020).

## Iteration Type

Behaviour-facing. New user-observable rule: replying to a Memba thread email from your own mail client posts your reply into that thread (subject to membership), the same as replying in-app.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

Extend `acceptance-tests/features/club_message_replies.feature` with `@iteration-041` scenarios: a member replying by email lands in the thread and reaches followers; a reply email from a non-member is rejected; an inbound email that can't be matched to a thread is handled safely. Tag ahead-of-implementation scenarios `@iteration-041 @todo-domain @todo-ui` until runnable.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: add `@iteration-041` inbound-reply scenarios; implement and remove/narrow `@todo-*` as runners can execute them. Preserve all 039/040 rules.

## Acceptance Criteria

- Outbound club-message and reply emails carry stable `Message-ID`/`References` enabling thread correlation.
- A current member replying by email to a thread message has their reply posted into that thread and fanned out to followers (per 040).
- An inbound reply from someone who is not a current member of the club is rejected/ignored safely (no thread post), reusing existing inbound rejection behaviour.
- An inbound email that cannot be correlated to a thread does not create a stray/misfiled reply; it is handled by the existing inbound fallback.
- The email reply is attributed to the sending member and the replier auto-follows (039).
- The `@iteration-041` scenarios pass with temporary tags removed/narrowed; existing scenarios stay green.
- `dev check` passes.

## Open Business Decisions

- **Fallback when an email reply can't be matched:** reject with a thread-aware rejection email, or silently drop. Recommendation: reuse the existing inbound rejection email path so the sender gets feedback; confirm copy during implementation.

Confirmed (from 039/040): membership required; auto-follow on reply; followers receive replies.

## Implementation Plan

1. Ensure outbound club-message (and 040 reply) emails set a stable `Message-ID` and thread `References`; persist the mapping from `Message-ID` → thread/message so inbound can correlate.
2. Extend the inbound pipeline (iteration 019/020 Postmark inbound) to detect `In-Reply-To`/`References` and resolve the target thread.
3. On a resolved, authorized inbound reply, post it as a reply (reusing the 039 reply command/path), attributed to the sending member; basic quoted-history stripping for the body.
4. Apply membership authorization and the existing rejection/ignore behaviour for non-members, unmatchable, or ambiguous inbound mail.
5. Make the `@iteration-041` scenarios executable; remove/narrow `@todo-*`.
6. Run `dev check`.

## Open Technical Decisions

- **Correlation store:** how to persist `Message-ID` → thread mapping (dedicated lookup vs. derive from a structured address/plus-addressing). Prefer header correlation with a persisted map; plus-addressing is a fallback if headers prove unreliable across providers.
- Degree of quoted-text stripping (library vs. simple heuristic) — keep minimal but usable.
- Spoofing/authenticity: how far to trust the `From` for membership matching given the existing inbound path's assumptions; reuse whatever inbound iteration 019/020 established.

These are implementation details and should not need product decisions.

## New Capability

The conversation closes the loop: a member can reply from wherever they read the message — in Memba or straight from their inbox — and it lands in the same tracked thread and reaches the people following it.

## Validation Plan

- Tests that outbound emails carry correlatable `Message-ID`/`References` and the mapping persists.
- Inbound tests: matched member reply posts into the thread and fans out (040); non-member rejected; unmatchable handled by fallback; basic quote stripping.
- `@iteration-041` acceptance scenarios green; existing scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **Inbound correlation is the core risk:** header behaviour varies across mail clients/providers. Mitigate with persisted `Message-ID` mapping plus a safe fallback; consider plus-addressing if headers are unreliable.
- Quoted-history bloat in stored replies; basic stripping now, better parsing as a follow-up.
- Authenticity/spoofing of inbound `From`; lean on the existing inbound pipeline's trust model and note hardening as follow-up.
- Depends on 039 (thread/reply) and 040 (follower fan-out + reply email shape); sequenced last for that reason.
- Sits behind 039 and 040 in the queue; planning ahead.
