# Member-facing club subdomains

Date: 2026-06-01
Status: implementing

## Goal

Move normal member-facing club navigation from UUID query strings to club slug subdomains.

After this iteration, a signed-in member reaches Kootenay Mountaineering Club at `kmc.clubs.memba.io`, and that host selects KMC for the member dashboard, compose page, and message detail page. Local development and browser acceptance tests exercise the same host-based behaviour using the configured local club-site domain, defaulting to `lvh.me`, for example `kmc.lvh.me:4000`.

## Background / Context

Iteration 015 added staff-managed club slugs and public club subdomain routing at `slug.clubs.memba.io`. The public root of a known club subdomain already resolves the club by host and renders that club's public page.

Current member-facing navigation still uses UUID query strings:

- `/?club_id=<uuid>` for the signed-in club dashboard;
- `/messages/new?club_id=<uuid>` for composing a message;
- `/messages/:message_id?club_id=<uuid>` for reading message details.

Those URLs are not suitable as the normal member-facing club-site surface. The club slug should be the advertised and navigated address, while UUID query strings remain only as a temporary backwards-compatible fallback during migration.

ADR 0019 records the local-development decision: production uses `clubs.memba.io`; local development and browser acceptance tests default to `lvh.me` so host-based routing can be exercised without wildcard `/etc/hosts` entries or a project-managed DNS server.

## Scope

### In scope

- Add configuration for the club-site base domain used when generating club subdomain URLs:
  - production: `clubs.memba.io`;
  - local/test default: `lvh.me`.
- Generate signed-in “My clubs” links as club subdomain URLs instead of `?club_id=<uuid>` URLs.
- Route known club subdomain roots so:
  - unauthenticated visitors see the public club page;
  - signed-in active members see the member dashboard;
  - signed-in non-members see the public club page.
- Route member-only pages on known club subdomains:
  - `/messages/new` selects the club from the host slug;
  - `/messages/:message_id` selects the club from the host slug.
- Redirect unauthenticated visitors who open private member URLs on a club subdomain to sign in, preserving the full return URL including host and path.
- After a valid magic-link sign-in, return active members to the private club subdomain URL they originally requested.
- Show a safe forbidden/access-denied response when a signed-in non-member opens a private member URL on a club subdomain.
- Return 404 Not Found for unknown club subdomains.
- Keep existing `?club_id=<uuid>` member routes as temporary backwards-compatible fallback routes, but stop generating them from normal member navigation.
- Update browser acceptance support, Cucumber step support, and tests to exercise `lvh.me` host-based local club URLs.
- Update relevant controller/LiveView/router tests for host-based dashboard, compose, detail, auth return-to, forbidden, and fallback behaviour.
- Keep `dev check` green.

### Out of scope

- Removing `?club_id=<uuid>` support entirely.
- Custom club domains.
- Club-branded sign-in pages or club-branded magic-link emails.
- Slug rename history, redirects, or aliases.
- Reserved slug policy beyond existing slug validation.
- Running a local DNS server in devenv/process-compose.
- Production DNS changes for `*.clubs.memba.io`; those remain an external deployment prerequisite.
- Public club page content changes.
- Staff/admin routing changes.

## Iteration Type

Behaviour-facing.

The user-observable rule is that the club slug in the subdomain identifies the active club for member-facing pages. UUID query strings are no longer the normal member navigation mechanism.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes member-visible URLs, club selection, authentication continuation, and authorization rules. Stakeholder-readable scenarios are useful because the same root URL has public and member meanings depending on sign-in and membership, while private URLs must remain protected.

Add the following shared Cucumber feature file:

- `acceptance-tests/features/member_club_subdomains.feature` (`@wip` for planning until implementation catches up)

The feature covers these scenarios:

- Alice opens Kootenay Mountaineering Club from “My clubs” and lands on `kmc.clubs.memba.io`.
- Alice composes a message on the KMC subdomain and the host-selected club supplies the recipients.
- Alice views a message on the KMC subdomain and sees it in KMC.
- Alice opens a private message URL while signed out, signs in, and returns to the same subdomain URL.
- Pat, a member of another club, cannot view KMC's private message URL.
- Robin can still open KMC's public club page at the subdomain root.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_club_subdomains.feature`: new feature file, tagged `@wip`, to document the member subdomain navigation, host-selected club, auth return-to, private authorization, and public-root rules for this iteration. The tag keeps planning-time checks green until delivery implements the supporting steps and application behaviour.
- Acceptance support and Cucumber configuration may be updated during implementation to generate and open local club subdomain URLs using the configured local base domain, defaulting to `lvh.me`.

## Acceptance Criteria

- The application has a configurable club-site base domain for generated club URLs.
- Production club-site URL generation uses `clubs.memba.io`.
- Local development and browser acceptance tests default to `lvh.me`, so KMC can be opened as `kmc.lvh.me:<port>`.
- The signed-in home page lists a member's clubs with links to each club's slug subdomain.
- The “My clubs” links no longer include `club_id` query strings.
- Opening `kmc.clubs.memba.io/` while signed out shows the Kootenay Mountaineering Public club page.
- Opening `kmc.clubs.memba.io/` while signed in as an active KMC member shows the KMC member dashboard.
- Opening `kmc.clubs.memba.io/` while signed in as a non-member shows the KMC public club page.
- Opening `unknown.clubs.memba.io/` returns 404 Not Found.
- Opening `kmc.clubs.memba.io/messages/new` while signed in as an active KMC member shows the compose page for KMC.
- Sending a message from `kmc.clubs.memba.io/messages/new` addresses KMC members and not members of another club.
- Opening `kmc.clubs.memba.io/messages/:message_id` while signed in as an active KMC member shows the KMC message detail page.
- Private member URLs on a club subdomain do not need or generate `club_id` query parameters.
- Opening a private member URL on a club subdomain while signed out redirects to sign-in with a safe return path that preserves host, path, and query string as needed.
- Following a valid magic link after that redirect returns the active member to the originally requested private subdomain URL.
- A signed-in non-member who opens a private member URL on another club's subdomain sees a safe forbidden/access-denied response and does not see private message content.
- Existing `?club_id=<uuid>` dashboard, compose, and message-detail routes continue to work as temporary backwards-compatible fallbacks.
- Fallback `?club_id=<uuid>` routes remain protected by the existing active-membership checks.
- Existing public Memba routes at `/`, `/about`, `/terms`, and `/privacy` on the main host continue to work.
- Existing staff/admin routes continue to work.
- ADR 0019 documents the `lvh.me` local subdomain decision.
- `dev check` passes.

## Open Business Decisions

None known.

Deferred decisions:

- When to remove the legacy `?club_id=<uuid>` fallback routes.
- Whether custom club domains will replace or supplement Memba-hosted club subdomains.
- Whether the sign-in page and magic-link email should become club-branded when a member arrives from a club subdomain.
- Whether signed-in non-members at the club subdomain root should eventually see a different “request access” or “wrong account” experience instead of the public page.

## Implementation Plan

1. Inspect current routing, `PageController`, member dashboard LiveView, member message routes, compose route, auth return-to handling, and URL generation helpers.
2. Add configuration for the club-site base domain and generated URL scheme/port where needed:
   - production base domain `clubs.memba.io`;
   - dev/test base domain `lvh.me`;
   - preserve environment-appropriate scheme and port in generated URLs.
3. Add a small URL/host helper or equivalent web module that:
   - builds a club URL from a club slug;
   - detects whether a request host is under the configured club-site base domain;
   - extracts the slug from the left-most label;
   - ignores non-club hosts.
4. Update home-page “My clubs” link generation to use the helper and each club's slug.
5. Update root club-subdomain handling so known club hosts choose between public page and member dashboard:
   - signed-out visitor: public club page;
   - signed-in active member: member dashboard;
   - signed-in non-member: public club page;
   - unknown slug: 404.
