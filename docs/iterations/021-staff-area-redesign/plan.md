# Staff area redesign and read-only operations indexes

Date: 2026-06-05
Status: merged

## Goal

Make the Memba staff area clearer, calmer, and more useful as an operations surface while keeping the domain model honest.

After this iteration, Memba staff can navigate a redesigned admin shell, manage existing club/person/membership workflows with clearer layout, see all people as global identity/contact records, see all messages in a read-only global operations list, and open existing message delivery diagnostics. Staff are no longer offered the awkward staff-side “send club message” form.

## Background / Context

Matt provided HTML mockups under `docs/iterations/021-staff-area-redesign/mockups/`:

- `Clubs _ all clubs.html`
- `Club _ members _drill-in_.html`
- `Messages _ add _ remove.html`
- `Deliveries _ full diagnostics.html`
- `Incoming _ inbound replies.html`

The mockups are useful for layout, density, navigation rhythm, operational tables, and overall staff-operations feel. They should not be copied literally where they imply product behaviour Memba does not support yet or where they blur domain concepts.

The important domain rule for this iteration is that a person and a membership are distinct:

- A person is an identity/contact record and may have multiple email addresses.
- A membership connects a person to a specific club.
- One person may be a member of multiple clubs.

The redesigned staff area should make that distinction more legible rather than hiding it behind a generic “members” model.

## Scope

### In scope

- Use the mockups as visual and information-architecture inspiration for the staff operations area.
- Redesign the staff layout shell around a Memba staff operations surface.
- Staff navigation shows only working pages for this slice:
  - Clubs
  - People
  - Messages
  - Deliveries
- Restyle and reorganise existing staff pages:
  - `/admin/clubs`
  - `/admin/clubs/:club_id`
  - `/admin/clubs/:club_id/people/new`
  - `/admin/clubs/:club_id/people/:person_id/edit`
  - `/admin/deliveries`
  - `/admin/messages/:message_id`
- Keep the club detail page honest about the model by distinguishing:
  - club facts/editing;
  - person records;
  - memberships for that club.
- Add read-only `/admin/people`:
  - list person records across Memba;
  - show primary and alternate email address summary;
  - show membership summary across clubs where available;
  - link to existing person edit flow where the route is unambiguous enough, or explicitly leave editing in the existing club-scoped flow.
- Add read-only `/admin/messages`:
  - list projected messages across clubs;
  - show enough club and sender context for staff to identify a message where available;
  - link each row to existing `/admin/messages/:message_id` delivery diagnostics.
- Remove the staff “Send a club message” form from `/admin/clubs/:club_id`.
- Remove the embedded club messages list from club detail and replace it with a clear path toward the global Messages area or a future club-filtered messages view.
- Preserve existing staff authentication and authorization.
- Preserve existing club creation, club editing, person creation/editing, email-address editing, membership add/remove, deliveries overview, and message diagnostics behaviour.
- Add or update tests for new routes, navigation, read-only lists, removed compose affordance, and preserved existing workflows.
- Keep `dev check` green.

### Out of scope

- Global people editing or full global membership management.
- Changing the underlying person/membership data model.
- Combining people and memberships into a single domain concept.
- Club-filtered global People, Messages, or Deliveries views, unless a simple link can be provided without implementing filtering.
- New global Members page.
- Roles model or Roles page.
- Incoming/rejected inbound email inbox.
- Message bulk actions such as resend or delete.
- Staff “New message” or any replacement staff-side message composer.
- Message or delivery status filtering.
- Operational KPI cards that require new projections or new semantics.
- Plans, trials, paused club lifecycle, or subscription concepts.
- Reintroducing email open tracking or an “opened” status.
- Club moderator access to staff tools.
- New staff permissions beyond existing Memba staff authorization.
- Major visual rewrites of public or member-facing surfaces.

## Iteration Type

Behaviour-facing.

The user-observable rules are:

- Memba staff have a clearer operations area with working navigation to Clubs, People, Messages, and Deliveries.
- The staff area represents people and memberships as distinct concepts.
- Staff can review messages globally but cannot compose club messages from the staff area.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes staff-visible navigation, adds two staff-visible read-only indexes, and removes a staff-visible action. Stakeholder-readable examples are useful because they document the domain distinction between people and memberships and prevent the redesign from copying misleading mockup assumptions.

