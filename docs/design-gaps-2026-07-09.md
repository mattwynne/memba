# Design gap pass — iterations 044–049 vs claude.ai/design

**Date:** 2026-07-09

**Method:** Pulled the current designs directly from claude.ai/design (project `bc97cfc3-…`,
via the `DesignSync` tool) rather than trusting the local `design-system/` mirror, and diffed
them against the actual Phoenix templates/LiveViews that shipped in iterations 044–049 (shared
app shell, section tabs, conversation-page alignment, delivery-details extraction, named member
rows, role badges). Confirmed the local mirror is byte-identical to the cloud for every file
checked (`club-home`, `member-conversation`, `delivery-details`, `staff-console`,
`invite-a-member`, `check-email-delivery-progress`), so `design-system/` can be trusted as the
comparison target going forward without re-pulling every time.

Ran an extended `./bin/dev gallery-walk` (scenes added below) to get real screenshots of every
surface this pass covers, including the Members tab and the staff/admin area, neither of which
the gallery walked before. See `tmp/gallery/gallery.html` for the full set.

Supersedes `docs/design-gaps-2026-07-04.md` for the surfaces it covers; extends it into the
staff/admin area and the member-list join-date question it left open.

**Gallery coverage added this pass** (`acceptance-tests/gallery/scenes.js`,
`acceptance-tests/gallery/walk.js`):
- `member-club-home-members-tab` — the Members tab (previously ungalleried; this is where role
  badges and named rows from iterations 048/049 actually live).
- `member-club-invitation-new` — member-facing "Invite a member".
- `staff-clubs-index`, `staff-club-show`, `staff-requests-index`, `staff-request-review`,
  `staff-people-index`, `staff-deliveries-index`, `staff-messages-index`,
  `staff-invite-member-new` — the whole staff/admin area, signed in as a `@memba.io` staff
  identity via a new `signInStaff` helper in `walk.js`.

This directly closes gap #13 from `docs/design-gaps-2026-06-28.md` ("the gallery walk does not
cover many current design surfaces") for the member and staff areas, including the
request-conversion flow (`staff-request-review` drives the real "Convert" click-through rather
than guessing a request ID). Still not galleried: `profile-completion`, `onboarding-request-flow`
(need a seeded invitation/request-token email flow to drive) — left for a follow-up gallery pass.

---

## How to read this pass

Several design-system files carry a `Design-system catch-up` eyebrow and a "mirrored from the
shipped app" subtitle: `invite-a-member.html`, `check-email-delivery-progress.html`,
`profile-completion.html`, `admin-request-review.html`, `onboarding-request-flow.html`,
`member-empty-first-run-states.html`. These were captured **from** the app after the fact
(iterations 036/037), not designed **for** the app. Diffing the app against them will always
look clean by construction — they are not a live target, and finding no gap there isn't
evidence of nothing to check. This pass spot-checked `invite-a-member` and
`check-email-delivery-progress` for drift since capture and found none; it did not re-derive
every one.

The forward-looking design targets — where drift is meaningful — are `club-home.html`,
`member-conversation.html`, `delivery-details.html`, and `staff-console.html`. Those are where
this pass concentrated.

---

## Gaps, most-valuable first

### 1. Conversation list rows are missing the message preview and participant avatar-stack

**Design (`club-home.html`, Conversations panel):** each row shows subject, date, a one-line
**preview/excerpt of the message body**, an **avatar-stack of participants** ("ES PD KW +8"),
and "N replies · last Xm ago".

**App (`club.html.heex:115-173`):** each row shows an avatar (originator only), subject,
"Started by {name}", and a reply-activity label ("N replies · latest from {name}"). There is
**no body preview and no participant avatar-stack**.

**Root cause:** `MemberDashboardPresentation.present_message_rows/2`
(`member_dashboard_presentation.ex:107-138`) already carries `body` in every row — it's simply
never rendered. The avatar-stack is a real gap: nothing in `Messaging.list_conversations_for_club/1`
aggregates the distinct set of participants for a conversation, so that part needs a new query,
not just a template change.

**Impact:** members scanning the club home can't tell what a conversation is about, or who's in
it, without opening it. This is the single highest-value/lowest-cost gap — the preview text is a
one-line template change with data that already exists.

### 2. Member rows are missing "member since {date}"

**Design (`club-home.html`, Members panel):** every row shows a meta line — "You · member since
Jan 2022", "Member since 2015", etc.

**App (`club.html.heex:274-286`):** the meta line only ever shows "You" for the current member,
or is empty for everyone else.

**Root cause:** `Membership.list_active_members_of_club/1` (`membership.ex:595-630`) selects
`membership_id`, `id`, `name`, `email`, `roles` — it doesn't select `membership.inserted_at`,
even though `Membership.Projections.Membership` already has it via `timestamps()`. **The data
already exists in the projection; it's just not selected or passed through.**

Iteration 049 explicitly deferred this ("member-since dates" is listed as out of scope), so this
isn't a bug in 049 — it's the next slice in the same list, now that named rows and role badges
are both shipped.

