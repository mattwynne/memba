# Replies feature — actuals vs. wireframes gap analysis

**Date:** 2026-06-22
**Method:** Captured live app + dev-mailbox screenshots via `bin/dev gallery-walk`
(`tmp/gallery/`), compared against the claude.ai/design wireframes pulled with `DesignSync`
(project `bc97cfc3-436c-471e-a939-7ba222859282`) and the local `design-system/wireframes/`.

Surfaces covered: messages overview, conversation/message detail (thread + follow + composer),
reply compose states, reply-notification email, stop-following page, inbound-rejection email.

Legend — **type**: `missing` (in design, not in app) · `extra` (in app, not in design) ·
`divergent` (both have it, differently) · `no-design` (app surface has no wireframe) ·
`stale-design` (wireframe annotation contradicts a later shipped decision).

---

## A. Messages overview — club home "Recent club messages"

Actual: `app__member-club-home__*`. Design: `wireframes/member-messaging.html` (§"1 · Club home"),
which predates the replies feature.

| # | Type | Gap |
|---|------|-----|
| A1 | **divergent / missing** | **Replies appear as separate top-level rows.** Seeding two replies to "Saturday ridge walk" produced **three** "Saturday ridge walk" rows in the list (Alice's original + Benji's reply + Carmen's reply), each with its own sender and its own delivery bar (`0 of 1 delivered`, `0 of 2 delivered`, …). The list is not grouped by conversation. |
| A2 | **missing** | **No reply / conversation count.** A conversation is not represented as one row with an "N replies" affordance. (Matches the original request's expectation that the overview "should show at least a reply count".) |
| A3 | **no-design** | There is **no wireframe for a replies-aware overview.** The only club-home wireframe predates conversations and likewise shows neither grouping nor a reply count, so there is nothing to build A1/A2 against yet. |

**Recommendation:** this is the highest-impact gap. The overview needs a conversation-grouped
design (one row per conversation, latest activity + reply count) before the app can be aligned;
right now replies visibly leak into the message list as duplicate rows.

---

## B. Conversation / message detail (thread + follow + composer)

Actual: `app__member-message-read__*`, `app__member-reply-posted__*`.
Design: `wireframes/member-conversation.html` (FINAL/040, with follow toggle).

| # | Type | Gap |
|---|------|-----|
| B1 | **divergent** | **Follow control widget.** Design uses a **toggle switch** ("Follow this conversation to receive any new replies / You'll get an email when someone replies. Stop any time."). App uses a **card with a button** ("You're following this conversation" + a "Stop following" button). Different interaction model. |
| B2 | **divergent** | **Delivery summary prominence.** Design **demotes** delivery to a single **collapsed** one-line row ("Delivery — 142 delivered · 0 sending · 0 problems" + mini bar + chevron) near the top. App renders a large "**Message delivery**" card **and** a full "**Members by delivery status**" expandable section at the bottom — receipts still dominate the page, which is the opposite of the design's intent (sketch §4.1 "demoted from the whole page"). |
| B3 | **divergent** | **Composer placement.** Design puts the reply composer **at the bottom**, after the replies. App puts it **above** the replies (between the follow control and the reply list). |
| B4 | **missing** | **"Replies · N" heading.** Design has a "Replies · 2" count header above the reply list. App has no replies-count heading; replies are just stacked. |
| B5 | **divergent** | **Reply visual treatment.** Design = lightweight rows (avatar + `name · time` + body, separated by hairline rules). App = each reply in its own bordered **card** with a "REPLY" badge. |
| B6 | **missing** | **Per-reply timestamps.** Design shows each reply's time ("3 Jun, 9:14am"). App replies show **no timestamp**. |
| B7 | **missing** | **Sent date on the original.** Design meta is "From X · sent to N members · **3 Jun**". App meta is "From X · sent to N members" with **no date**. |
| B8 | **divergent (app richer)** | **Original-message treatment.** Design renders the original inline under the subject. App boxes it in a card with an avatar + "ORIGINAL MESSAGE" badge. Not necessarily wrong, but it diverges. |
| B9 | **extra** | **Composer chrome.** App composer adds a titled card ("Reply to this conversation"), helper text, a "Replying as <name>" pill, and a "Reply" field label; design composer is a bare textarea with "Write a reply…". |

---

## C. Reply compose states

Actual: `app__member-reply-posted__*`, `app__member-reply-validation-error__*`.

| # | Type | Gap |
|---|------|-----|
| C1 | **no-design** | **Posted confirmation.** App shows a "Your reply is being sent." success banner after posting. No wireframe depicts a post-submit/confirmation state. |
| C2 | **no-design** | **Validation error.** App shows "Reply body can't be blank." on empty submit. No wireframe depicts the error state. |
| C3 | **deferred / not captured** | The dispatch-failure `:failed` state ("Your reply was not sent. Please try again.") is intentionally not captured — it requires fault injection into the production reply path. Recorded as a known uncaptured state. |

---

## D. Reply-notification email

Actual: `emails__5..7-kootenay-alpine-re-saturday-ridge-walk` (dev mailbox).
Design: `emails/reply-notification.html`. Body structure matches well — club lockup + "New reply"
label, "In the conversation" eyebrow + subject, the single new-reply block (avatar + "X replied"
+ "just now" + body), a "View the conversation" CTA, a standard `gmail_quote` quoted history, and
a "Stop following this conversation" footer are **all present** (`member_message_email.ex:249, 272, 420`).

| # | Type | Gap |
|---|------|-----|
| D1 | **divergent** | **Subject prefix.** App subject is `[kootenay-alpine] Re: Saturday ridge walk`; design subject is `Re: Saturday ridge walk` (no `[slug]` mailing-list tag). |
| D2 | **stale-design** | **Reply-To address.** App Reply-To is the club-wide `everyone@kootenay-alpine.clubs-dev.memba.io` with header-based threading (`In-Reply-To` / `References` / `Message-ID` all set). The wireframe's header comment still describes a conversation plus-address (`kootenay-alpine+c.<token>@clubs.memba.io`). Per commit "iteration 041: pivot reply routing to email headers", the app deliberately moved to header-based routing — so the **wireframe annotation is out of date**, not the app. Worth correcting the design note. |

---

## E. Stop-following confirmation page

Actual: `app__conversation-stop-following__*`. No wireframe exists for this page.

| # | Type | Gap |
|---|------|-----|
| E1 | **no-design** | App renders a clean card on the marketing chrome: "CONVERSATION NOTIFICATIONS" eyebrow + "You've stopped following this conversation" + explanatory copy + "View the conversation" button. Reads well; no wireframe to compare against. |
| E2 | **divergent (minor)** | The page uses the **public/marketing nav** (Sign in / Request access). A recipient arriving from an email unsubscribe link sees marketing CTAs — fine, but worth a deliberate design decision. |

---

## F. Inbound-rejection email

Actual: `emails__2-your-email-to-rideau-park-sailing-wasn-t-posted`. Design: `emails/inbound-rejection.html`.
Body matches the design (Memba mark + "DELIVERY NOTICE" label, calm envelope icon, "Your email
wasn't posted", "Sorry — your message to <club> didn't go out…", reason box, etc.).

| # | Type | Gap |
|---|------|-----|
| F1 | **divergent** | **From header brands the club, not the carrier.** App From is `"Rideau Park Sailing via Memba" <messages@mail.memba.io>`. The design's explicit DIAL is "Memba-led — a bounce genuinely comes from the carrier, so Memba speaks", with `From: Memba <post@memba.io>`. The email **body** is Memba-branded per the design, but the **From** still says the club — internally inconsistent and against the stated dial. |
| F2 | **divergent / config** | **Reply-To.** App Reply-To is `"Matt Wynne" <matt@mattwynne.net>` (a dev-config artifact). Design specifies the support address `help@memba.io` ("reply to this email and a person will help"). At minimum a dev-config fix; confirm production points Reply-To at support. |

---

## Summary of the most actionable gaps

1. **A1/A2 — overview leaks replies as separate rows with no conversation grouping or reply count** (and A3: no design exists for the fix). Highest impact; needs a design first.
2. **B2 — delivery receipts still dominate the conversation page** despite the design demoting them to a single collapsed line.
3. **B1/B3/B4/B6 — follow control type, composer placement, missing "Replies · N" header, and missing per-reply timestamps** on the conversation page.
4. **F1 — inbound-rejection From brands the club** instead of Memba-the-carrier, contradicting the design's dial (and the email's own Memba-branded body).
5. **D2 — reply-notification Reply-To / wireframe annotation are out of sync** because reply routing pivoted to email headers; update the wireframe note.

**Deferred / not captured:** the `:failed` reply dispatch-error UI (would need production fault injection).