Add this shared Cucumber feature file:

- `acceptance-tests/features/memba_staff_operations.feature`

The new feature file is tagged `@todo-domain`/`@todo-ui` during planning because all of its scenarios are future-facing and the new routes and step support do not exist yet:

- Staff navigation offers only working operations pages: Clubs, People, Messages, and Deliveries; it does not offer unavailable pages such as Incoming or Roles.
- Staff can see one person with memberships in multiple clubs on the global People page.
- Staff can see messages across clubs on the global Messages page and open existing diagnostics for a message.
- Staff are not offered a way to send a club message from a club’s staff page.

Matt approved the scenario direction during planning: the staff UI should follow the domain model, not copy the mockups literally where they collapse people and memberships.

## Allowed acceptance feature changes

- `acceptance-tests/features/memba_staff_operations.feature`: create a new feature-level `@todo-domain`/`@todo-ui` feature documenting staff operations navigation, global People, global Messages, and removal of staff-side club-message composition. The `@todo-domain`/`@todo-ui` tag keeps planning-time checks green until delivery implements the routes, UI, and step support.
- Acceptance support and step definitions may be updated during implementation to sign in as Memba staff, create multi-club membership examples, open the staff People and Messages pages, and assert the absence of the staff-side send-message affordance.

## Acceptance Criteria

- Staff layout uses the new mockups as design inspiration while remaining consistent with Memba’s Phoenix/Tailwind patterns.
- Staff navigation includes working links to Clubs, People, Messages, and Deliveries.
- Staff navigation does not include non-working Incoming or Roles links in this slice.
- `/admin/clubs` remains accessible to signed-in Memba staff.
- `/admin/clubs` uses the redesigned staff operations style and still supports creating clubs.
- `/admin/clubs/:club_id` remains accessible to signed-in Memba staff.
- `/admin/clubs/:club_id` makes club facts, people records, and memberships visually distinct.
- Existing club name/slug editing still works.
- Existing person creation and editing still works.
- Existing primary and alternate email-address presentation/editing still works.
- Existing membership add/remove behaviour still works.
- `/admin/clubs/:club_id` no longer shows the staff “Send a club message” form or any equivalent staff-side member impersonation composer.
- `/admin/clubs/:club_id` no longer embeds the old club-scoped messages list as the primary diagnostics entry point.
- Club detail provides a clear route or copy pointing staff toward global Messages or a future club-filtered messages view.
- `/admin/people` exists for signed-in Memba staff.
- `/admin/people` lists person records across Memba.
- `/admin/people` shows each person’s primary email address.
- `/admin/people` shows alternate email-address summary where available.
- `/admin/people` shows membership summary across clubs where available, so one person with multiple memberships is represented honestly.
- `/admin/people` is read-only for this slice except for any links to existing person edit routes that remain unambiguous and safe.
- `/admin/messages` exists for signed-in Memba staff.
- `/admin/messages` lists projected messages across clubs.
- `/admin/messages` shows enough club and sender context for staff to identify messages where available.
- `/admin/messages` links each message to `/admin/messages/:message_id`.
- `/admin/messages` does not offer New message, Resend, Delete, bulk actions, or unsupported filters.
- `/admin/deliveries` keeps existing delivery diagnostics and is restyled consistently.
- `/admin/messages/:message_id` keeps existing message delivery diagnostics and is restyled consistently.
- Existing staff authentication and authorization still protect all `/admin/*` pages.
- Existing acceptance scenarios for staff sign-in, club visibility, slug management, person email addresses, and email deliverability keep passing unless intentionally updated for route/nav copy.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Decisions made during planning:

- Use only working staff navigation links in this iteration.
- Add a read-only global People page and call it “People,” not “Members.”
- Add a read-only global Messages page.
- Keep People and Memberships distinct in the staff UI.
- Remove the staff-side send club message feature rather than redesigning it.
- Treat mockup-only concepts such as Incoming, Roles, bulk message actions, filters, and opened status as follow-ups or non-goals.

## Implementation Plan

