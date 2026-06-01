# Club slugs and public club subdomains

Date: 2026-06-01
Status: ready

## Goal

Let Memba staff assign each club a short, unique, human-readable slug and let public visitors reach a club's public page at `slug.clubs.memba.io`.

After this iteration, Kootenay Mountaineering Club can have the slug `kmc`, staff can see and edit that slug in a minimal admin club edit page, and `kmc.clubs.memba.io` routes public visitors to KMC's public marketing page. No inbound email is received or sent in this slice.

## Background / Context

Memba already has public club pages and member-facing routes that use `club_id` query parameters. The next product direction includes both inbound club email addresses and hosted club sites. Both need a stable public addressing key for each club.

Current club identity is UUID-based and club names are display text. UUIDs are safe but not suitable for advertised subdomains or email addresses, while names are not stable or normalized enough for routing. A slug gives us a user-facing, DNS/email-friendly club identifier without changing the existing UUID aggregate identity.

Production DNS for `*.clubs.memba.io` is a prerequisite for delivery and will be prepared outside Fabro. This iteration implements the application behaviour that uses those hosts once DNS points at the production app.

Relevant current implementation:

- `Memba.Membership.Commands.CreateClub` and `Memba.Membership.Events.ClubCreated` currently carry `club_id` and `name` only.
- `Memba.Membership.Projections.Club` currently stores `club_id` and `name` only in `membership_clubs`.
- Club lookup and routing currently use `club_id` query parameters.
- The public club page exists, but not host-based club resolution by slug.
- Inbound email, inbound Postmark webhooks, MX setup, and email-to-message dispatch are not implemented yet.

## Scope

### In scope

- Add a required `slug` to the Membership club domain model for newly-created clubs.
- Default a new club's suggested slug to kebab-case generated from the club name.
- Let Memba staff edit a club slug on a new minimal admin club edit page.
- Validate staff-entered slugs exactly as address-safe values:
  - lowercase letters, numbers, and hyphens only;
  - no spaces, underscores, or punctuation other than hyphen;
  - no leading or trailing hyphen;
  - no blank slug;
  - maximum 32 characters.
- Provide live UI feedback while staff type a slug, including whether the slug is valid and whether it is already taken.
- Prevent client-side submission when the slug is invalid or duplicate, while still enforcing server-side validation and leaving the form editable on invalid submissions.
- Keep `club_id` as the aggregate identity and primary key.
- Add `slug` to `ClubCreated` events and club projections.
- Add a database migration for `membership_clubs.slug`, including a unique index.
- Backfill existing projected clubs with deterministic slugs derived from their current names, with collision handling suitable for the current seed/test data.
- Add `Membership.get_club_by_slug/1` or equivalent public query API.
- Add host-based public club-page routing for `slug.clubs.memba.io`.
- Return 404 Not Found for unknown club slugs on `*.clubs.memba.io` hosts.
- Update club creation call sites, seeds, fixtures, and tests to supply or derive slugs.
- Add focused tests for slug default generation, validation, live feedback endpoint or LiveView behaviour, projection, uniqueness, lookup, admin editing, and public host routing.
- Preserve all existing `club_id`-based member routes and links.
- Keep `dev check` green.

### Out of scope

- Fabro-managed production DNS changes. See `dns-prerequisite.md` for the manual prerequisite.
- Postmark inbound email setup.
- MX/DNS changes for email.
- Inbound webhook controller.
- Email address format finalization beyond making slugs available.
- Sending club messages by email.
- Slug rename workflow, history, or aliasing after a slug has been advertised.
- Reserved slug policy such as `www`, `admin`, `support`, `postmaster`, `abuse`, or `no-reply`.
- Custom club domains.
- Replacing authenticated member routes and links with slug/host-based routing.
- Member-facing slug editing.
- Logo upload, broader club profile management, or full club CRUD polish.

## Iteration Type

Behaviour-facing slice.

The user-observable rule is that a public club slug identifies exactly one club page at `slug.clubs.memba.io`. A supporting staff rule lets Memba staff create and edit the slug safely before it is used publicly.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes staff-visible club setup behaviour and public visitor routing, so stakeholder-readable examples are useful. Add the following shared Cucumber feature file:

- `acceptance-tests/features/staff_club_slugs.feature` (`@wip` for planning until implementation catches up)

The feature covers these scenarios:

- Staff create a club with the suggested slug generated from the club name.
- Staff cannot save an invalid edited slug such as `kmc club!`.
- Staff cannot save a slug already used by another club.
- A public visitor opening `kmc.clubs.memba.io` sees Kootenay Mountaineering Club's public page.
- A public visitor opening `unknown.clubs.memba.io` sees a 404 Not Found page.

## Allowed acceptance feature changes

- `acceptance-tests/features/staff_club_slugs.feature`: new feature file, tagged `@wip`, to document the staff slug-management and public host-routing rules for this iteration. The tag keeps planning-time checks green until the delivery implementation adds the supporting steps and application behaviour.

## Acceptance Criteria

