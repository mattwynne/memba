# Memba product roadmap

Date: 2026-05-31

This roadmap follows the navigation and pages handoff from the designer package. It assumes iteration 009 splits the app into public, admin, and future club-site surfaces, and iteration 010 adds shared magic-link authentication.

## Near-term sequence

### 1. Club-site member shell

Create the first signed-in member surface using the temporary `?club_id=...` approach.

Expected shape:

- `/members?club_id=...`
- white-label club layout with the neutral default slate theme
- club wordmark from club name
- tabs: Noticeboard · Directory · Sent
- clear “New message” action
- quiet “Powered by Memba” footer credit

Purpose: make the authenticated member experience real without waiting for custom domains.

### 2. Member noticeboard and read-message split

Move member reading into clean club-site pages.

Expected shape:

- noticeboard lists recent club messages
- `/messages/:message_id?club_id=...` shows a clean reading view
- delivery diagnostics stay in `/admin/messages/:message_id`
- members do not see operational delivery records

Purpose: separate member experience from staff diagnostics.

### 3. Member compose

Let a signed-in active member send a message to the whole club.

Expected shape:

- `/compose?club_id=...`
- subject and body fields
- fixed audience: whole club
- sender comes from the authenticated person, not a dropdown

Purpose: turn the member site from read-only into the core club noticeboard workflow.

### 4. Directory and sent messages

Add the remaining member tabs.

Expected shape:

- `/directory?club_id=...` — searchable/read-only active member directory
- `/sent?club_id=...` — messages sent by the signed-in member

Purpose: complete the first useful club member area.

### 5. Request-an-account flow

Replace public “get started” links with a lead-capture flow.

Expected shape:

- public request form
- fields: name, club, email, short note about the club
- submitting creates a lead and emails Memba
- no club/account is created automatically
- staff can review requests in `/admin/requests`

Purpose: support invite-only onboarding without self-serve signup or billing.

### 6. Club branding controls

Let staff set the basic brand layer for a club.

Expected shape:

- `/admin/clubs/:club_id/brand`
- brand colour
- domain field, even before full domain routing is live
- text wordmark from club name
- CSS variables drive member-facing colour
- no logo upload yet unless it becomes trivial

Purpose: make the white-label model explicit and configurable.

### 7. Custom-domain club resolution

Replace `?club_id=...` with host-based club resolution.

Expected shape:

- incoming host maps to a club
- club-domain `/auth` and member routes
- member links no longer need `club_id` query strings
- central Memba home can still list “my clubs” and link out to each club site

Purpose: deliver the intended white-label experience where members use their club’s own website.

## Deliberately later

- Club logo and image upload
- Self-serve brand controls for club admins
- Self-serve signup
- Subscriptions and billing
- Renewals and dues
- Club-built public pages
- Events/trips
- Member-to-member email list
- Google Sheet sync
- AT Protocol and social profiles

## Guiding decisions

- Authentication is shared: everyone signs in by email magic link.
- Staff authorization is simple for now: `@memba.io` email addresses are staff.
- People can be members of multiple clubs.
- Staff can also be members of clubs.
- Member-facing pages are white-label: club brand, not Memba brand.
- Until custom domains exist, member routes may carry `club_id` in the query string.
- The query-string approach is temporary and should be removed once host-based club resolution exists.
