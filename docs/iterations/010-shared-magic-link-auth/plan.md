# Shared magic-link authentication

Date: 2026-05-31
Status: implementing

## Goal

Add one shared email magic-link authentication system for members and Memba staff.

After this iteration, a person can sign in with their email address, receive a real magic-link email through Postmark, and land on the home page. The signed-in home page shows their clubs. If their email address is a Memba staff address, it also shows an admin link and allows access to `/admin/*`.

## Background / Context

The navigation handoff defines three surfaces: public Memba marketing, staff admin, and the future white-label club site. Iteration 009 splits the route/module structure so staff tools live under `/admin/*` and member-facing work has a clearer seam.

Authentication should be shared rather than separate by role:

- Everyone signs in by email magic link.
- Staff authorization is simple: a signed-in email at the `memba.io` domain is staff.
- Club membership authorization comes from active memberships associated with the signed-in email.
- A person may belong to more than one club.
- A Memba staff person may also be a member of one or more clubs.

For now, do not solve custom domains. Club links may carry `club_id` in the query string until host/domain resolution is implemented later.

## Scope

### In scope

- Add `/auth` as the single sign-in page:
  - email field,
  - submit button,
  - neutral success response that does not reveal whether the email is known.
- Add a magic-link callback route under `/auth`, such as `/auth/magic/:token` or `/auth/callback/:token`.
- Generate secure, single-use, expiring magic-link tokens.
- Store only token hashes server-side.
- Send real magic-link emails through Postmark.
- Add Postmark configuration for auth emails, including a dedicated auth/transactional message stream if supported by the adapter/API.
- Establish a signed-in browser session after a valid magic link is consumed.
- Add sign out.
- Change the signed-in home page (`/`) to show “My clubs” rather than adding a separate `/my-clubs` route.
- On the signed-in home page, list every club where the signed-in email belongs to an active member.
- If the signed-in email is a Memba staff email, show an Admin link on the home page.
- Protect `/admin/*` so only signed-in `@memba.io` users can access it.
- Protect club/member routes that use `?club_id=<uuid>` so only active members of that club can access them.
- Preserve the public marketing home page for unauthenticated visitors at `/`.
- Add tests for token generation/consumption, session establishment, staff authorization, member authorization, and Postmark auth email construction.
- Keep `dev check` green.

### Out of scope

- Custom club domains or host-based club resolution.
- Club-branded sign-in pages.
- Per-club sending domains for magic-link emails.
- Passwords.
- OAuth/social login.
- Invite emails beyond the sign-in magic link.
- Account/profile management UI.
- Staff user management UI.
- Changing how people/members are created, except for query support needed to find clubs by email.
- Self-serve signup or request-an-account lead capture.
- Billing/subscriptions.

## Acceptance Criteria

- Visiting `/auth` shows a sign-in form with one email field.
- Submitting an email on `/auth` always shows a neutral response such as “If we know that email, we sent a sign-in link.”
- Submitting an email that belongs to at least one active member or a `memba.io` staff address creates a magic-link token and sends a real Postmark email when Postmark auth-email configuration is enabled.
- Magic-link emails contain a link back to the application under `/auth`.
- Magic-link tokens expire after 15 minutes.
- Magic-link tokens can be used only once.
- Token values are not stored in plaintext.
- Following a valid magic link signs the browser in and redirects to `/`.
- Following an expired, unknown, or already-consumed magic link does not sign the browser in and shows a safe error.
- When signed in as a club member, `/` shows a “My clubs” list containing every club where that email is an active member.
- Club links from the signed-in home page include `club_id` in the query string for now.
- When signed in with an email at the `memba.io` domain, `/` also shows an Admin link.
- Signed-in `@memba.io` users can access `/admin/*`.
- Signed-in non-`@memba.io` users cannot access `/admin/*`.
- A signed-in person who is both staff and club member sees both their clubs and the Admin link.
- A signed-in person who belongs to multiple clubs sees all of them.
- A signed-in person can access a club-member route with `?club_id=<uuid>` only when their email belongs to an active member of that club.
- `POST /webhooks/postmark` remains unchanged.
- Local/test environments do not send real emails unless explicitly configured; tests use deterministic email assertions.
- Missing required auth-email Postmark configuration fails clearly when real auth-email sending is enabled.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Business decisions intentionally deferred:

- The final club-domain sign-in flow.
- Whether magic-link emails should later be branded as Memba or as the club, depending on how the person arrived.
- Whether staff auth should later require stronger controls than an email domain check.

