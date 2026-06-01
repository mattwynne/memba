# Member-facing message behaviour

Date: 2026-06-01
Status: ready

## Goal

Make the member message acceptance scenarios prove member-facing behaviour through authenticated member sessions, and build the member screens those scenarios need.

After this iteration, a club member can sign in, open their club, send a message to every active member, open that message, and see simple receipt statuses for everyone addressed. Staff/admin routes may still be used by tests to arrange data, but member `When` and `Then` steps must use a browser session authenticated as a member.

## Background / Context

The shared member deliverability scenarios currently describe member behaviour but the browser step definitions exercise the staff admin harness for action and verification. That hides an important product gap: ordinary members do not yet have a useful message journey.

Recent foundations now make this slice possible:

- Iteration 009 split public, staff-admin, and club-site surfaces.
- Iteration 010 added shared magic-link authentication and temporary `?club_id=` club-member access.
- A pre-iteration change now excludes `@wip` scenarios from both browser and domain Cucumber runners by default, documented in `acceptance-tests/README.md`.

Design reference files have been expanded into this iteration folder under `designs/`. The most relevant files are:

- `designs/Member Messaging Wireframes.html`
- `designs/wireframes/dashboard.jsx`
- `designs/wireframes/compose.jsx`
- `designs/wireframes/receipts.jsx`
- `designs/wireframes/icons.jsx`

## Scope

### In scope

- Rework member browser acceptance support so member behaviour runs as an authenticated member:
  - setup may use staff/admin routes;
  - member `When` and `Then` steps must sign in as the named member and use member-facing routes/pages.
- Replace member-facing scenario assertions that inspect staff/operator delivery details with member-visible outcomes.
- Add member-facing club messaging screens using the club-site surface:
  - club home/member dashboard with recent messages, active members, and a send-message action;
  - compose club message screen or state;
  - message detail/receipt screen.
- Allow any active member to send a message to every active member of their club.
- Treat the sender as an addressed recipient for now.
- Show every club member the same simple receipt statuses for every addressed member of a club message.
- Display internal receipt status `sent` as the member-facing label `Sending`.
- Display member-facing status labels with icons:
  - `sent` → `Sending`, clock/progress icon;
  - `delivered` → `Delivered`, delivered/check-mail icon;
  - `delivery problem` → `Delivery problem`, warning/problem-mail icon;
  - `opened` → `Opened`, open-mail/eye/read icon.
- Keep staff/operator delivery diagnostics separate from member screens.
- Keep `dev check` green.

### Out of scope

- Custom club domains or host-based club resolution.
- Changing the underlying messaging projection vocabulary; this slice changes member-facing labels only.
- Excluding the sender from message recipients; sender receives their own message for now.
- Technical delivery IDs, provider statuses, webhook metadata, or raw delivery records on member pages.
- Bulk recipient selection; a club message goes to every active member.
- Rich drafts, scheduling, attachments, templates, or replies.
- Changing operator deliverability scenarios except where implementation needs shared setup helpers to coexist.
- Changing Postmark webhook behaviour.

## Iteration Type

Behaviour-facing.

User-observable rule changed: member-message acceptance must now be proved through the member product surface, and members can see simple receipt statuses for everyone addressed to a club message.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

The shared feature file `acceptance-tests/features/member_message_deliverability.feature` is updated as future-facing `@wip` planning language for this slice. The `@wip` tag is intentional: the scenarios describe the member-facing product behaviour to implement and are excluded from both Cucumber runners until this iteration removes the tag by making them pass.

Scenario summaries:

- `Alice sends a club message`: Alice sends a message as an authenticated club member, sees it in the club, sees Alice/Bob/Carol/Dana addressed, does not see Pat, and sees all addressed receipts initially as `Sending`.
- `Alice sees different receipt statuses for different members`: after provider events, Alice sees Bob `Delivered`, Carol `Delivery problem`, Dana `Opened`, and Alice `Sending`.
- `Bob sees the same shared receipt statuses`: another member sees the same member-facing simple statuses for the message.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: replace the old member scenarios with member-facing product scenarios tagged `@wip`. Remove assertions about delivery records, provider delivery, and test mailbox from this member feature because those are staff/operator or integration concerns.
- Implementation may remove the `@wip` tag once the scenarios pass through the browser runner as authenticated members.
- Implementation may make small wording adjustments to keep step language business-readable, but must preserve the rules above.
- Implementation may update operator/staff feature files only if extracting staff/operator-only expectations from the old member feature requires preserving coverage elsewhere. Any such change must keep operator language staff-facing.

## Acceptance Criteria

