# Member-facing message behaviour

Date: 2026-06-01
Status: ready

## Goal

Build the member-facing message journey and make the member deliverability scenarios prove behaviour through authenticated member sessions.

After this iteration, a club member can sign in, open their club, send a message to every active member, open that message, and see simple receipt statuses for everyone addressed. Staff/admin routes may still arrange test data, but member `When` and `Then` steps must use a browser session authenticated as the named member.

## Background / Context

Current member-message browser scenarios describe member behaviour but drive the staff admin harness. That hides the actual product gap: ordinary members do not yet have a complete message journey.

Foundations already in place:

- Iteration 009 split public, staff-admin, and club-site surfaces.
- Iteration 010 added shared magic-link authentication and temporary `?club_id=` club-member access.
- A pre-iteration change excludes `@wip` scenarios from both browser and domain Cucumber runners by default and documents this in `acceptance-tests/README.md`.

Design references are included in this iteration folder under `designs/`. Use these files first:

- `designs/Member Messaging Wireframes.html`
- `designs/wireframes/dashboard.jsx`
- `designs/wireframes/compose.jsx`
- `designs/wireframes/receipts.jsx`
- `designs/wireframes/icons.jsx`

## Scope

### In scope

- Member browser acceptance support:
  - `Given` setup may use staff/admin routes;
  - member `When` and `Then` steps must sign in as the named member and use member-facing pages.
- Member club home at the current authenticated club-site entry point `GET /?club_id=<club_id>`:
  - recent messages;
  - active members;
  - send-message form/action.
- Member message detail at `GET /messages/:message_id?club_id=<club_id>` guarded by active membership in that club.
- Message sending from the club home using the existing member-authenticated `POST /?club_id=<club_id>` flow, sending to all active members.
- Sender is addressed like any other active member for now.
- Any active club member can see every addressed member's simple receipt status for a club message.
- Member-facing status display mapping:
  - internal `sent` -> label `Sending`, icon `hero-clock`;
  - internal `delivered` -> label `Delivered`, icon `hero-check-circle`;
  - internal `delivery problem` -> label `Delivery problem`, icon `hero-exclamation-triangle`;
  - internal `opened` -> label `Opened`, icon `hero-envelope-open`.
- Receipt display follows the wireframe's grouped-by-status shape with counts where practical. Each recipient must also have a stable row exposing their name and member-facing status for tests.
- Staff/operator delivery diagnostics remain separate under `/admin/*`.
- Keep `dev check` green.

### Out of scope

- Custom club domains or host-based club resolution.
- Changing internal projection values or Postmark webhook behaviour.
- Excluding the sender from recipients.
- Technical delivery IDs, provider event names, webhook metadata, raw provider statuses, or operator-only diagnostics on member pages.
- Recipient selection, drafts, scheduling, attachments, templates, replies, or rich editor behaviour.
- Role-restricted sending; any active member can send in this slice.
- Implementing unrelated directory/trip/profile features from the design zip.

## Iteration Type

Behaviour-facing.

User-observable rule changed: member-message acceptance is proved through the member product surface, and members can see simple receipt statuses for everyone addressed to a club message.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

`acceptance-tests/features/member_message_deliverability.feature` has been rewritten as `@wip` planning language for this slice. The `@wip` tag is intentional and must be removed during implementation once the scenarios pass through the browser runner as authenticated members.

Scenarios:

- `Alice sends a club message`: Alice sends as an authenticated club member, sees the message in Kootenay Mountaineering Club, sees Alice/Bob/Carol/Dana addressed, does not see Pat, and sees all addressed receipts initially as `Sending`.
- `Alice sees different receipt statuses for different members`: after delivery events, Alice sees Bob `Delivered`, Carol `Delivery problem`, Dana `Opened`, and Alice `Sending`.
- `Bob sees the same shared receipt statuses`: Bob opens the same message as a member and sees the same shared member-facing receipt statuses.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: replace staff/admin-detail assertions with member-facing scenarios. Remove the `@wip` tag once browser implementation passes.
- Implementation may make small wording adjustments to keep Gherkin business-readable, but must preserve the rules above.
- Operator/staff feature files may be changed only to preserve staff/operator coverage intentionally removed from the member feature.

