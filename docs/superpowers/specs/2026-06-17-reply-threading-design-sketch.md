# Design sketch — replying to club messages (conversations)

**Date:** 2026-06-17
**Status:** Sketch for review — not a plan, not approved. Captures the pivotal product
decision plus screen mockups so Matt can react.
**Problem:** [`docs/problems/2026-06-01-cant-reply-to-email-message.md`](../../problems/2026-06-01-cant-reply-to-email-message.md)

---

## 1. What the problem asks for

> - Users can reply to email messages from the message view.
> - Replies preserve enough message context for the user to understand what they are responding to.
> - Replies are tracked as part of the relevant conversation in Memba.
> - Members can opt in to receive replies to a conversation.

## 2. How messaging works today (so we change the right thing)

- A **club message is a broadcast** to *all current members*. There is no recipient
  list to pick (`member_message_live/new.ex`: "this message will be emailed to all N
  current members. There is no list to pick.").
- The **message detail screen** (`page_html/message.html.heex`) is, today, almost entirely
  a **delivery-receipts dashboard**: a big "Message delivery" bar, a per-status legend, and
  "Members by delivery status" groups. It is the *sender's* accountability view — not a
  reading/conversation view.
- **There is no reply affordance anywhere.** Members can start a *new* broadcast (compose),
  or send one by email to the club inbound address. Email replies to a club message go to the
  original human sender (iteration 024) and are **not tracked in Memba**.

**Implication:** "reply" doesn't fit the current model as a tweak. The detail screen needs to
become a **conversation** view, and delivery-status needs to step down to a secondary role.

## 3. The pivotal decision: who receives a reply?

Everything else follows from this. Three models:

| Model | Reply goes to… | Feel | Noise risk | Matches problem? |
|---|---|---|---|---|
| **A. Reply-all** | the whole club (another broadcast in the conversation) | group mailing list | **High** — every reply hits 142 inboxes | Conversations ✓, but no opt-in; floods everyone |
| **B. Reply-to-sender** | only the original sender (private) | 1:1 email | Low | Not a shared conversation; fails "tracked as a conversation" + "opt in to receive replies" |
| **C. Conversation + opt-in follow** ⭐ | the **conversation**, emailed to **followers** only | forum conversation you can subscribe to | Controlled | ✓ all four bullets |

### Recommendation: **Model C — conversation with opt-in follow**

- A reply is posted to a **conversation** attached to the original message; it's visible in Memba
  on the message page.
- **Followers** receive the reply by email. Auto-followed: the original sender and anyone who
  has replied. Everyone else **opts in** with a "Follow this conversation" toggle (default off, so a
  142-member club doesn't get mailing-list noise).
- This is the only model that satisfies *"replies are tracked as part of the conversation"* **and**
  *"members can opt in to receive replies."*

This is a genuine product call — A/B/C is the one thing I most want your read on. Mockups below assume **C**.

## 4. Screen changes

### 4.1 Message detail → **conversation view** (the big change)

Reframe the detail page around reading + replying. Delivery status becomes a collapsed
secondary panel (still one tap away for the sender, but no longer the headline).

```
┌─────────────────────────────────────────────┐
│  ← Club home                                   │
│                                                │
│  CLUB MESSAGE                                  │
│  Saturday ridge walk                           │
│  From Eira Sandhu · to 142 members · 3 Jun     │
│                                                │
│  Meeting at the trailhead 8am sharp. Bring     │
│  microspikes — north side still has ice.       │
│                                                │
│  ┌─ [☑ Follow this conversation]  get replies by ──┐ │
│  │   email. You can stop any time.            │ │
│  └────────────────────────────────────────────┘
│                                                │
│  ▸ Delivery: 142 delivered · 0 sending  (tap)  │  ← collapsed; was the whole page
│  ───────────────────────────────────────────  │
│  REPLIES · 3                                   │
│                                                │
│   ◐ Phil Dunbar · 3 Jun 9:14am                 │
│     I can bring a spare set of spikes.         │
│                                                │
│   ◐ Marta Wiśniewska · 3 Jun 9:40am            │
│     Carpool from the north lot? I have 3 seats.│
│                                                │
│   ◐ You · 3 Jun 10:02am                        │
│     Grabbing a seat with Marta, thanks!        │
│                                                │
│  ┌──────────────────────────────────────────┐ │
│  │ Write a reply…                            │ │
│  │                                            │ │
│  │                          [ Post reply  ↵ ] │ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

Notes:
- **Reply composer is inline** and lightweight: just a body. No subject — replies inherit the
  conversation ("Re: Saturday ridge walk"). This reuses the blank-body validation already in compose.
- **Follow toggle** sits right under the original message; replying auto-follows you.
- **Delivery panel** collapses to a one-line summary (`status_badge` row); expanding reveals
  today's receipts UI unchanged. Sender still gets full accountability; readers aren't buried in it.

### 4.2 Club-home message row → show the conversation, not just receipts

Today each row shows a receipt mini-bar + "142 delivered". Add a reply signal so the list reads
as conversations:

```
┌─────────────────────────────────────────────┐
│  ES   Eira Sandhu                       3 Jun  │
│       Saturday ridge walk                      │
│       💬 3 replies · last 10:02am   ▸          │   ← new: reply count + last activity
└─────────────────────────────────────────────┘
```

The receipt mini-bar can stay for the sender's own messages, or move behind the delivery panel —
open question (see §6).

### 4.3 Reply notification email (followers only)

```
  Kootenay Alpine Club via Memba
  Re: Saturday ridge walk

  Phil Dunbar replied:
  ──────────────────────────────
  I can bring a spare set of spikes.
  ──────────────────────────────
  In reply to Eira Sandhu: "Meeting at the trailhead 8am sharp…"

  [ View the conversation ]

  You're following this conversation.  ·  Stop following
  ── Memba footer ──
```

- Reuses the existing transactional email layout + footer + "via Memba" sender (iteration 024/031).
- **Reply-by-email**: if reply-to points at the conversation address, a follower can reply from their
  inbox and it lands back in the conversation. That needs inbound email routing (the conversation-addressed
  reply address; Message-ID / In-Reply-To / References as a secondary check) — a real capability, built in
  iteration 041, not assumed by these mockups.

### 4.4 Compose — unchanged

Starting a *new* club message is still the broadcast compose flow. A reply is **not** compose;
it's the inline composer in §4.1.

## 5. What this implies for the domain (sketch only — not a plan)

These are consequences to size later, not decisions:

- A **conversation** concept (the original message is the conversation root; replies belong to it).
- A **reply** message type that targets the conversation, not a fresh broadcast.
- A **follow/subscription** per (member, conversation), with auto-follow on send/reply.
- Reply delivery goes to **followers**, reusing the existing send/receipt machinery.
- Inbound email reply threading (optional, larger) if we want inbox replies to land in the conversation.

## 6. Open questions for Matt

1. **Audience model A / B / C?** (I recommend **C**.)
2. **Default follow state for recipients:** off (opt-in, my recommendation, low noise) — or on?
3. **Who can reply?** Any current member, or admins only / sender-configurable?
4. **Reply-by-email in v1?** Or in-app replies first, inbound threading as a follow-up?
5. **Delivery receipts placement:** collapse behind a panel for everyone (my sketch), or keep
   full receipts for the sender's own messages?

## 7. Suggested slicing (if we proceed)

This is too big for one iteration. Likely order:
1. **Conversations + in-app replies** (read/post replies in Memba; no email yet) — smallest useful slice.
2. **Follow + reply notification emails** (opt-in, followers get emails).
3. **Reply-by-email threading** (inbound References/In-Reply-To) — largest, optional.

Plus a **DS** pass to add the conversation previews once the model is chosen.

## 8. Decisions (2026-06-19) — sketch resolved

The open questions in §6 are now decided; this sketch is implemented across iterations 039–041.

- **Audience model: C** (conversation + opt-in follow). Terminology is **"conversation"** everywhere; the follow control reads *"follow this conversation to receive any new replies."*
- **Who can reply:** any current member of the club.
- **Default follow state:** off (opt-in); the original sender and anyone who replies auto-follow.
- **Slicing (revised from §7):**
  1. **039 — Club message conversations and replies:** post/read replies in a conversation; a reply is emailed to **all current members** (interim reply-all, reusing existing delivery). No follow yet.
  2. **040 — Follow a conversation, send replies to followers:** introduce follow (auto for sender/repliers, opt-in for others) and **narrow** reply delivery from all members to followers. This removes 039's reply-all.
  3. **041 — Reply by email:** inbound replies land in the conversation via a conversation-addressed reply address.
- **Reply email address schema (extensible — room for groups/channels later):** one inbound domain `clubs.memba.io`; typed, dot-segmented local part under the club slug:
  - `<club-slug>@clubs.memba.io` → club-wide (today).
  - `<club-slug>+c.<token>@clubs.memba.io` → a conversation (reply target; iteration 041).
  - `<club-slug>+g.<group>@clubs.memba.io` and `…+g.<group>.c.<token>` → **reserved** for future groups/channels.
  - Matching is by the address token (robust); `In-Reply-To`/`References` are a secondary check.
- **Reply email — show the whole conversation, but lean on the client to fold it.** The branded body is just the new reply + "View the conversation" CTA + footer (with "you're following · stop following" from 040). Earlier messages are emitted as a **standard quoted thread** (`blockquote.gmail_quote` + "On <date>, <name> wrote:") so Apple Mail/Gmail fold ("See more" / "•••") and thread it natively via the 041 headers. We do **not** build a custom fold (`<details>` is unreliable in email) or inline a branded full history (it would double the thread in clients that thread by headers). DS design: `emails/reply-notification.html`.
- **One canonical email design; earlier slices omit elements.** The DS card `emails/reply-notification.html` is the **final (040) version** — including the "you're following · stop following" footer. Iteration 039 renders the *same* email minus that follow-footer line (039 has no follow concept yet). We do not keep a separate per-iteration card; earlier iterations just leave parts out.
- **Delivery-receipts placement (§6 Q5):** still open as a UI detail; the conversation view may demote receipts to a secondary panel, decided during 039 implementation.
