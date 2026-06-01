# Club slugs for inbound email routing

Date: 2026-06-01
Status: draft

## Goal

Give every club a unique, stable, human-readable slug that can later be used to route inbound email addresses such as `kmc@messages.memba.io` or `kootenay-mountaineering-club@messages.memba.io`, and to support hosted club sites such as `kmc.memba.io`, to exactly one club.

After this iteration, club slugs are part of the Membership model, projected in the club read model, visible in the relevant staff/operator UI, and available through a public Membership lookup API. No inbound email is received or sent in this slice.

## Background / Context

Memba already sends member club messages via the existing web compose flow and outbound Postmark integration. The next product direction is to let members send club messages by emailing a club address. A related direction is hosted club sites on subdomains such as `kmc.memba.io`. Before Postmark inbound email or host-based club routing can be safely enabled, Memba needs a stable addressing key for clubs.

Current club identity is UUID-based and club names are display text. UUIDs are safe but not suitable for advertised email addresses, while names are not stable or normalized enough for routing. A slug gives us a user-facing, DNS/email-friendly club identifier without changing the existing UUID aggregate identity.

Relevant current implementation:

- `Memba.Membership.Commands.CreateClub` and `Memba.Membership.Events.ClubCreated` currently carry `club_id` and `name` only.
- `Memba.Membership.Projections.Club` currently stores `club_id` and `name` only in `membership_clubs`.
- Club lookup and routing currently use `club_id` query parameters.
- Inbound email, inbound Postmark webhooks, MX setup, and email-to-message dispatch are not implemented yet.

## Scope

### In scope

- Add a required `slug` to the Membership club domain model for newly-created clubs.
- Normalize and validate slugs:
  - lowercase letters, numbers, and hyphens only;
  - no leading or trailing hyphen;
  - no blank slug;
  - choose a reasonable max length to protect UI/email use.
- Keep `club_id` as the aggregate identity and primary key.
- Add `slug` to `ClubCreated` events and club projections.
- Add a database migration for `membership_clubs.slug`, including a unique index.
- Backfill existing projected clubs with deterministic slugs derived from their current names, with collision handling suitable for the current seed/test data.
- Add `Membership.get_club_by_slug/1` or equivalent public query API.
- Update club creation call sites, seeds, fixtures, and tests to supply or derive slugs.
- Expose the slug in the relevant staff/operator-facing club UI or development/admin surface that currently shows club identity, so humans can see the future inbound-address key.
- Add focused tests for slug normalization, validation, projection, uniqueness, lookup, and visible UI display.
- Preserve all existing `club_id`-based member routes and links.
- Keep `dev check` green.

### Out of scope

- Postmark inbound email setup.
- MX/DNS changes.
- Inbound webhook controller.
- Email address format finalization beyond making slugs available.
- Sending club messages by email.
- Slug rename workflow or history/aliasing.
- Custom club domains.
- Public club-page route changes from `club_id` to slug.
- Host-based routing for `slug.memba.io` club sites.
- Member-facing slug editing.

## Iteration Type

Technical/engineering enabling slice with a small staff/operator-visible UI affordance.

The new capability is foundational for future inbound email routing. It does not change member-facing messaging behaviour yet, and it does not change who can access or send club messages.

## Acceptance Scenarios / Feature Files

BDD decision: Not useful for this slice.

No shared Cucumber feature changes are planned. The user-facing business behaviour for club messages is unchanged, and inbound email is explicitly out of scope. Slug rules are deterministic data/model rules better validated with domain, projection, migration, and focused Phoenix tests. Future inbound email routing should get stakeholder-readable scenarios when email-to-club-message behaviour is introduced.

## Acceptance Criteria

