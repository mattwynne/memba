# Multiple email addresses per person

Date: 2026-06-01
Status: ready

## Goal

Let a person have more than one email address, with exactly one primary email address used for outbound club messages.

After this iteration, Memba can recognize a member by any known email address attached to their person record, while still sending club messages to that person's primary email address. Staff can create and edit a person's primary and alternate email addresses from dedicated staff LiveViews. This prepares for inbound email, where members may send from personal aliases, work addresses, or old addresses, without forcing outbound club mail to go to every known address.

## Background / Context

Memba currently stores one `email` on each Membership person projection. That single value is used for several jobs: magic-link sign-in, finding active clubs for a signed-in email, checking active membership by email, and resolving outbound club-message recipients.

Inbound email needs a more precise model. A person may have multiple legitimate sender addresses, but Memba should normally deliver each club message to one address per person. Separating known addresses from the primary sending address gives us that distinction.

Relevant current implementation:

- `Memba.Membership.Commands.CreatePerson`, `Memba.Membership.Events.PersonCreated`, `Memba.Membership.Person`, and `Memba.Membership.Projections.Person` currently carry one `email`.
- `membership_people.email` is the existing projected email column.
- `Membership.list_active_clubs_for_member_email/1` and `Membership.active_member_of_club_by_email?/2` match the single projected person email.
- `Membership.list_active_members_of_club/1` returns one email per person for Messaging recipient resolution.
- `Accounts.request_magic_link/1` uses Membership email lookup to decide whether a non-staff requester is known.
- The existing admin club LiveView has an inline person creation form and people list; this iteration should move person create/edit into dedicated staff LiveViews linked from that staff/admin surface rather than expanding the inline form.

## Scope

### In scope

- Add support for multiple normalized email addresses per person.
- Ensure each person has exactly one primary email address.
- Default the primary address to the first entered address for the common one-email case, while validating that exactly one primary address is selected on create/edit.
- Treat the existing person `email` value as the initial primary email during migration/backfill.
- Globally disallow duplicate normalized email addresses for now, so one email address cannot identify more than one person.
- Use the primary email address for outbound club-message recipient resolution.
- Let authentication/magic-link eligibility recognize any known email address attached to an active member.
- Send a requested magic-link email to the known address the requester typed, including when that address is an alternate email address.
- Let active-member-by-email checks recognize any known email address attached to an active member.
- Add public Membership query APIs needed by Accounts and future inbound email sender matching.
- Add database/projection support for person email addresses.
- Add dedicated staff LiveViews for creating and editing people with primary and alternate email addresses, linked from the existing admin club/person surface.
- Display a person's primary and alternate email addresses on staff/operator person surfaces.
- Add tests for migration/backfill, normalization, uniqueness, primary selection, authentication lookup, active-member lookup, outbound recipient resolution, staff create/edit UI, and display.
- Keep existing single-email flows working.
- Keep `dev check` green.

### Out of scope

- Postmark inbound email setup.
- Inbound webhook controller.
- Sending club messages by emailing a club address.
- Email verification workflow for newly-added alternate addresses.
- Member self-service email address management.
- Member-facing display of primary or alternate email addresses; capture this as a follow-up iteration if needed.
- Sending outbound club messages to more than one address per person.
- Per-club email preferences.
- Bounce-driven automatic primary-email changes.
- Shared household email addresses or any policy that lets the same normalized email address belong to more than one person.
- Ambiguous sign-in or inbound-sender disambiguation flows.

## Iteration Type

Behaviour-facing data/model and staff workflow slice.

The changed user-observable rules are:

- staff can create and edit a person's primary and alternate email addresses;
- a known member can sign in using any email address attached to their person record;
- magic-link email is sent to the known address the member typed;
- outbound club messages still go to one primary email address per active member.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes identity, staff data-management, and message-delivery business rules. Add the following shared Cucumber feature file as stakeholder-readable acceptance criteria:

- `acceptance-tests/features/person_email_addresses.feature` (`@wip` until this iteration is implemented)
  - `Alice signs in with her work email address`
  - `Alice receives a club message at her primary email address`
  - `Staff creates a person with primary and alternate email addresses`
  - `Staff changes a person's primary email address`

The feature is tagged `@wip` during planning so default browser Cucumber excludes it until Fabro implements the behaviour and removes or narrows the tag.

## Allowed acceptance feature changes

- `acceptance-tests/features/person_email_addresses.feature`: add the new `@wip` feature and scenarios listed above. Reason: these scenarios document the new identity, primary-email, and staff-management rules before implementation. Coverage is intentionally future-facing and excluded from default Cucumber while tagged `@wip`.
- `acceptance-tests/test/cucumber_config.test.js`: update the configuration expectation so the new `@wip` feature is known to be skipped by the default browser Cucumber profile. Reason: planning-time `@wip` scenarios must not make the main check red before implementation.

## Acceptance Criteria

- Existing people retain their current email address as their primary email after migration/backfill.
- A person can have more than one normalized email address.
- Email normalization trims whitespace and lowercases addresses consistently.
- Blank or malformed email addresses are rejected.
- A person has exactly one primary email address.
- Primary email is one of the person's known email addresses.
- The first entered email address is selected as primary by default for staff create/edit forms.
- Staff create/edit validation rejects forms with no primary address or more than one primary address.
- Duplicate normalized email addresses are globally rejected so an address cannot be attached to two people.
- `Accounts.request_magic_link/1` accepts any known email address for an active member.
- When a member requests a magic link using an alternate email address, the sign-in link is delivered to that alternate address.
- A person who signs in with an alternate email still sees the clubs for their person record.
- Membership email checks recognize any known email address for the person.
- `Messaging.send_club_message/2` resolves each active member once and uses that member's primary email address for outbound delivery.
- Existing member-message receipt and delivery projections still identify recipients by person, not by email address alone.
- Dedicated staff create/edit LiveViews allow staff to create a person with primary and alternate email addresses and later edit the email set and primary selection.
- Staff/operator UI displays a person's primary email and alternate email addresses.
- Existing single-email authentication and member-message scenarios continue to pass.
- `dev check` passes.