## Implementation Plan

1. Inspect the post-iteration-009 route structure and admin pipeline.
2. Add persistence for authentication:
   - generate migrations with `mix ecto.gen.migration`,
   - add an identity/session-support table if useful,
   - add a magic-token table with email, hashed token, expiry timestamp, consumed timestamp, and timestamps.
3. Add an authentication context, likely `Memba.Accounts` or `Memba.Identity`, with functions to:
   - normalize email addresses,
   - determine staff status from the `memba.io` domain,
   - request a magic link,
   - create and hash a token,
   - consume a token exactly once,
   - list clubs for an email,
   - check whether an email is an active member of a club.
4. Extend `Memba.Membership` query API as needed:
   - find active clubs for a member email,
   - check active membership by club and email.
5. Add auth email delivery:
   - build a concise plain-text and HTML magic-link email,
   - use `Memba.Mailer`/Swoosh/Postmark,
   - configure a dedicated auth/transactional stream if supported,
   - use clear runtime configuration errors when real auth email is enabled but credentials/stream/from address are missing.
6. Add web auth helpers/plugs, likely `MembaWeb.UserAuth`, to:
   - fetch current signed-in identity from the session,
   - require authentication,
   - require Memba staff,
   - require active membership for a `club_id` query parameter.
7. Add `/auth` UI and callback handling:
   - sign-in form,
   - request submission,
   - callback token consumption,
   - sign out route/action.
8. Update the home page:
   - unauthenticated visitors see the existing marketing page,
   - signed-in users see “My clubs”, club links with `?club_id=...`, and an Admin link when staff.
9. Apply auth gates:
   - `/admin/*` requires staff,
   - member/club routes using `?club_id=...` require active membership.
10. Add focused tests:
    - context/token tests,
    - auth email tests using Swoosh test facilities or an adapter stub,
    - controller/LiveView tests for `/auth`, callback, sign out, home page variants, admin access, and member authorization.
11. Update operational documentation for auth Postmark environment variables and the required message stream.
12. Run `bin/dev check` and fix regressions.

## Open Technical Decisions

- Exact module name: prefer `Memba.Accounts` if following Phoenix convention, or `Memba.Identity` if we want to avoid implying full account management.
- Exact callback route under `/auth`: choose the clearest route during implementation, keeping the sign-in form at `/auth`.
- Exact Swoosh/Postmark option for message streams. Confirm adapter support; if insufficient, use Req against Postmark directly for auth emails while still following the project rule to use Req for HTTP.
- Whether to persist staff identities. Staff authorization can be derived from email alone, but an identity row may still be useful for token/session audit.
- Whether unauthenticated access to protected routes redirects to `/auth` with a return path. Prefer preserving the originally requested path, including `club_id`, where safe.

## New Capability

People can authenticate with Memba using only their email address. The app can distinguish staff access from club membership access after sign-in, support people with multiple clubs, and support people who are both staff and members.

## Validation Plan

- Run `bin/dev check`.
- Automated tests should prove:
  - token hashes are stored, not plaintext tokens,
  - tokens expire,
  - tokens are single-use,
  - valid token consumption creates a browser session,
  - `/auth` does not reveal whether an email is known,
  - auth emails are constructed with the configured sender/stream and correct callback URL,
  - signed-in home page lists all clubs for an active member email,
  - staff see an Admin link,
  - staff can access `/admin/*`,
  - non-staff cannot access `/admin/*`,
  - membership checks enforce `club_id` access,
  - the Postmark webhook route is unchanged.
- Manual demo:
  1. Configure auth email Postmark settings in a controlled environment.
  2. Create a club and add a member with a real test email.
  3. Visit `/auth`, submit the email, receive the magic link, and follow it.
  4. Confirm `/` shows that member's club.
  5. Add the same email to a second club and confirm both clubs appear.
  6. Sign in with a `memba.io` address and confirm the Admin link appears and `/admin/*` is accessible.
  7. Confirm a non-staff member cannot access `/admin/*`.

## Risks / Follow-ups

- Email-domain-only staff authorization is intentionally simple; later production hardening may require explicit staff records, MFA, or allow-lists.
- Magic links sent through email inherit email account security risks; this is acceptable for the first product slice but should be revisited if admin capabilities become more sensitive.
- Auth email deliverability may need a dedicated Postmark stream, template, and monitored sender reputation.
- Club-domain sign-in and club-branded auth emails remain important follow-ups.
- Query-string `club_id` is temporary and should be replaced by host/domain club resolution when custom domains are implemented.