- Club creation suggests a slug generated as kebab-case from the club name.
- Staff can edit a club slug on a minimal admin club edit page.
- Staff-entered slugs are trimmed/downcased only if needed by form handling, but spaces and punctuation are not silently converted; edited values must already be valid address-safe slugs.
- Invalid slugs are rejected: blank, uppercase, spaces, underscores, punctuation other than hyphen, leading hyphen, trailing hyphen, longer than 32 characters, or otherwise malformed values.
- Duplicate slugs produce live feedback while staff type.
- Duplicate slugs are rejected by server-side validation and prevented by database uniqueness.
- The client-side UI prevents saving while the slug is invalid or duplicate.
- If a stale or bypassed submission reaches the server with an invalid or duplicate slug, the server rejects it with a validation error and leaves the form editable.
- `membership_clubs.slug` is non-null for existing and new clubs.
- `membership_clubs.slug` has a unique index.
- Existing seeded/test clubs have deterministic slugs.
- `Membership.get_club_by_slug/1` returns the expected club for a valid slug and returns `nil` for missing/invalid/unknown slugs.
- `kmc.clubs.memba.io` routes to the public page for the club whose slug is `kmc`.
- Unknown club subdomains under `clubs.memba.io` return 404 Not Found.
- Existing `Membership.get_club/1`, `Membership.list_clubs/0`, active membership queries, member dashboard links, and message compose/detail links continue to work by `club_id`.
- No authenticated member route changes are required in this slice.
- `dev check` passes.

## Open Business Decisions

None known.

Deferred decisions for later iterations:

- Final inbound email address format: `slug@messages.memba.io`, `slug@memba.club`, or another domain/subdomain.
- Whether slugs may be renamed after inbound email or public club subdomains are advertised.
- Whether old slugs should remain as inbound aliases or web redirects after a rename.
- Reserved slug policy for public web and email use.
- Whether clubs can choose their own slug without staff review.

## Implementation Plan

1. Confirm production DNS prerequisite outside Fabro: `*.clubs.memba.io` points at the production Memba app before delivery starts.
2. Inspect current Membership club command/event/aggregate/projector/projection code, public club route code, admin/staff route code, and all club creation call sites.
3. Add `slug` to `CreateClub`, `ClubCreated`, `Memba.Membership.Club`, and `Memba.Membership.Projections.Club`.
4. Implement slug generation and validation in a small Membership slug module or equivalent domain helper:
   - generate defaults by kebab-casing club names;
   - validate staff-entered values as already address-safe;
   - enforce lowercase letters, numbers, hyphens, no leading/trailing hyphen, and maximum 32 characters.
5. Update `Membership.create_club/2` and relevant forms to use the generated default slug while allowing staff override.
6. Add a migration to add `slug` to `membership_clubs`, backfill existing rows deterministically, set non-null, and create a unique index.
7. Update the club projector to write `slug` from `ClubCreated` events.
8. Do not support replay of old slug-less `ClubCreated` events. There is no live data yet; development/test event stores may be reset or backfilled as needed.
9. Add `Membership.get_club_by_slug/1`, using normalized lookup input only where safe and returning `nil` for invalid/unknown values.
10. Add a minimal staff/admin club edit page for name/slug editing or, if creation already exists, extend the creation/edit flow with slug controls.
11. Implement live validity/availability feedback for staff slug editing, either in LiveView or via a small admin-only validation endpoint.
12. Add host-based public club-page resolution for `*.clubs.memba.io`:
    - extract the left-most slug label from hosts under `clubs.memba.io`;
    - look up the club by slug;
    - render the existing public club page for found clubs;
    - return 404 for unknown slugs.
13. Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.
14. Add tests for:
    - default slug generation from names;
    - valid and invalid staff-entered slugs;
    - duplicate slug live feedback and server rejection;
    - database unique constraint;
    - projection contains slug;
    - lookup by slug;
    - public host routing and unknown-host 404;
    - existing club-id queries and member routes still work;
    - admin UI displays and edits slug.
15. Run `dev check`.

## Open Technical Decisions

None known.

Decisions made during planning:

- Maximum slug length is 32 characters.
- Public club subdomains use `slug.clubs.memba.io`, not `slug.memba.io`.
- Actual production DNS setup is a prerequisite outside Fabro, not part of implementation delivery.
- Staff-entered slugs must already be address-safe; the app should not silently kebab-case arbitrary staff input.
- Duplicate slug feedback should be live in the client and enforced on the server/database.
- Old slug-less `ClubCreated` event replay does not need compatibility support because there is no live production data yet.

## New Capability

Memba can identify a club by a stable public slug, staff can manage that slug safely, and public visitors can reach a club's public page at a human-readable subdomain such as `kmc.clubs.memba.io`.

## Validation Plan

- Run `dev check`.
- Run targeted Membership domain/projection tests for club creation, slug generation, slug validation, uniqueness, and slug lookup.
- Run targeted migration/persistence tests verifying `membership_clubs.slug` is non-null and unique.
- Run targeted Phoenix/LiveView tests verifying staff can see/edit slugs and receive live duplicate/invalid feedback.
- Run targeted routing/controller/LiveView tests verifying:
  - `kmc.clubs.memba.io` renders Kootenay Mountaineering Club's public page;
  - `unknown.clubs.memba.io` returns 404;
  - existing `club_id` public/member links still work.
- Confirm the new Cucumber feature file remains tagged `@wip` until implemented.
- Manual production validation after deploy:
  - confirm wildcard DNS for `*.clubs.memba.io` resolves to the production app;
  - confirm `https://kmc.clubs.memba.io` shows KMC's public page;
  - confirm `https://unknown.clubs.memba.io` returns 404.

## Risks / Follow-ups

- Host-based routing may interact with endpoint URL, allowed-host, proxy, or deployment configuration. Tests should cover host handling explicitly.
- Slug rename/aliasing will matter once public subdomains or inbound email addresses are advertised, but it is intentionally out of scope here.
- Future inbound email and hosted subdomains may require reserved slugs such as `www`, `app`, `admin`, `support`, `postmaster`, `abuse`, or `no-reply`; that reserved-word policy can be added before wider public use.
- Production DNS propagation and TLS certificate coverage for `*.clubs.memba.io` must be verified outside Fabro.