1. Inspect the mockup HTML files and extract reusable layout ideas: staff operations shell, page header, navigation grouping, table density, status chips, action placement, and card/table treatment.
2. Inspect current admin routes, LiveViews, layouts, tests, and acceptance helpers.
3. Update `Layouts.admin` to the redesigned staff operations shell with working nav links: Clubs, People, Messages, Deliveries.
4. Add routes and LiveViews for read-only `/admin/people` and `/admin/messages` under the existing staff live session.
5. Add context/read-model queries as needed:
   - list all person records with email summaries and membership summaries;
   - list all projected messages with club and sender context where available.
6. Keep the new index queries simple and deterministic; avoid implementing filters, pagination, bulk actions, or new statuses in this slice.
7. Restyle `/admin/clubs` to match the new staff operations direction while preserving club creation behaviour.
8. Restyle `/admin/clubs/:club_id` around club facts, people records, and memberships.
9. Remove the staff send-message form, its form assign/event handling, and any no-longer-needed member sender options from club detail.
10. Remove the embedded club messages list from club detail and replace it with a clear link/copy toward `/admin/messages` or future club-filtered messages.
11. Restyle person new/edit pages enough that they feel part of the redesigned staff area; preserve existing behaviour.
12. Restyle `/admin/deliveries` consistently without changing delivery semantics.
13. Restyle `/admin/messages/:message_id` consistently without changing diagnostics semantics.
14. Update or add LiveView tests for:
    - staff nav links;
    - `/admin/people` read-only list and multi-club membership summary;
    - `/admin/messages` read-only list and diagnostics links;
    - absence of staff-side send-message affordance;
    - preservation of existing club/person/membership workflows.
15. Update acceptance step support and remove the feature-level `@todo-domain`/`@todo-ui` tag from `memba_staff_operations.feature` once its scenarios pass.
16. Run targeted tests for admin LiveViews and acceptance configuration.
17. Run `dev check`.

## Open Technical Decisions

Implementation should investigate and decide:

- The best query shape for global People membership summaries without introducing expensive N+1 behaviour.
- Whether global People rows can safely link to an existing club-scoped person edit route when a person has multiple memberships; if ambiguous, keep the page read-only and defer global edit semantics.
- The best query shape for global Messages sender and club context, given current projections only store IDs on `messaging_messages`.
- How much of the mockup’s KPI/header treatment can be implemented from existing data without inventing unsupported operational metrics.
- Whether shared admin UI helper components should be extracted during the redesign, or whether duplication is preferable for this slice.

## New Capability

Memba staff have a clearer operations area that shows the real domain model: clubs, people, memberships, messages, and delivery diagnostics are easier to find and no longer mixed with staff-side message composition.

## Validation Plan

- Review the implemented pages against the mockups for staff-operations feel, while checking that domain language remains honest.
- Run LiveView tests for the new People and Messages pages and updated admin pages.
- Run affected acceptance scenarios after implementation removes `@todo-domain`/`@todo-ui` tags.
- Run acceptance configuration checks while scenarios are still `@todo-domain`/`@todo-ui` during planning.
- Run `dev check` before delivery is complete.
- Manual demo:
  1. Sign in as Memba staff.
  2. Confirm staff nav shows Clubs, People, Messages, Deliveries only.
  3. Open Clubs and create or inspect a club.
  4. Open a club and confirm club facts, people, and memberships are distinct.
  5. Confirm no staff-side send club message form exists.
  6. Open People and confirm a person with multiple club memberships is represented as one person with multiple memberships.
  7. Open Messages and open a message diagnostics page.
  8. Open Deliveries and confirm existing diagnostics remain visible.

## Risks / Follow-ups

- The mockups imply several future behaviours that should not sneak into this slice; see `follow-ups.md`.
- Global People edit routing may be ambiguous for people with multiple memberships; do not invent a global edit workflow unless it remains small and safe.
- Global Messages may need sender/club enrichment not currently projected directly; keep the read model simple and avoid large projection redesign unless necessary.
- Removing the staff composer may require updating browser acceptance helpers that currently click “Send club message” through staff club pages; implementation should move those helpers to member compose flows or direct domain setup as appropriate.
- `docs/iterations/020-migrate-production-email-to-postmark` is still marked `implementing` in the iteration index; delivery of this plan should wait until the implementation WIP slot is free.
