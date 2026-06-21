# Reply by email

Date: 2026-06-19
Status: merged

## Goal

Let members reply to a club conversation straight from their email client and have that reply land in the right Memba conversation. This is the final reply slice: inbound email replies are matched to conversations by standard email reply headers (`In-Reply-To` / `References`) against Memba-stored outbound `Message-ID` values, posted as replies, and delivered to followers exactly like an in-app reply (per iteration 040). Builds on iteration 039 (conversations/replies) and 040 (follow + follower delivery).

After this iteration:

- A member can hit reply in their email client on a Memba club/reply email, and the response appears in the Memba conversation.
- Memba uses normal email threading headers to decide whether an inbound email is a reply; there is no conversation id or token in the visible email address.
- The same club address continues to handle inbound mail: a header match means “reply to this conversation”; no header match means “new club-wide message” as in iterations 019/020.
- An email reply follows the same rules as an in-app reply: membership-checked, attributed to the sender, auto-follows the replier, fanned out to followers (040), and tracked.
- Unsafe inbound mail is handled with the existing inbound rejection behaviour.

## Background / Context

Iteration 024 documented that email replies currently go to the sender and are not tracked. Iterations 039/040 make replies first-class in Memba and emailable to followers. The remaining gap is the natural action: hitting “reply” in your mail client. Memba already has an inbound email pipeline (iterations 019/020, Postmark inbound) and a club inbound address; this slice extends inbound handling so the same address can route either a new club-wide message or a conversation reply.

The previous 041 draft assumed a tokenised conversation address such as `<club-slug>+c.<token>@clubs.memba.io`. Topicbox observation and mailbox inspection challenged that assumption: Topicbox appears to use the normal group address and standard email threading rather than putting a topic id in the visible address. This plan therefore pivots to the simpler email-native model: stored outbound `Message-ID` values plus inbound `In-Reply-To` / `References` determine whether a message is a reply.

This changes an assumption from iterations 019/020. `<club-slug>@clubs.memba.io` no longer always means “new message.” It means “mail to this club”; the presence of a recognized reply header for that club decides whether the mail is a reply or a new club-wide message.

## Reply Routing Model

One inbound domain remains: `clubs.memba.io`.

| Inbound address | Reply-header match? | Routes to |
|---|---:|---|
| `<club-slug>@clubs.memba.io` | Matches a stored Memba outbound `Message-ID` for that club | Existing conversation reply |
| `<club-slug>@clubs.memba.io` | No recognized same-club Memba reply header | New club-wide message (existing iterations 019/020 behaviour) |

Rules:

- Memba-generated club-message and reply-notification emails set a Memba-controlled RFC `Message-ID` and persist a mapping from that message id to the Memba message/conversation and club.
- Inbound parsing extracts `In-Reply-To` and all message ids in `References`. `In-Reply-To` is checked first; `References` are checked from newest/rightmost to oldest/leftmost when needed.
- A reply match is valid only when the matched outbound `Message-ID` belongs to a Memba message in the addressed club.
- If no valid same-club header match exists, Memba treats the inbound email as a new club-wide message to the addressed club, preserving the existing inbound path.
- Subject-line matching is not used to decide reply-vs-new.
- No conversation id or routing token is placed in `Reply-To` or the visible email address.

## Related Problems

- [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md): **expected to resolve.** With 039 (conversation + in-app reply), 040 (follower emails + opt-in follow), and this slice (reply from the inbox), all four “Expected” bullets are met end to end.

## Designs

- **Reply notification email** — DS card `emails/reply-notification.html`. This iteration keeps the visible reply address as the club’s inbound address and adds/persists Memba `Message-ID`, `In-Reply-To`, and `References` headers so mail clients thread naturally and Memba can route inbound replies. The email’s earlier-messages quoted-thread block remains the client-folded history. No new screen design — 041 is inbound routing.

## Scope

### In scope