- Club creation accepts and records a slug alongside club name and UUID.
- Slugs are normalized to lowercase and trimmed.
- Invalid slugs are rejected: blank, spaces, underscores, punctuation other than hyphen, leading hyphen, trailing hyphen, or malformed values.
- Duplicate slugs are rejected or prevented before two projected clubs can share one slug.
- `membership_clubs.slug` is non-null for existing and new clubs.
- `membership_clubs.slug` has a unique index.
- Existing seeded/test clubs have deterministic slugs.
- `Membership.get_club_by_slug/1` returns the expected club for a valid slug and returns `nil` for missing/invalid/unknown slugs.
- Existing `Membership.get_club/1`, `Membership.list_clubs/0`, active membership queries, member dashboard links, and message compose/detail links continue to work by `club_id`.
- A staff/operator-visible club surface displays the slug.
- No member-facing route changes are required in this slice.
- `dev check` passes.

## Open Business Decisions

None blocking this slice.

Deferred decisions for the inbound email iteration:

- Final inbound address format: `slug@messages.memba.io`, `slug@memba.club`, or another domain/subdomain.
- Whether slugs may be renamed after inbound email is enabled.
- Whether clubs can choose their own slug without staff review.
- Whether old slugs should remain as inbound aliases after a rename.

## Implementation Plan

1. Inspect current Membership club command/event/aggregate/projector/projection code and all club creation call sites.
2. Add `slug` to `CreateClub`, `ClubCreated`, `Memba.Membership.Club`, and `Memba.Membership.Projections.Club`.
3. Implement slug normalization/validation in the club aggregate or a small Membership slug helper:
   - trim;
   - downcase;
   - accept only `a-z`, `0-9`, and single or repeated hyphens where not leading/trailing;
   - enforce a reasonable max length.
4. Update `Membership.create_club/2` to require `:slug` / `"slug"` for new calls, or derive a slug only at trusted fixture/seed boundaries if implementation chooses not to require callers to pass one.
5. Add a migration to add `slug` to `membership_clubs`, backfill existing rows, set non-null, and create a unique index.
6. Update the club projector to write `slug` from `ClubCreated` events.
7. Consider existing event-store history in dev/test: if old `ClubCreated` events without slugs may be replayed, handle them deliberately either with a migration/reset expectation for current development data or with projector fallback for legacy events. Document the chosen approach in code comments or tests.
8. Add `Membership.get_club_by_slug/1`, using normalized input and returning `nil` for invalid/unknown values.
9. Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.
10. Display the slug in the relevant staff/operator club list/detail/dev surface that already exposes club identity. If no true club-admin screen exists, use the existing development/admin-facing club listing rather than inventing a full CRUD workflow.
11. Add tests for:
    - valid slug normalization;
    - invalid slug rejection;
    - duplicate slug protection;
    - projection contains slug;
    - lookup by slug;
    - existing club-id queries still work;
    - UI displays slug.
12. Run `dev check`.

## Open Technical Decisions

- Exact max slug length. Suggested default: 63 characters, aligning with DNS label constraints and keeping future email local parts manageable.
- Collision handling for automatic backfill/generation. For existing data, deterministic suffixing is acceptable if needed; for new club creation, duplicate slugs should fail clearly.
- Legacy event replay strategy for pre-slug `ClubCreated` events in local/dev event stores.

## New Capability

Memba can identify a club by a stable slug, which makes future inbound email routing and future hosted club subdomains possible without exposing UUIDs in public club addresses.

## Validation Plan

- Run `dev check`.
- Run targeted Membership domain/projection tests for club creation and slug lookup.
- Run targeted migration/persistence tests verifying `membership_clubs.slug` is non-null and unique.
- Run targeted Phoenix/UI tests verifying the slug is visible on the chosen staff/operator surface.
- Manual check:
  - create or seed Kootenay Mountaineering Club;
  - confirm its slug is visible;
  - confirm lookup by slug returns the club;
  - confirm existing member routes still use and accept `club_id`.

## Risks / Follow-ups

- Event-sourced history may contain old club-created events without slug data. The implementation must make a deliberate choice rather than silently breaking projection replay.
- Slug rename/aliasing will matter once clubs advertise inbound email addresses, but it is intentionally out of scope here.
- Future inbound email and hosted subdomains may require reserved slugs such as `www`, `app`, `admin`, `support`, `postmaster`, `abuse`, or `no-reply`; that reserved-word policy can be added before public inbound addresses are enabled.