6. Add host-selected member routes for compose and message detail, reusing existing member page modules where practical but passing `club_id` from slug lookup instead of from query parameters.
7. Ensure private member routes require authentication and active membership for the host-selected club.
8. Update auth redirect/return-to handling so private subdomain URLs preserve the original host and path through magic-link sign-in, while still avoiding unsafe open redirects.
9. Keep old `?club_id=<uuid>` routes working as fallback routes and continue to protect them with active-membership checks.
10. Update templates and verified routes so normal member navigation no longer emits `club_id` query strings.
11. Update acceptance test support to build club URLs using the configured local base domain, defaulting to `lvh.me`, and to open host-based URLs in Playwright.
12. Add or update tests for:
    - club URL generation in production-like and local/test configuration;
    - slug extraction from configured club-site hosts;
    - unknown subdomain 404;
    - root public/member/non-member behaviour;
    - compose and message detail host-selected club behaviour;
    - unauthenticated private subdomain redirect and post-auth return;
    - signed-in non-member forbidden private URL;
    - legacy `club_id` fallback still works and remains protected;
    - main-host public and admin routes still work.
13. Keep the new Cucumber feature tagged `@wip` until the delivery implementation adds matching step support and behaviour.
14. Run `dev check`.

## Open Technical Decisions

None known.

Decisions made during planning:

- Use ADR 0019's local subdomain strategy: `lvh.me` for local/test wildcard loopback subdomains.
- Keep `?club_id=<uuid>` as a temporary fallback, but stop generating it from normal member navigation.
- Private member URLs on club subdomains should redirect signed-out visitors to sign-in and then return them to the same URL after magic-link auth.
- Signed-in non-members should see forbidden/access denied on private member URLs.
- Signed-in non-members at the club subdomain root should see the public club page.

## New Capability

Members can use a stable, human-readable club subdomain as their normal club-site address. The app can select the active club from the host for member dashboard, compose, and message detail pages, while still preserving public club pages and authentication/authorization boundaries.

## Validation Plan

- Run `dev check`.
- Run targeted web tests for club-site host detection, URL generation, root routing, private member routing, auth return-to, forbidden access, and legacy fallback routes.
- Run targeted acceptance-test configuration checks proving `@wip` scenarios are excluded from the default browser Cucumber run.
- Run browser acceptance support tests that verify local club URLs use `lvh.me` rather than `club_id` query strings.
- Manual demo:
  1. Start the app locally.
  2. Sign in as a member of KMC.
  3. Confirm the home page links KMC to `kmc.lvh.me:<port>`.
  4. Open `kmc.lvh.me:<port>/` and confirm the KMC member dashboard appears.
  5. Open `kmc.lvh.me:<port>/messages/new` and send a message to KMC members.
  6. Open the message detail on `kmc.lvh.me:<port>/messages/:message_id`.
  7. Sign out, open the private message URL, sign in, and confirm the browser returns to that URL.
  8. Sign in as a member of another club and confirm the private KMC message URL is forbidden.
  9. Confirm `unknown.lvh.me:<port>/` returns 404.
  10. Confirm the old `/?club_id=<uuid>` fallback still works temporarily.

## Risks / Follow-ups

- Absolute URL generation with scheme, host, and port can be subtle across Phoenix endpoint config, Playwright, reverse proxies, and production deployment. Keep helper tests explicit.
- Auth return-to handling must preserve subdomain URLs without opening unsafe redirects to arbitrary external sites.
- The temporary `club_id` fallback should be retired once all member navigation and external links have moved to subdomains.
- Browser tests may need careful base URL and host handling because Playwright defaults to one base URL but club navigation crosses hosts.
- Production TLS and wildcard DNS for `*.clubs.memba.io` remain deployment concerns outside this implementation slice.