- The member feature no longer uses member scenarios to assert staff/operator-only delivery details.
- Browser step definitions for member `When` and `Then` steps authenticate as the named member and use member-facing pages.
- Browser step definitions may use staff/admin routes only for `Given` setup.
- Alice can send a club message from the member-facing club surface.
- A club message is addressed to every active member of that club, including the sender for now.
- Members from other clubs are not addressed and are not shown as addressed.
- A member can open a sent club message from a member-facing route/page.
- Any club member can see every addressed member's simple receipt status for that message.
- Member-facing status labels are `Sending`, `Delivered`, `Delivery problem`, and `Opened`.
- Each status label is accompanied by an appropriate icon in the member UI.
- Member pages do not expose delivery IDs, provider event names, webhook metadata, raw provider statuses, or operator-only diagnostics.
- Staff/operator deliverability pages continue to expose detailed statuses/reasons separately.
- The expanded design references remain in the iteration folder for implementers.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Business decisions intentionally deferred:

- Whether senders should receive their own messages long-term.
- Whether message sending should later be limited to certain roles.
- Whether ordinary members should always see all receipts, or whether that later becomes role-dependent.
- Final custom-domain club-site URL shape.

## Implementation Plan

1. Inspect the current authenticated club-site routes and member homepage implementation.
2. Inspect the design references in `docs/iterations/011-member-facing-message-behaviour/designs/`, especially the member messaging wireframes and status icon mapping.
3. Update acceptance support:
   - keep or extract `withStaffHarness` for setup only;
   - add `withMemberHarness(world, memberName, action)` that signs in by magic link using the member email, opens member routes, shares scenario state, and closes its browser context;
   - fail clearly if member `When`/`Then` helpers try to use `/admin/*` pages.
4. Update member step definitions so:
   - `When Alice sends...` signs in as Alice and submits the member compose flow;
   - `When Alice/Bob views the message...` signs in as that member and opens the member message detail;
   - receipt assertions read member-facing rows/labels/icons from the member page.
5. Add or refine member routes/pages:
   - member club home lists recent messages and active members and offers a send-message action;
   - compose message form sends to all active members;
   - message detail page shows subject/body/sender and grouped or listed member receipt statuses.
6. Reuse existing `Memba.Membership` and `Memba.Messaging` APIs where possible.
7. Add presentation mapping for member receipt labels/icons without changing internal projection values.
8. Ensure authorization checks use the signed-in identity and active membership for the selected club.
9. Keep staff/admin diagnostics available on `/admin/*` and separate from member pages.
10. Remove `@wip` from `member_message_deliverability.feature` once the browser scenarios pass.
11. Update low-level tests only where needed to cover route authorization, status label mapping, and member page rendering.
12. Run `dev check` and fix regressions.

## Open Technical Decisions

- Exact route shape for member message detail while custom domains are deferred. Prefer a member-facing route guarded by active membership and carrying `club_id` temporarily, for example a path under the current club-site surface rather than `/admin/messages/:id`.
- Whether compose is a separate route/page or a prominent section/modal/state from the club home. The design reference includes a separate compose screen; implement whichever is simplest while preserving the journey.
- Whether receipt statuses are displayed as grouped sections with counts/summary bar, or a simple table/list. The wireframe suggests grouped statuses with a summary bar; implementation can start simpler if the acceptance behaviour and icon labels are clear.
- Exact icon source. Prefer existing `<.icon>`/Heroicons or small inline components already permitted by project conventions.

## New Capability

Memba can prove member-message behaviour through the actual member experience. Members can send a club message and inspect member-friendly delivery receipts for everyone addressed, while detailed delivery diagnostics remain staff/operator-only.

## Validation Plan

- Run `dev check`.
- Browser Cucumber must pass with `member_message_deliverability.feature` untagged.
- Targeted browser validation should prove:
  - setup may use staff/admin routes;
  - Alice sends from an authenticated member session;
  - Alice/Bob view receipt statuses from authenticated member sessions;
  - member assertions do not navigate to `/admin/*`.
- Automated Phoenix tests should cover:
  - member route authorization;
  - status label/icon mapping;
  - member message detail rendering without operator-only fields.
- Manual demo:
  1. Sign in as Alice.
  2. Open Kootenay Mountaineering Club.
  3. Send `Trip planning night` to all members.
  4. Open the message detail page and see all addressed members as `Sending` with icons.
  5. Simulate provider events for Bob, Carol, and Dana.
  6. Refresh/open as Alice and see `Delivered`, `Delivery problem`, `Opened`, and `Sending`.
  7. Sign in as Bob and confirm Bob sees the same shared receipt statuses.
  8. Confirm no member page exposes delivery IDs or provider/webhook terminology.

## Risks / Follow-ups

- The existing acceptance support is staff-harness-heavy; separating setup from member assertions may reveal hidden coupling.
- Query-string `club_id` remains temporary and could make route helpers awkward until custom domains exist.
- The member-facing receipt policy may later need role controls if clubs consider receipts sensitive.
- The sender-included rule is intentionally provisional.
- The design reference is richer than the required slice; avoid implementing unrelated directory/trip/profile features from the expanded zip.