## Acceptance Criteria

- Member scenarios no longer assert staff/operator-only delivery details.
- Member `When` and `Then` step definitions authenticate as the named member and do not navigate to `/admin/*`.
- Alice can send a message from the member club home.
- A club message is addressed to every active member of that club, including the sender for now.
- Members from other clubs are not addressed or shown as addressed.
- Any active member of the club can open the member-facing message detail page.
- The message detail page shows subject/body/sender and addressed members with member-facing receipt labels and icons.
- Status labels shown to members are exactly `Sending`, `Delivered`, `Delivery problem`, and `Opened`.
- Member pages do not expose delivery IDs, provider event names, webhook metadata, raw provider statuses, or operator diagnostics.
- Staff/operator diagnostics continue to work under `/admin/*`.
- `member_message_deliverability.feature` is untagged and passes through browser Cucumber.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Deferred: whether senders should receive their own messages long-term; whether sending later needs roles; whether receipt visibility later becomes role-dependent; final custom-domain URL shape.

## Implementation Plan

1. Inspect current authenticated club-site routes and the design references listed above.
2. Add member acceptance support:
   - keep staff setup helpers for `Given` steps;
   - add `withMemberHarness(world, memberName, action)` that signs in by magic link using the member email;
   - add a guard/helper convention so member action/assertion helpers fail if they reach `/admin/*`.
3. Update member step definitions so:
   - `When Alice sends...` uses Alice's member session and the club-home send flow;
   - `When Alice/Bob views...` uses that member's session and `GET /messages/:message_id?club_id=<club_id>`;
   - receipt assertions read member-facing recipient rows, labels, and icons.
4. Build/refine member club home at `GET /?club_id=<club_id>`:
   - recent messages link to member message detail;
   - active members summary/list;
   - inline compose form/action based on the wireframe's compose design.
5. Add member message detail at `GET /messages/:message_id?club_id=<club_id>`:
   - authorize active membership for the `club_id` query param;
   - ensure the message belongs to that club;
   - show subject, body, sender, and addressed members with grouped receipt statuses and stable recipient rows.
6. Add a presentation mapping for member receipt labels and Heroicons without changing internal projection values.
7. Keep staff/admin diagnostics unchanged on `/admin/messages/:message_id` and `/admin/deliveries`.
8. Add focused tests for member route authorization, message-club ownership checks, status label/icon mapping, and no operator-only fields on member pages.
9. Remove `@wip` from `member_message_deliverability.feature` when browser scenarios pass.
10. Run `dev check`.

## Open Technical Decisions

None known. Route shape, compose placement, receipt display, and icon source are decided in Scope and Implementation Plan.

## New Capability

Memba can prove member-message behaviour through the actual member experience. Members can send a club message and inspect member-friendly receipts for everyone addressed, while detailed deliverability diagnostics remain staff/operator-only.

## Validation Plan

- Run `dev check`.
- Browser Cucumber passes with `member_message_deliverability.feature` untagged.
- Targeted browser evidence proves:
  - setup may use staff/admin routes;
  - Alice sends from an authenticated member session;
  - Alice/Bob view receipt statuses from authenticated member sessions;
  - member assertions do not navigate to `/admin/*`.
- Phoenix tests cover member route authorization, message-club ownership, status label/icon mapping, and member detail rendering without operator-only fields.
- Manual demo script: `docs/iterations/011-member-facing-message-behaviour/manual-demo-script.md`.

## Risks / Follow-ups

- Existing acceptance support is staff-harness-heavy; separating setup from member assertions may reveal coupling.
- Query-string `club_id` remains temporary until custom domains exist.
- The member-facing receipt policy may later need role controls if clubs consider receipts sensitive.
- The sender-included rule is provisional.
- The design reference is richer than this slice; avoid unrelated features.
