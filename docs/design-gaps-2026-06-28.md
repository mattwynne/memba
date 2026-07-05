# Design gap pass — app/gallery vs current local design-system mirror

**Date:** 2026-06-28

**Method:** Ran `./bin/dev gallery-walk`, then compared the generated screenshots in `tmp/gallery/` with rendered local design-system previews in `design-system/`.

**Gallery output:** `tmp/gallery/gallery.html`

**Design screenshots generated for comparison:** `tmp/designshots/`

**Side-by-side comparison images:** `tmp/gap-pairs/`, `tmp/email-pairs/`

This pass updates the earlier replies-focused analysis in `docs/replies-wireframe-gaps.md`. The app has moved on since then: the club home now groups replies into conversations instead of leaking each reply as a separate row.

## Biggest gaps

### 1. Member list does not show member names or roles

**Actual:** The club home “Current members” section is still an avatar stack plus member count. It exposes names only through avatar `title`/data attributes.

**Design / expectation:** Recent discussion expects a visible role chip such as “Club Admin” beside a member. The local `design-system/components/badges/badges.card.html` includes role/admin badge examples, but the local `club-home.html` wireframe does not apply those badges to the member list.

**Impact:** A member cannot tell who the club admins are from the member list. The current Membership query also does not pass role names into the member dashboard presentation.

**Likely slice:** Add a named member list/directory row treatment and role badges for assigned club roles, starting with the built-in Admin/Membership Administrator role.

---

### 2. Club home is partly conversation-aware, but copy is still message-era

**Actual:** The app now shows one row per conversation with reply count/latest reply summary. Good. But headings and copy still say:

- “Read recent club messages…”
- “Send a message to the club?”
- “Recent club messages”
- “Send club message”

**Design:** `design-system/wireframes/member-conversation-overview.html` reframes the surface as conversations:

- “Catch up on club conversations…”
- “Start a conversation?”
- “Recent conversations”
- “Send club message” / conversation framing in row copy

**Impact:** The product model is now conversations, but the UI still teaches members to think in one-way messages.

---

### 3. Club-home designs conflict / local mirror is stale in places

There are now at least two relevant local designs:

- `design-system/wireframes/club-home.html` — older “Recent club messages” design with delivery bars.
- `design-system/wireframes/member-conversation-overview.html` — newer conversation-grouped design.

The running app matches the newer grouping behaviour better than `club-home.html`, but still uses the older copy/chrome. This needs one canonical club-home design.

---

### 4. Conversation page still lets delivery receipts dominate

**Actual:** The conversation page renders:

- a large “Message delivery” card,
- a full delivery status breakdown,
- a separate “Members by delivery status” section.

**Design:** `design-system/wireframes/member-conversation.html` demotes delivery to one compact collapsed row near the top.

**Impact:** The page still feels like a delivery dashboard, not a conversation thread.

---

### 5. Follow control interaction differs from the design

**Actual:** A card says “You’re following this conversation” with a “Stop following” button.

**Design:** A toggle-style control says “Follow this conversation to receive any new replies” / following state copy.

**Impact:** Different interaction model and visual weight. The actual control is heavier and less like a preference/toggle.

---

### 6. Reply composer and reply list order differ

**Actual:** Reply composer appears before existing replies.

**Design:** Existing replies appear first, with a “Replies · N” heading, then the reply composer at the bottom.

**Impact:** The actual page prioritizes writing over reading. It also lacks the explicit reply-count section heading.

---

### 7. Replies are visually heavier and less informative than the design

**Actual:** Replies are separate bordered cards with “REPLY” badges and no visible timestamps.

**Design:** Replies are lightweight rows with avatar, name, timestamp, and body.

**Impact:** The thread is harder to scan, and members cannot see when each reply was posted.

---

### 8. Original message metadata is missing date/time

**Actual:** “From Alice Adams · sent to 4 members”

**Design:** “From Eira Sandhu · sent to 142 members · 3 Jun”

**Impact:** The conversation page lacks a basic time context for the original message.

---

### 9. Mobile conversation designs are stale / missing

**Actual:** The mobile app shows the conversation page with replies, follow control, composer, delivery card, delivery status sections, site footer, and full club header.

**Design:** `design-system/wireframes/mobile-message-detail.html` is still a pre-replies message-detail design focused on delivery receipts. It does not show the conversation/follow/reply model.

**Impact:** There is no clear mobile target for the shipped conversation feature. The app’s mobile page is very long and receipt-heavy.

---

### 10. Stop-following page still has marketing chrome

**Actual:** The stop-following confirmation page uses the marketing header with “Sign in” and “Request access”.

**Design:** `design-system/wireframes/conversation-stop-following.html` shows a minimal Memba header only, plus valid and invalid token states.

**Impact:** Email notification preference flows should feel transactional and quiet, not like a marketing page.

---

### 11. Reply notification email header still diverges from design

**Actual:** Subject includes the club slug prefix: `[kootenay-alpine] Re: Saturday ridge walk`.

**Design:** `emails/reply-notification.html` shows `Re: Saturday ridge walk`.

**Also:** The app uses header-routed replies with `Reply-To: everyone@<club>.clubs-dev.memba.io`; older design annotation has referred to conversation plus-addressing. If header-routing is the product decision, the design note should be updated.

---

### 12. Inbound rejection email header still diverges from design

**Actual:**

- From: `Rideau Park Sailing via Memba <messages@mail.memba.io>`
- Reply-To: Matt’s dev address in the gallery seed/config

**Design:** The body is Memba-led and the design direction says carrier-led rejection email. It expects Memba/support-style sender semantics.

**Impact:** The body says Memba is the carrier, but the From header still makes it look club-sent. The dev Reply-To is also noisy in screenshots.

---

### 13. The gallery walk does not cover many current design surfaces

Current `./bin/dev gallery-walk` covers member home/messages/replies/stop-following/public club page plus emails. It does **not** screenshot these design-system surfaces:

- `wireframes/invite-a-member.html`
- `wireframes/profile-completion.html`
- `wireframes/check-email-delivery-progress.html`
- `wireframes/onboarding-request-flow.html`
- `wireframes/admin-request-review.html`
- staff operations pages / people / club detail / message diagnostics against their designs
- role/member-admin badge usage in an actual member list

**Impact:** We can keep shipping visual drift on whole product areas without the gallery making it visible.

## Suggested slicing order

1. **Member list + role badges** — visible names and “Club Admin”/admin badge support.
2. **Club home conversation copy cleanup** — align headings/copy to the conversation model and pick one canonical club-home wireframe.
3. **Conversation page alignment** — demote delivery, move composer, add reply count/timestamps, simplify reply cards.
4. **Stop-following minimal header** — low-risk visual alignment.
5. **Email header policy cleanup** — decide app-vs-design for subject prefix, rejection From, Reply-To/support address, then update app or design.
6. **Gallery coverage expansion** — add staff, invitation, auth, onboarding, and profile-completion scenes so future drift is visible.

## Notes

- `docs/replies-wireframe-gaps.md` still has useful detail, but its overview row leak finding is now mostly addressed by the current app.
- The local design-system mirror appears internally inconsistent in places. Before implementing larger visual changes, choose the current canonical wireframe for each surface or refresh the mirror from the cloud design system.
