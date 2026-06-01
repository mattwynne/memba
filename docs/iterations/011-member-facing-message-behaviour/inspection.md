# Iteration 011 inspection notes

Selected task: `001 Inspect current authenticated club-site routes and the design references listed above.`

## Current route topology

Confirmed from `web/lib/memba_web/router.ex` and `mix phx.routes`:

- Member/public entry point:
  - `GET /` -> `MembaWeb.PageController.home/2`
  - `POST /` -> `MembaWeb.PageController.send_message/2`
  - Both are in the `[:browser, :club_member_context]` pipeline.
- Authentication:
  - `GET /auth`, `POST /auth`, `GET /auth/magic/:token`, `DELETE /auth`
  - `MembaWeb.UserAuth` stores unauthenticated GET return paths in the `identity_return_to` session key.
- Staff/operator diagnostics:
  - `GET /admin/clubs`
  - `GET /admin/clubs/:club_id`
  - `GET /admin/deliveries`
  - `GET /admin/messages/:message_id`
  - These use the `:staff_browser` pipeline.
- Webhooks/dev support:
  - `POST /webhooks/postmark`
  - development-only dashboard/mailbox/test-support routes.

There is no member-facing `GET /messages/:message_id` route yet.

## Current authenticated club-site behaviour

Current code already has the temporary `?club_id=` club-site seam from iteration 010:

- `MembaWeb.UserAuth.require_active_club_member_if_club_id_present/2`
  - allows logged-out `GET /?club_id=...` to reach the public club marketing page;
  - requires an authenticated active club member for signed-in `GET /?club_id=...` and for `POST /?club_id=...`;
  - returns the existing plain `403 Forbidden` for signed-in users who are not active members.
- `MembaWeb.PageController.home/2`
  - renders a public club marketing LiveView for logged-out `GET /?club_id=...`;
  - renders the member club page for signed-in active members;
  - renders “My clubs” on signed-in `GET /` without a selected club.
- `MembaWeb.PageController.send_message/2`
  - accepts `POST /?club_id=...` from signed-in active club members;
  - verifies the selected sender is an active member of the selected club;
  - dispatches `Messaging.send_club_message/2` with a generated message ID and strong consistency;
  - redirects back to `/?club_id=...` after success.
- `web/lib/memba_web/controllers/page_html/club.html.heex`
  - uses `<Layouts.club_site>`;
  - shows a member home hero;
  - has an inline send-message form;
  - lists active members with stable `data-testid="club-member-row"` rows;
  - lists sent messages with stable `data-testid="club-message-row"` rows;
  - does not link sent messages to a member detail page yet.

Relevant query seams:

- `Membership.list_active_members_of_club/1` returns stable active member rows with `id`, `name`, and `email`, excluding inactive memberships and other clubs.
- `Messaging.list_messages_for_club/1` returns projected messages for a club.
- `Messaging.get_message/1`, `Messaging.list_recipient_deliveries/1`, and `Messaging.list_member_receipts/1` are available for a future member message detail page.

## Design references inspected

Inspected the plan-listed local references:

- `designs/Member Messaging Wireframes.html`
- `designs/wireframes/dashboard.jsx`
- `designs/wireframes/compose.jsx`
- `designs/wireframes/receipts.jsx`
- `designs/wireframes/icons.jsx`

Key design constraints for later implementation tasks:

- Club home/dashboard:
  - signed-in member chrome with club name, current member identity, sign out, and “Powered by Memba” footer;
  - prominent “Got something to share?” send-message call-to-action;
  - recent club messages list with sender/subject and at-a-glance receipt summary;
  - active members summary showing the count and explaining that all current members receive messages.
- Compose:
  - calm single-column form;
  - explanatory note that the message goes to all active members;
  - fields: From, Subject, Message;
  - primary action text equivalent to “Send to all members”.
  - The approved plan adapts this into an inline club-home form rather than a separate compose route.
- Receipts/message detail:
  - back link to club home;
  - subject, sender, sent-to count, and body;
  - “Who got this” summary grouped by status;
  - grouped breakdown order in the wireframe is `Opened`, `Delivered`, `Sending`, `Delivery problem`;
  - each status group has a label, description, count, and icon;
  - each recipient row exposes recipient name plus the member-facing status.
- Icons:
  - the wireframe uses custom `WIcon` names, but project guidance requires Phoenix’s `<.icon>` component.
  - The plan’s required Heroicons mapping for member pages is:
    - internal `sent` -> label `Sending`, icon `hero-clock`;
    - internal `delivered` -> label `Delivered`, icon `hero-check-circle`;
    - internal `delivery problem` -> label `Delivery problem`, icon `hero-exclamation-triangle`;
    - internal `opened` -> label `Opened`, icon `hero-envelope-open`.

## Constraints and gaps handed to following tasks

- Keep staff diagnostics on `/admin/messages/:message_id` and `/admin/deliveries` unchanged.
- Do not expose operator-only fields on member pages: delivery IDs, provider event names, webhook metadata, raw provider statuses, or reason diagnostics.
- Add member `GET /messages/:message_id?club_id=...` under the authenticated club-member rules; it must ensure the message belongs to the selected club.
- Update club-home message rows to link to the member detail route when that route exists.
- Add presentation mapping without changing ADR 0006 internal projection values.
- Use Phoenix 1.8 conventions: no custom Heroicons modules, use `<.icon>`, and be careful with router scope aliases.

## ADR conformance notes

- ADR 0001: keep the implementation in Phoenix/LiveView/Phoenix HTML surfaces.
- ADR 0003: future acceptance plumbing should keep shared Cucumber feature language user-facing and avoid route/CSS implementation detail in scenarios.
- ADR 0004 and ADR 0005: message detail should read the existing one-message aggregate projections and resolved-recipient delivery rows rather than inventing a new delivery model.
- ADR 0006: member pages should show simplified receipt statuses; detailed delivery values remain operator-only.
- ADR 0013: future focused Phoenix web tests should prefer `PhoenixTest` style where feature-level interactions are useful, while lower-level ConnCase assertions remain appropriate for authorization/error checks.