## Open Business Decisions

None known.

Deferred decisions:

- Whether alternate email addresses must be verified before they can be used for sign-in or future inbound sending.
- Whether members can self-manage alternate emails.
- Whether and how members can see their own primary and alternate email addresses.
- Whether shared household email addresses are allowed across people, and if so how sign-in and inbound sender matching avoid ambiguity.
- Whether primary email is global per person or can vary by club. This iteration assumes global per person.

## Implementation Plan

1. Inspect current Membership person command/event/aggregate/projector/projection code, Accounts lookup code, Messaging recipient resolution, seeds, fixtures, staff/admin LiveViews, and acceptance support that assume a single `email` field.
2. Choose and implement the data shape for projected person email addresses. Suggested direction: a separate projected email-address table keyed by person and normalized email, with a global unique constraint on normalized email and a constraint/index that enforces exactly one primary address per person.
3. Add migrations to create/backfill the email-address projection from existing `membership_people.email`, mark the backfilled address primary, enforce non-null/unique constraints, and preserve compatibility with the existing person projection during the transition.
4. Update Membership person schemas/projections and public query APIs so callers can fetch a person's primary email, alternate emails, and lookup active memberships by any known address.
5. Evolve person commands/events deliberately:
   - support creating a person with one or more email addresses and exactly one primary;
   - support editing a person's email addresses and primary selection from staff UI;
   - handle legacy `PersonCreated` events containing only `email` during replay/backfill.
6. Enforce global duplicate normalized-email rejection before unsafe sign-in or sender matching can occur, using both application validation and database constraints where practical.
7. Update Accounts sign-in eligibility to search all known addresses for active members, while preserving staff `@memba.io` sign-in behaviour.
8. Ensure magic-link tokens and delivery use the normalized known address requested by the user, not necessarily the person's primary address.
9. Update active-club lookup and active-member-by-email checks to match any known address attached to the person.
10. Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.
11. Add dedicated staff LiveViews/routes for person create and edit. Link to them from the existing admin club/person list. Keep the common one-email case easy by defaulting the first entered address as primary while still making the primary choice explicit and validated.
12. Update staff/operator person displays to show primary and alternate addresses distinctly.
13. Update seeds, fixtures, browser acceptance support, and tests that create people to supply or derive the new email-address shape.
14. Add/enable the planned Cucumber scenarios in `acceptance-tests/features/person_email_addresses.feature`; remove or narrow `@wip` once implemented.
15. Run targeted Membership, Accounts, Messaging, LiveView, migration, and Cucumber checks, then `dev check`.

## Open Technical Decisions

- Exact table/schema names for projected person email addresses.
- Whether to keep `membership_people.email` as a denormalized primary-email field for compatibility/performance or replace reads with joins to the email-address projection.
- Exact database constraint strategy for “exactly one primary per person”.
- Exact command/event names for adding/removing/changing person email addresses.
- Whether person email editing is implemented as one replace-all command or as separate add/remove/change-primary commands.
- Legacy event replay strategy for old `PersonCreated` events that contain only `email`.
- How much of the existing inline person creation form remains on the admin club show page versus becoming a link to the dedicated create LiveView.

## New Capability

Memba can distinguish addresses that identify a person from the address Memba sends club messages to. Staff can manage that email-address set, members can sign in with any known address, and outbound club mail still goes once to the person's primary address.

## Validation Plan

- Run `dev check`.
- Run targeted Membership domain/projection/query tests for:
  - creating/backfilling person email addresses;
  - normalization and malformed-address rejection;
  - global duplicate normalized-email rejection;
  - exactly one primary address per person;
  - active-club and active-member lookup by alternate address.
- Run targeted Accounts tests for:
  - magic-link request accepted for an alternate email address;
  - magic-link email delivered to the address requested;
  - staff `@memba.io` sign-in remains unchanged;
  - unknown email remains neutral and receives no link.
- Run targeted Messaging tests proving club-message recipient resolution uses the primary address and sends once per person.
- Run migration/persistence tests for email-address rows, uniqueness, and one-primary constraints.
- Run staff LiveView/controller tests for person create/edit forms, primary selection defaults, validation errors, and display of primary/alternate addresses.
- Run browser Cucumber with the new `person_email_addresses.feature` once the `@wip` tag is removed or narrowed during implementation.
- Manual demo:
  1. Staff creates Alice with primary `alice@example.com` and alternate `alice@work.example`.
  2. Alice requests a sign-in link for `alice@work.example` and receives it there.
  3. Alice signs in and sees Kootenay Mountaineering Club.
  4. Bob sends a club message; Alice receives it at `alice@example.com`, not `alice@work.example`.
  5. Staff edits Alice to make `alice@work.example` primary; the next club message goes to `alice@work.example`.

## Risks / Follow-ups

- Shared household email addresses are intentionally out of scope; global uniqueness may need revisiting when that policy is designed.
- Email verification is out of scope here but will matter before members can self-add addresses.
- Member-facing display or editing of known email addresses is deferred and captured in `docs/problems.md` as a separate account/profile problem to explore.
- Existing test helpers and browser acceptance support assume a single `email` field on person projections.
- Event-sourced history may contain old `PersonCreated` events without the new email-address shape. The implementation must handle replay deliberately.
- Future inbound email should use the new sender-matching query rather than reimplementing email lookup in a controller.