**Caveat to confirm before building:** `membership.inserted_at` is when the *membership
projection row* was created. For memberships imported/backfilled rather than joined-in-app, this
may not equal the club's real-world join date.

**Resolved with Matt (2026-07-09):** confirmed — real clubs will have migrated/imported
membership history, so `membership.inserted_at` is **not** an acceptable "member since" date.
This needs its own feature with an import-aware join date (e.g. a dedicated `joined_at` populated
by import tooling where relevant), not a one-line query change. Pulled out of iteration 050
entirely; not yet scheduled.

### 3. Conversation page: two small elements the refreshed design dropped

Comparing `page_html/message.html.heex` against the current `member-conversation.html` (the
version reconciled for iteration 044, i.e. after cards/kebab-menu/follow-toggle/delivery-details
extraction — most of the earlier `docs/design-gaps-2026-07-04.md` gaps #4–#7 are now resolved by
iterations 046/047):

- **Extra "ORIGINAL MESSAGE"/"REPLY" badge** — `conversation_entry_label/1` in `page_html.ex`
  renders an uppercase pill badge on every message/reply card
  (`data-testid="member-conversation-entry-label"`). The current design differentiates the
  original message only by card tint/ring, with no text badge at all.
- **Extra "From {sender}" meta line** — `message.html.heex:85-87` renders a `From {sender_name}`
  paragraph under the title/follow-toggle row. The design has no such line; sender name and time
  already appear once, on the original-message card itself. This is a duplicate of information
  shown a few lines below.
- **The subject renders as an oversized hero headline.** Confirmed in
  `tmp/gallery/app__member-message-read__desktop.png` — "Saturday ridge walk" renders at
  `text-4xl`/`sm:text-5xl` (`message.html.heex:29-34`), the same scale as a marketing splash
  headline. The design's `.page-title` class (`member-conversation.html`) is a normal page
  heading, not a hero — this is the most visually obvious gap in the screenshot, more so than the
  badge/meta-line items above.

**Impact:** minor visual clutter for the badge/meta-line items, not functional gaps. The oversized
title is a bigger visual miss — it makes every conversation look like a landing page. All three
are low-risk, high-confidence cleanup, worth confirming intent before removing/resizing since
dropping UI or shrinking a heading is still a product call.

### 3a. Club home: a duplicated "Invite member" button, and headings the design doesn't have

Confirmed in `tmp/gallery/app__member-club-home-members-tab__desktop.png`: the Members tab shows
**two "Invite member" buttons at once** — one in the section-tabs action slot (top right, matches
design) and a second, redundant one inline in the "Current members" section header
(`club.html.heex:213-221`). The design has exactly one invite action per section, in the tab-row
slot only.

Similarly, both panels have a heading the design doesn't: "Recent club messages" (Conversations)
and "Current members" (Members) — `club.html.heex:84-87, 209-211`. The current `club-home.html`
design's panels have no heading at all; they go straight from the tab row into the list. Low
priority on its own, but worth fixing alongside the inline Invite-member button since it's the
same two sections.

### 4. Club home has no "About" tab

**Design (`club-home.html:66-69`):** three tabs — Conversations, Members, **About** — with the
About panel showing free-text club description copy ("We're a group of 142 folks based out of
Nelson, BC…").

**App (`club.html.heex:17-45`, `router.ex:69-70`):** two tabs only — Conversations, Members. No
About route, panel, or data.

**Root cause:** this isn't a rendering gap — there's no club "about/description" field anywhere
in `Membership.Projections.Club`. This is a real missing feature, not a polish item, and needs a
product decision before it can be scoped (see Open Business Decisions below): where the copy
comes from, and who can edit it.

**Impact:** low urgency (nothing today claims to show it), but it's a checked-in tab in the
canonical design that doesn't exist in the app at all, so a gap pass should surface it.

### 5. Conversation page and club-home rows don't reuse the design system's own CSS classes

This is a structural finding, not a single visual bug. `web/assets/css/app.css` already carries
faithful, exact-name ports of several design-system component classes — `.app-frame`,
`.app-card`, `.app-bar*`, `.section-tab*`, `.member-row*`, `.detail-head*`, `.follow-toggle*`,
and the full `.delivery-*` family. Those surfaces (top shell, tabs, member list, follow toggle,
delivery details) match the design closely because the app is **using the design system's own
CSS**, not reimplementing it.

But `.conversation` / `.conversation__*` / `.avatar-stack` (club-home conversation rows) and
`.message` / `.message__*` / `.composer*` / `.page-title` / `.about*` (the conversation page and
its composer) exist in the design system's CSS and **do not exist anywhere in `app.css`**. Those
surfaces are hand-rolled with Tailwind utility classes directly in the `.heex` templates instead.

**Impact:** two consequences, not just cosmetic risk:
1. Any future spacing/color/typography tweak to `.message`/`.conversation` in the design system
   won't propagate here — these two surfaces are the ones most likely to silently drift again.
2. It's the reason gaps #1 and #3 above exist in the first place — without the shared classes,
   there's no structural home for a preview line or an avatar-stack to slot into.

**Suggested fix shape:** port `.conversation`/`.conversation__*`/`.avatar-stack` and
`.message`/`.message__*`/`.composer*`/`.page-title` into `app.css` (mechanical, same pattern
already used for `.member-row*`/`.follow-toggle*`), then rewrite `club.html.heex`'s conversation
list and `message.html.heex` to use them instead of ad hoc Tailwind. This is naturally the same
piece of work as gap #1 and #3, not a separate effort.

### 6. Two staff-console designs disagree; the app matches the simpler one

Corrected after reviewing the actual gallery screenshots (`app__staff-clubs-index__desktop.png`
etc.) — code-reading alone was misleading here.

**The app already has a persistent sidebar rail.** `Layouts.admin` (`layouts.ex:125-…`) ships a
left rail with the Memba mark + "Staff" chip, an "Operations" group (Clubs/Requests/People), a
"Messaging" group (Messages/Deliveries), and a staff-identity block pinned to the rail footer —
this is not a gap.

**The reason it looked like a gap from code alone:** there are **two different staff-console
designs checked into `design-system/`, and they disagree.**

1. `staff-console.html` (pulled 07-04, its own dedicated file) — a more elaborate rail with
   **Roles** as a fourth nav item, **counts next to each nav item** ("Clubs 47", "Members 6.2k"),
   a **search bar** in the top bar, and a clubs table with **Members/Plan/Status columns and
   colored status pills** (Active/Paused/Trial).
2. The `.admin-shell` embedded inside `invite-a-member.html`'s "mirrored from the shipped app"
   catch-up doc — a simpler rail with no Roles item, no counts, no search, matching exactly what
   `Layouts.admin` renders today (confirmed class-for-class: `.admin-sidebar`, `.staff-brand`,
   `.staff-chip`, `.admin-nav-link--active`, `.staff-identity` all match `layouts.ex` verbatim).

The app matches (2) faithfully. It does not have (1)'s Roles nav item, per-item counts, search
bar, or the clubs table's Members/Plan/Status-pill columns (the shipped clubs table shows
Club/Slug/Identifier/Open instead — operationally useful for staff, but not what either design
shows).