- Generate and persist Memba-controlled outbound RFC `Message-ID` values for club messages and reply notification emails, with enough mapping to resolve inbound replies to the correct club conversation.
- Set reply notification emails so a normal email-client reply goes to the club inbound address `<club-slug>@clubs.memba.io` and carries correct `In-Reply-To` / `References` headers.
- Extend the inbound pipeline (iterations 019/020 Postmark inbound) to parse `In-Reply-To` and `References`, resolve a same-club Memba message/conversation match, and post matched inbound mail as a reply via the 039 reply path, attributed to the sending member, with basic quoted-history stripping.
- Preserve existing bare club-address behaviour: if no same-club Memba reply header match exists, the inbound email is a new club-wide message.
- Apply the same authorization as in-app replies: the sender must resolve to exactly one current member of the addressed club; auto-follow the replier (040); fan out replies to followers (040).
- Safe handling of unsafe inbound mail: non-member senders, ambiguous sender identity, unsupported attachments/body, malformed provider payloads, and unrecognized clubs reuse the existing inbound rejection behaviour and rejection email.
- Acceptance scenarios for inbound reply routing, tagged `@iteration-041`.

### Out of scope

- Tokenised conversation addresses such as `<club-slug>+c.<token>@clubs.memba.io`.
- Building groups/channels or reserving a visible group/channel address grammar.
- Subject-based reply matching.
- Quoting/trimming heuristics beyond what is needed to store a usable reply body. Basic quoted-history stripping is acceptable; perfect quote parsing is a follow-up. Failure to strip quotes must not by itself reject a reply.
- Attachments in replies.
- Changing in-app reply behaviour, follow defaults, or who may reply (set in 039/040).
- New provider integrations beyond the existing inbound path.
- New anti-spoofing mechanisms beyond the existing inbound-provider trust model; stronger SPF/DKIM/DMARC enforcement is a follow-up.

## Iteration Type

Behaviour-facing. New user-observable rule: replying to a Memba conversation email from your own mail client posts your reply into that conversation when standard email reply headers identify the conversation; otherwise, mail to the club address remains a new club-wide message.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

Extend `acceptance-tests/features/club_message_replies.feature` with `@iteration-041` scenarios: a member replying by email lands in the conversation and reaches followers; a member emailing the same club address without reply headers creates a new club-wide message; a reply email from a non-member is rejected; headers that refer to another club do not create a cross-club reply. Tag ahead-of-implementation scenarios `@iteration-041 @todo-domain @todo-ui` until runnable.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: add `@iteration-041` inbound-reply scenarios; implement and remove/narrow `@todo-*` as runners can execute them. Preserve all 039/040 rules.
- Existing inbound club-message scenarios in `acceptance-tests/features/member_message_deliverability.feature` may be extended only as needed to prove bare club-address email without reply headers still creates a new club-wide message.

## Acceptance Criteria

- Memba-generated club-message and reply-notification emails include a persisted Memba-controlled RFC `Message-ID` that can be resolved back to the Memba message/conversation and club.
- Reply notification emails use the club inbound address `<club-slug>@clubs.memba.io` as the reply destination and include appropriate `In-Reply-To` / `References` headers for email-client threading.
- A current member replying by email to a Memba conversation email has their reply posted into that conversation and fanned out to followers (per 040), attributed to them, and they auto-follow.
- An inbound email to `<club-slug>@clubs.memba.io` with no recognized same-club Memba reply header still creates a new club-wide message, preserving iterations 019/020 behaviour.
- An inbound email whose reply headers match a Memba message in a different club does not create a cross-club reply; absent any same-club match, it follows the new club-wide path for the addressed club if the sender is authorized for that club.
- An inbound reply from someone who is not a current member of the addressed club, or whose sender identity is ambiguous, is rejected safely with the existing inbound rejection behaviour and creates no post.
- Basic quoted-history stripping stores the sender’s new text when detectable and does not reject solely because quote stripping is imperfect. If stripping leaves no usable reply body, reuse the existing blank-body rejection behaviour.
- The `@iteration-041` scenarios pass with temporary tags removed/narrowed; existing scenarios stay green.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed (from 039/040): membership required; auto-follow on reply; followers receive replies. Confirmed for 041: no visible conversation token/address id; reply-vs-new is decided by Memba-recognized email headers; no recognized same-club reply header means a new club-wide message; unsafe mail is rejected with existing rejection behaviour.

