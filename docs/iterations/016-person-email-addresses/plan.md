# Multiple email addresses per person

Date: 2026-06-01
Status: draft

## Goal

Let a person have more than one email address, with exactly one primary email address used for outbound club messages.

After this iteration, Memba can recognize a member by any known email address attached to their person record, while still sending club messages to that person's primary email address. This prepares for inbound email, where members may send from personal aliases, work addresses, or old addresses, without forcing outbound club mail to go to every known address.

## Background / Context

Memba currently stores one `email` on each Membership person projection. That single value is used for several jobs: magic-link sign-in, finding active clubs for a signed-in email, checking active membership by email, and resolving outbound club-message recipients.

Inbound email needs a more precise model. A person may have multiple legitimate sender addresses, but Memba should normally deliver each club message to one address per person. Separating known addresses from primary sending address gives us that distinction.

This draft is captured for later refinement. It should not be delivered until iteration 015 is refined and implemented.

## Scope

### In scope

- Add support for multiple normalized email addresses per person.
- Ensure each person has exactly one primary email address.
- Treat the existing person `email` value as the initial primary email during migration/backfill.
- Use the primary email address for outbound club-message recipient resolution.
- Let authentication/magic-link eligibility recognize any known email address attached to an active member.
- Let active-member-by-email checks recognize any known email address attached to an active member.
- Add public Membership query APIs needed by Accounts and future inbound email sender matching.
- Add database/projection support for person email addresses.
- Add staff/operator UI affordances to display a person's primary and alternate email addresses.
- Add tests for migration/backfill, normalization, uniqueness, primary selection, authentication lookup, active-member lookup, and outbound recipient resolution.
- Keep existing single-email flows working.
- Keep `dev check` green.

### Out of scope

- Postmark inbound email setup.
- Inbound webhook controller.
- Sending club messages by emailing a club address.
- Email verification workflow for newly-added alternate addresses.
- Member self-service email address management.
- Sending outbound club messages to more than one address per person.
- Per-club email preferences.
- Bounce-driven automatic primary-email changes.
- Household/shared-email policy beyond preserving current behaviour where possible.

## Iteration Type

Behaviour-facing data/model slice.

The changed user-observable rules are:

- a known member can sign in using any email address attached to their person record;
- outbound club messages still go to one primary email address per active member.

## Acceptance Scenarios / Feature Files

BDD decision: Required when this draft is refined.

This iteration changes identity and message-delivery business rules, so stakeholder-readable examples are useful. During refinement, add or update shared Cucumber scenarios for examples such as:

- Alice signs in with an alternate email address.
- Alice receives club messages at her primary email address even though she has multiple known addresses.

No feature file is added in this capture commit; formulation should happen when this iteration is actively planned.

## Acceptance Criteria

- Existing people retain their current email address as their primary email after migration/backfill.
- A person can have more than one normalized email address.
- A person has exactly one primary email address.
- Primary email is one of the person's known email addresses.
- Email normalization trims whitespace and lowercases addresses consistently.
- Blank or malformed email addresses are rejected.
- Duplicate email addresses are handled deliberately so authentication and future inbound sender matching are not unsafe.
- `Accounts.request_magic_link/1` accepts any known email address for an active member.
- A person who signs in with an alternate email still sees the clubs for their person record.
- Membership email checks recognize any known email address for the person.
- `Messaging.send_club_message/2` resolves each active member once and uses that member's primary email address for outbound delivery.
- Existing member-message receipt and delivery projections still identify recipients by person, not by email address alone.
- Staff/operator UI displays a person's primary email and alternate email addresses.
- Existing single-email authentication and member-message scenarios continue to pass.
- `dev check` passes.

## Open Business Decisions

- Whether alternate email addresses must be verified before they can be used for sign-in or future inbound sending.
- Whether members can self-manage alternate emails, or only staff/operators can edit them.
- Whether shared household email addresses are allowed across people, and if so how sign-in and inbound sender matching avoid ambiguity.
- Whether primary email is global per person or can vary by club. This draft assumes global per person.

## Implementation Plan

Draft outline for later refinement:

1. Inspect current Membership person command/event/aggregate/projector/projection code, Accounts lookup code, Messaging recipient resolution, seeds, fixtures, and staff/operator UI surfaces that show people.
2. Choose the data shape for email-address projections.
3. Add migrations and backfill the existing `membership_people.email` as primary.
4. Update projection schemas and Membership query APIs.
5. Decide how to evolve event-sourced person commands/events and handle legacy `PersonCreated` events.
6. Update Accounts sign-in eligibility and active-club lookup to search all known addresses.
7. Update Messaging recipient resolution to use primary email only.
8. Add staff/operator UI display for primary and alternate addresses.
9. Add/refine acceptance scenarios and focused tests.
10. Run `dev check`.

## Open Technical Decisions

- Whether to model email-address changes as first-class event-sourced person commands/events now, or introduce the read-model structure first with minimal event evolution.
- Exact database constraints for one primary per person.
- Exact global uniqueness policy for normalized email addresses.
- Legacy event replay strategy for old `PersonCreated` events that contain only `email`.

## New Capability

Memba can distinguish addresses that identify a person from the address Memba sends club messages to, which is required before inbound email can safely accept messages from member aliases.

## Validation Plan

To be refined before delivery. Expected checks include:

- `dev check`.
- Targeted Membership domain/projection tests.
- Targeted Accounts tests for magic-link request and club lookup via alternate email.
- Targeted Messaging tests for recipient resolution using primary email.
- Migration/persistence tests for email-address rows, uniqueness, and one-primary constraints.
- Shared Cucumber scenarios added during refinement.

## Risks / Follow-ups

- Shared household email addresses may conflict with global uniqueness.
- Email verification is out of scope here but will matter before members can self-add addresses.
- Existing test helpers may assume a single `email` field on person projections.
- Future inbound email should use the new sender-matching query rather than reimplementing email lookup in a controller.
