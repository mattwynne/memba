# Member dashboard LiveView polish

Date: 2026-06-01
Status: ready

## Goal

Finish the remaining member-facing wireframe work by converting the club home/dashboard to a LiveView and polishing it toward the dashboard designs.

After this iteration, the signed-in club home at `GET /?club_id=<club_id>` is a LiveView member dashboard with a compact “Got something to share?” CTA card, polished recent-message rows with receipt glances, designed empty states, and a compact active-members card. This also records the product architecture decision that member application pages should be LiveViews unless they are genuinely static pages.

## Background / Context

Iterations 011–013 delivered and planned the core member messaging journey:

- 011: member-facing send/view/receipt behaviour;
- 012: LiveView receipt-detail polish;
- 013: LiveView compose flow at `/messages/new?club_id=<club_id>` and removal of the inline compose form.

The remaining design gap is the member dashboard / club home. The current club home is controller-rendered and heavier than the wireframe. It still carries implementation history from the inline compose form. The desired direction is explicit: member app pages should be LiveViews; static pages such as `/about`, `/terms`, and `/privacy` may remain controller/static pages.

Use these exact design references first:

- `docs/iterations/011-member-facing-message-behaviour/designs/Member Messaging Wireframes.html`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/dashboard.jsx`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/receipts.jsx` for the mini receipt-bar/status vocabulary used in message rows
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/wireframes.css`

Relevant current implementation:

- Signed-in `GET /?club_id=<club_id>` is currently rendered by `MembaWeb.PageController.home/2` and `web/lib/memba_web/controllers/page_html/club.html.heex`.
- Iteration 013 plans to replace the inline compose form with a CTA to `/messages/new?club_id=<club_id>`.
- Member message rows already expose stable browser-test attributes such as `data-testid="club-message-row"`, `data-message-id`, `data-message-subject`, and `data-testid="club-message-link"`.
- Active member rows expose stable attributes such as `data-testid="club-member-row"` and `data-member-name`.

## Scope

### In scope

- Convert the signed-in selected-club home/dashboard at `GET /?club_id=<club_id>` to a Phoenix LiveView.
- Preserve the public/logged-out club marketing behaviour for `GET /?club_id=<club_id>` unless implementation finds a safe reason to convert it separately.
- Preserve existing authentication and club-member authorization semantics:
  - logged-out visitors to public club pages still see the public/marketing experience;
  - signed-in users must be active members of the selected club to see the member dashboard;
  - signed-in non-members/inactive members receive existing forbidden behaviour;
  - missing/unknown clubs receive existing not-found behaviour.
- Add or update an ADR recording the product architecture decision: member application pages are LiveViews by default; static marketing/legal pages may remain controller/static pages.
- Polish the member dashboard toward `dashboard.jsx`:
  - club/member chrome remains via `<Layouts.club_site>`;
  - greeting and lede use the compact dashboard tone;
  - “Got something to share?” CTA card links to `/messages/new?club_id=<club_id>`;
  - recent club messages are presented as polished rows with sender/avatar/initials, subject, when/sent metadata when available, and link to message detail;
  - message rows show an at-a-glance member receipt summary/mini bar when receipt data is available;
  - active members are presented as a compact card with avatar stack, count, and explanatory copy;
  - designed empty state for no recent messages;
  - designed empty state for no/first active members where applicable.
- Keep stable DOM/test attributes needed by existing browser acceptance helpers for messages and members, or update helpers deliberately without changing business feature wording.
- Use Phoenix 1.8 and project guidance:
  - LiveView module with `Live` suffix;
  - `<Layouts.club_site>` / existing layout conventions;
  - `<.icon>` for icons;
  - Tailwind classes and app CSS only, no inline scripts, no external assets.
- Add focused LiveView/Phoenix tests for routing/auth, CTA link, empty states, message rows, active-member card, and receipt-glance rendering.
- Keep existing member-message browser scenarios green.
- Keep `dev check` green.

### Out of scope

- Compose LiveView implementation details beyond linking to the route planned in iteration 013.
- Receipt detail expand/collapse behaviour from iteration 012.
- New messaging business rules, recipient selection, roles, drafts, scheduling, attachments, replies, templates, or rich editor behaviour.
- Real-time dashboard updates.
- Custom club domains or host-based club resolution.
- Public marketing-page redesign.
- Staff/operator dashboard changes.

## Iteration Type

Behaviour-facing presentation and architecture alignment.

The underlying messaging business rules do not change. The user-observable improvement is that the club home becomes a polished member dashboard matching the wireframe direction. The technical/product architecture rule is also made explicit: member application pages should be LiveViews by default, except truly static pages.

## Acceptance Scenarios / Feature Files

BDD decision: Not useful for this slice.

No Gherkin changes are planned. Existing scenarios in `acceptance-tests/features/member_message_deliverability.feature` already cover the relevant business behaviour: members can send messages, see messages in the club, and inspect member-facing receipt statuses. Iteration 014 changes dashboard presentation and the LiveView implementation shape, so LiveView/Phoenix tests are the right executable specification.

## Acceptance Criteria

- Signed-in selected-club home at `GET /?club_id=<club_id>` is implemented as a LiveView.
- An ADR records that member application pages should be LiveViews by default, while static marketing/legal pages may remain controller/static pages.
- Existing auth/failure behaviours for selected-club member home are preserved.
- The dashboard shows the club name, current member greeting, and concise lede.
- The dashboard shows a “Got something to share?” CTA card linking to `/messages/new?club_id=<club_id>`.
- The dashboard does not render an inline compose form.
- Recent message rows show sender/member identity, subject, link to member message detail, and stable browser-test attributes.
- Recent message rows show a receipt glance/mini bar when receipt data exists.
- Receipt glance labels/counts use the member-facing status vocabulary, not operator delivery statuses.
- Empty message state is designed and includes a send-message action.
- Active members are shown as a compact card with avatar stack, count, and explanatory copy.
- Existing stable active-member test attributes remain available somewhere on the page or browser helpers are updated deliberately.
- Member dashboard does not expose operator-only details such as delivery IDs, provider event names, webhook metadata, raw provider statuses, recipient email addresses, or failure reasons.
- Existing member-message browser scenarios continue to pass without business-language changes.
- `dev check` passes.

## Open Business Decisions

None known.

Decisions made during planning:

- Club home/dashboard should be a LiveView.
- The architecture decision should be recorded in an ADR so future plans and implementers stop re-litigating controller vs LiveView for member app pages.
- Dashboard polish should finish the remaining wireframe gap without expanding into compose or receipt-detail work.

## Implementation Plan

1. Inspect current `PageController.home/2`, `club.html.heex`, `UserAuth` club-member plugs, route tests, and browser helpers that rely on club-home selectors.
2. Add an ADR, likely `docs/adr/0015-use-liveview-for-member-application-pages.md`, recording:
   - context: member surfaces need interaction and consistent stateful UX;
   - decision: member application pages are LiveViews by default;
   - exceptions: static marketing/legal pages may remain controller/static;
   - consequences: new member pages should not default to controller templates.
3. Introduce a member dashboard LiveView, for example `MembaWeb.MemberDashboardLive`, routed for signed-in selected-club home while preserving public/logged-out handling for `/?club_id=`.
4. Move selected-club dashboard data loading into the LiveView mount path or a small query/presentation helper:
   - selected club;
   - current member derived from authenticated identity;
   - active members with initials/avatar data;
   - recent messages;
   - sender names;
   - receipt summary data for recent message rows.
5. Build message-row receipt glance data using existing member receipt projections and `MembaWeb.MemberReceiptPresentation` where useful:
   - counts by member-facing status;
   - simple percentages/segment widths for the mini bar;
   - human glance copy such as “N of M opened” where data supports it.
6. Render the dashboard toward `dashboard.jsx`:
   - compact hero/greeting;
   - CTA card linking to `/messages/new?club_id=<club_id>`;
   - recent-message list rows with avatar/initials, sender, subject, receipt mini bar, glance copy, and detail link;
   - active-members compact card with avatar stack and count;
   - designed empty states.
7. Preserve or deliberately update stable selectors used by browser acceptance:
   - `club-message-row`;
   - `club-message-link`;
   - `club-member-row` or equivalent accessible member data;
   - message/member data attributes needed by helpers.
8. Remove any remaining inline compose form from club home if iteration 013 has not already done so in the branch being implemented.
9. Add focused LiveView/Phoenix tests for:
   - signed-in active member sees dashboard;
   - signed-in non-member/inactive member receives forbidden;
   - CTA points at compose route;
   - no inline compose form;
   - message rows and links render;
   - receipt glance renders with member-facing vocabulary;
   - empty states render;
   - active-member card renders count/avatar stack;
   - no operator-only fields leak.
10. Run existing browser Cucumber for member-message deliverability and `dev check`.

## Open Technical Decisions

- Exact route organization for sharing `GET /?club_id=<club_id>` between public/logged-out marketing and signed-in member dashboard. Preserve user-visible behaviour over internal neatness.
- Whether message receipt glances are calculated per row in the LiveView or via a presentation/query helper. Prefer a helper if it keeps LiveView mount readable and testable.
- Exact “when” metadata source for message rows if current message projections do not carry sent timestamps. If unavailable, do not invent data; leave that visual detail out or use existing available metadata only.

## New Capability

Members land on a polished, LiveView-backed club dashboard that matches the remaining wireframe direction and gives quick access to compose, recent messages, and active-member context.

## Validation Plan

- Run `dev check`.
- Run targeted LiveView/Phoenix tests for the member dashboard.
- Run `acceptance-tests/features/member_message_deliverability.feature` through the browser runner.
- Manual demo:
  - sign in as Alice;
  - open Kootenay Mountaineering Club;
  - confirm the dashboard is visually aligned with `dashboard.jsx`;
  - confirm “Send club message” opens `/messages/new?club_id=<club_id>`;
  - confirm recent message rows link to message details and show receipt glances where available;
  - confirm active-member card and avatar stack;
  - confirm empty states in a brand-new club;
  - confirm no operator-only delivery details appear.

## Risks / Follow-ups

- Routing `/?club_id=` between public marketing and member LiveView needs care to preserve iteration 010 auth behaviour.
- Receipt-glance data may require efficient projection queries to avoid N+1 reads if many messages are shown.
- Current message projections may not have sent timestamps; avoid blocking the iteration on unavailable metadata.
- This finishes the current member messaging wireframe set; future design work should be planned as new product slices rather than more cleanup.