## Implementation Plan

1. Add outbound message-id support: generate Memba-controlled RFC `Message-ID` values for outbound club/reply emails and persist a mapping from message id to Memba message/conversation/club. Likely touchpoints: `Memba.Messaging.MemberMessageEmail`, provider adapters, `EmailDeliveryRequest`, and a projection/table or fields that make lookup deterministic.
2. Set reply email headers: club/reply emails should route normal replies to `<club-slug>@clubs.memba.io`; reply notification emails should set `In-Reply-To` / `References` so email clients thread and Memba can recognize the conversation on inbound.
3. Extend inbound parsing: parse `In-Reply-To` and all `References` message ids in Postmark/Resend provider-neutral inbound structs. Likely touchpoints: `MembaWeb.PostmarkInboundEmailParser`, `MembaWeb.ResendInboundEmailParser`, and `Memba.Messaging.InboundEmail`.
4. Extend inbound routing: before creating a new club-wide message, attempt a same-club header match; when found, post via the 039 reply path, apply current-member authorization, auto-follow the replier, fan out to followers, and apply basic quoted-history stripping.
5. Preserve and test fallback behaviour: no same-club header match remains the existing club-wide inbound message path; non-members, ambiguous senders, unsupported bodies/attachments, unknown clubs, and malformed provider payloads keep using existing rejection behaviour.
6. Make the `@iteration-041` scenarios executable; remove/narrow `@todo-*`.
7. Run `dev check`.

## Open Technical Decisions

None that require product decisions before implementation.

Implementation choices left to the implementer, with constraints:

- The message-id mapping may live on an outbound-message/read model, delivery record, or dedicated projection/table, provided lookup from an inbound RFC message id to the correct Memba message/conversation/club is deterministic and survives replay/deploy.
- It is acceptable for 041 to support email replies only to Memba emails sent after this change. Backfilling older outbound emails that lacked persisted Memba `Message-ID` mappings is out of scope.
- Sender authenticity reuses the existing inbound provider trust model: match `From` to Memba’s known primary/alternate person email addresses and require exactly one current member in the addressed club. No/ambiguous/non-current matches are rejected.
- Header parsing should tolerate angle brackets, whitespace, folded/multiple values, and common comma/space-separated `References` formats.

## New Capability

The conversation closes the loop: a member can reply from wherever they read the message — in Memba or straight from their inbox — and it lands in the same tracked conversation and reaches the people following it. The club address remains simple and email-native: the same address starts new messages and receives replies, while standard email headers decide which is which.

## Validation Plan

- Email generation tests: outbound club/reply emails include persisted Memba `Message-ID`; reply notification emails route replies to `<club-slug>@clubs.memba.io`; `In-Reply-To` / `References` are set for conversation replies.
- Header parsing/lookup tests: `In-Reply-To` and `References` resolve to the correct same-club conversation; missing, malformed, unknown, and different-club message ids do not create cross-club replies.
- Inbound tests: matched member reply posts into the conversation and fans out (040); sender is attributed; replier auto-follows; non-member/ambiguous sender rejected; no header match still creates a new club-wide message; basic quote stripping stores usable new text.
- Provider parser tests for Postmark/Resend inbound payload headers.
- `@iteration-041` acceptance scenarios green; existing 039/040 reply/follower scenarios and 019/020 inbound club-message scenarios green.
- Full `dev check`.

## Risks / Follow-ups

- **Inbound matching is the core risk.** Header-only routing matches Topicbox-style behaviour and keeps addresses simple, but relies on mail clients preserving `In-Reply-To` / `References`. If a client strips headers, Memba treats the mail as a new club-wide message.
- Older outbound Memba emails without persisted `Message-ID` mappings cannot be routed as replies by this mechanism.
- Quoted-history bloat in stored replies; basic stripping now, better parsing as a follow-up.
- Authenticity/spoofing of inbound `From`; lean on the existing inbound pipeline’s trust model and note stronger SPF/DKIM/DMARC hardening as follow-up.
- Depends on 039 (conversation/reply) and 040 (follower fan-out + reply email shape); sequenced last for that reason.