**Impact:** this is the same "two designs, no canonical one chosen" problem flagged for club-home
in `docs/design-gaps-2026-06-28.md` gap #3, now showing up on the staff side. Before scoping any
staff-console work, someone needs to decide whether `staff-console.html`'s richer table (member
counts, plan/status) is the intended direction or a stale exploration — that's a product question,
not a build question, so it's listed here rather than folded into iteration 050.

### 7. Minor: identity dropdown is missing the membership-status line

**Design (`member-conversation.html` app-menu):** the identity dropdown shows an
`app-menu__status` row — "● Active member · since Jan 2022" — above the Sign out button.

**App (`layouts.ex:328-359`):** the dropdown (`app-menu app-menu--id`) only has the Sign out
button.

**Impact:** cosmetic, low priority; noted for completeness since it's the same dropdown
component already faithfully ported everywhere else.

---

## Not re-verified this pass

`profile-completion.html`, `onboarding-request-flow.html`, `member-empty-first-run-states.html` —
"design-system catch-up" mirrors (see note above), and none of the shipped iterations since their
capture (044–049) touch those flows. Spot-checking these against a fresh cloud pull is reasonable
before the next iteration that touches onboarding, but wasn't the focus here.

`admin-request-review.html` turned out to be coverable after all — the new `staff-request-review`
gallery scene drives the real `/admin/requests` → convert flow
(`app__staff-request-review__desktop.png`) and it matches its catch-up mirror closely (same
summary-card layout, same "Prepare conversion" panel, same inbox table). No gap found.

## Suggested slicing order

1. **Iteration 050 (ready — [plan](iterations/050-club-home-conversation-and-member-row-fidelity/plan.md)):**
   conversation-row preview text (CSS line-clamp), the duplicate Invite-member button, and the
   conversation page's dropped badge/meta-line/oversized headline/headings (#1's preview half,
   #3, #3a). Member-row join dates (#2) were pulled out after review with Matt — see below.
2. **Not yet scheduled:** member-row join dates (#2) — needs a dedicated import-aware join-date
   feature, not a query tweak. Confirmed with Matt that `membership.inserted_at` alone isn't
   trustworthy once real clubs' migrated membership history is in play.
3. **Follow-up (sequencing not yet decided):** conversation participant avatar-stack (#1's
   avatar-stack half) — needs a new participants query, bundle with the CSS-class port (#5) since
   they touch the same templates.
4. **Follow-up:** port `.conversation*`/`.message*`/`.composer*`/`.page-title` into `app.css` and
   rewrite the two templates to use them (#5) — do this alongside whichever of #1/#3 lands next,
   since it's the same files.
5. **Own iteration, later:** club "About" tab (#4) — blocked on a product decision about where the
   copy comes from.
6. **Product decision first, then its own iteration:** staff console (#6) — decide whether
   `staff-console.html`'s richer table/search/counts is the direction, or the simpler shipped
   shell is fine and that file should be retired/reconciled instead.
7. **Low priority, anytime:** identity-dropdown status line (#7).
