# Design gap pass — refreshed design-system mirror vs current app

**Date:** 2026-07-04

**Method:** Pulled the latest designs from claude.ai/design (project `bc97cfc3-…`) into
`design-system/` (see `.design-sync/NOTES.md` → "2026-07-04 pull"), then compared the
refreshed design previews against the current app markup in
`web/lib/memba_web/controllers/page_html/` and the presentation modules. A fresh
`./bin/dev gallery-walk` regenerated the app screenshots in `tmp/gallery/` (Jul 4), which
**visually confirm** the club-home and conversation gaps below. The design-side renders in
`tmp/designshots/` are still from 2026-06-28 and predate today's refresh, so re-render those
locally for a full side-by-side. Supersedes the 2026-06-28 pass in
`docs/design-gaps-2026-06-28.md`.

**What changed since 2026-06-28:** every tracked design screen had drifted — the refreshed
`club-home.html` and `member-conversation.html` are notably different from the versions the
prior pass compared against. The cloud club-home has moved to an **app-like tabbed
interface**, which reframes the biggest gap (see #1).

---

## Gaps, most-valuable first

### 1. Club home: design moved to an app-like tabbed IA; app is still a single scroll

**Design (`wireframes/club-home.html`, refreshed):** an app shell — top bar with a club
switcher and a member-identity dropdown, a **Conversations / Members tab spine**, and one
primary action per section (`New message` on Conversations, `Invite member` on Members).
Conversation rows show a participant avatar-stack + "N replies · last Xm ago".

**App (`page_html/club.html.heex`):** a single scrolling column — hero greeting, a large
"Send a message to the club?" CTA card, a "Recent club messages" list, then a members card.
No tabs, no top-bar club switcher, no per-section action slot.

**Impact:** the design is now an application; the app is a page. This is the largest gap and
is the "app-like interface" direction captured in `docs/design-gaps-2026-06-28.md` and commit
`d49712925`. It's a sizable IA change, so it likely wants its own iteration rather than being
bundled with the smaller fixes below.

### 2. Member list shows no names and no roles

**App:** members render as an avatar stack + count ("142 members"); names live only in avatar
`title`/`data-*`. **Design:** named member rows with **role badges** (Chair / Secretary /
Treasurer / Trip organizer), and `components/badges/badges.card.html` defines the role-badge
variants.

**Root cause (code):** `member_dashboard_presentation.ex` exposes members as `name` + `initials`
only, plus a single boolean `current_member_can_manage_members?`. **No per-member role data
flows to the view.** Closing this needs (a) role data in the membership read model/presentation,
then (b) named rows + role badges in the template. (Carried from 2026-06-28 #1 — still open.)

### 3. Club-home copy is still message-era, not conversation-era

**App copy:** "Read recent club messages…", "Send a message to the club?", "Recent club
messages", "Send club message". The product model is conversations (rows already show reply
counts), but the chrome still teaches one-way messaging. (Carried #2 — still open.)

### 4. Conversation page: delivery receipts still dominate

**App (`page_html/message.html.heex`):** two heavy delivery sections near the bottom — a
"Message delivery" summary card (bar + 2-col legend) **and** a full "Members by delivery
status" grouped, expandable breakdown. **Design (`member-conversation.html`):** delivery is
demoted to **one compact collapsed row** ("All 142 delivered" + expand chevron) directly under
the subject. (Carried #4 — still open.)

### 5. Follow control is a button-in-a-card, not a toggle

**App:** a sage card with a bell icon, heading, and a `Follow conversation` / `Stop following`
button (`phx-click="follow_conversation"` / `"unfollow_conversation"`). **Design:** a
lightweight **toggle switch** — "You're following this conversation" / "You'll get an email
when someone replies. Stop any time." Different interaction model and much lighter weight.
(Carried #5 — still open.)

### 6. Composer sits above the replies, and there's no "Replies · N" heading

**App order:** original → follow → **composer** → replies → delivery. **Design order:**
(collapsed delivery) → follow toggle → original → **"Replies · N" heading → replies →
composer** at the bottom. The app prioritizes writing over reading and omits the reply-count
heading. (Carried #6 — still open.)

### 7. Original-message metadata lacks a timestamp

**App meta:** "From {sender} · sent to {N} members" — no date/time. **Design:** "From Eira
Sandhu · 3 Jun, 7:02am". (Carried #8 — still open; also confirm the reply cards show
per-reply timestamps.)

### 8. Two mobile designs are stale for the replies model (a design gap, not an app gap)

Scope: **`mobile-compose.html` is current** — it's the recently-iterated iOS-style
grouped-inset compose form (Settings/Mail idiom), and is *not* part of this gap.

But `wireframes/mobile-club-home.html` and `mobile-message-detail.html` are **still the
pre-replies, delivery-receipt-heavy, "Recent club messages" designs** (confirmed in both their
HTML and the `mobile.css` `.msg`/`.delbar`/`.grp` components). There is no mobile design target
for the shipped conversation / follow / reply model. This one needs the **design** updated on
claude.ai/design first, then the app. (Carried #9.)

### 9. Stop-following page — mostly aligned; confirm header chrome

**App (`conversation_follow_html/stop_following.html.heex`):** uses `Layouts.app`; success/error
copy already matches the design ("We won't email you new replies…"). Confirm the header is the
**minimal Memba-mark** the design specifies rather than the marketing nav. (Carried #10 — likely
mostly handled by iteration 045; visual check only.)

### 10. Email header policy — now largely reconciled

The refreshed `emails/reply-notification.html` and `emails/inbound-rejection.html` were already
in sync locally, and their design comments now cite the shipped decisions (subject `[slug] Re:`
prefix, `everyone@{slug}.clubs.memba.io` reply-to via header-routing — iter 041/042; rejection
From = "{club} via Memba", Reply-To = help@memba.io, Memba-voiced body). The earlier #11/#12
divergences look closed in the design; worth a quick confirmation against the sent mail, not a
build item.

---

## Not yet re-pulled (deferred; read on demand)

`onboarding-request-flow`, `profile-completion`, `mobile-compose`, the newer emails
(`welcome`, `sign-in-link`, `event-confirmation`, `member-message`, `renewal-reminder`), and
the foundational CSS/brand/guidelines layer. None are implicated in the top gaps above.

---

## Proposed iteration to close the gaps

Two of the gaps are large enough to be their own thing (#1 app-like club-home IA; #8 mobile
design refresh, which is design work first). The highest-value **buildable-now** slice is the
**conversation page**, which is fully specified by the refreshed design and is app-side only:

1. **Conversation page alignment** (all in `message.html.heex`, no new data):
   - Demote both delivery sections to one collapsed "All N delivered" row under the subject (#4).
   - Replace the follow card/button with the toggle control (#5).
   - Reorder to replies-first with a "Replies · N" heading, composer at the bottom (#6).
   - Add the original-message timestamp (and per-reply timestamps) (#7).
2. **Member list names + role badges** (#2, #3) — needs role data in the membership read
   model/presentation, then named rows + badges + conversation-era copy on the club home.
3. **Stop-following header check** (#9) — low-risk visual confirmation/fix.

Deferred to their own iterations: **#1 app-like tabbed club-home IA** (large), and **#8 mobile
conversation design** (update the cloud design first).
