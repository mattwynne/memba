# Task 001 inspection notes

## ADRs reviewed

- ADR 0002: Membership behaviour should remain command/event/aggregate based by default.
- ADR 0007: Messaging depends on Membership's public query API for recipient resolution, not Membership projection storage details.
- ADR 0009: read models should continue to use `commanded_ecto_projections`.
- ADR 0010: shared feature files live under `acceptance-tests/features/` and Elixir step definitions under `web/test/features/step_definitions/`.
- ADR 0011: person aggregate identity remains caller-generated `person_id`; email addresses must not become aggregate identities.
- ADR 0013: feature-style web tests should use PhoenixTest where suitable, with lower-level LiveView helpers only when needed.
- ADR 0015: member application pages default to LiveView; this iteration's new staff/admin LiveViews should still follow existing Phoenix/LiveView conventions.

## Membership write model single-email assumptions

- `web/lib/memba/membership/commands/create_person.ex`
  - `Memba.Membership.Commands.CreatePerson` enforces `[:person_id, :name, :email]` and has only `:email` for identity/contact data.
  - Later command evolution needs to keep `email` for compatibility and add optional replace-all `email_addresses`.
- `web/lib/memba/membership/events/person_created.ex`
  - `Memba.Membership.Events.PersonCreated` enforces and serializes `[:person_id, :name, :email]`.
  - Legacy replay requirement means this event should keep `email` as primary email.
- `web/lib/memba/membership/person.ex`
  - Aggregate state is `%Person{person_id, name, email}`.
  - `execute/2` for `CreatePerson` trims/downcases a single email and rejects blank or malformed values with `{:error, :invalid_email}`.
  - `apply/2` stores one `email`.
  - Multi-address validation will need to preserve current single-email normalization for existing callers while adding at-least-one/exactly-one-primary validation for the new shape.
- `web/lib/memba/membership/router.ex`
  - Routes only `CreatePerson` to the `Person` aggregate. `ReplacePersonEmailAddresses` will need to be routed to the same aggregate by `person_id`.

## Membership projection and persistence single-email assumptions

- `web/lib/memba/membership/projections/person.ex`
  - `Memba.Membership.Projections.Person` maps `membership_people` with primary key `person_id` and fields `name` and `email`.
  - The plan requires keeping `membership_people.email` as a denormalized primary-email field during this iteration.
- `web/lib/memba/membership/projectors/person.ex`
  - Projects `PersonCreated` by inserting one `membership_people` row with `event.email`.
  - Later projector work must also create/upsert one primary `membership_person_email_addresses` row for legacy `PersonCreated`, replace rows on `PersonEmailAddressesReplaced`, and update `membership_people.email` to `primary_email`.
- `web/priv/repo/migrations/20260529145014_create_membership_people_projection.exs`
  - Creates `membership_people(person_id uuid primary key, name text not null, email text not null, timestamps)`.
  - The new email-address table/backfill must reference `membership_people.person_id` and preserve existing `email` values as initial primary addresses.
- `web/config/config.exs` and `web/test/support/event_sourced_case.ex`
  - The configured event-sourced projection tables/projector reset list currently know about `membership_people` and `Memba.Membership.Projectors.Person`.
  - The new projected table and any new projector module must be added to reset/config support so event-sourced tests remain isolated.

## Membership public query API single-email assumptions

- `web/lib/memba/membership.ex`
  - `create_person/2` builds `%CreatePerson{person_id, name, email}` from attrs.
  - `list_people/0` returns `Person` projections directly, exposing one `person.email`.
  - `list_active_members_of_club/1` joins active memberships to `membership_people` and returns maps `%{id, name, email}` where `email` is `person.email`. This is the public boundary Messaging currently consumes.
  - `list_active_clubs_for_member_email/1` normalizes input and matches `fragment("lower(btrim(?))", person.email)`.
  - `active_member_of_club_by_email?/2` normalizes input and matches the same single `person.email`.
  - The new known-address lookup APIs should join `membership_person_email_addresses` by `normalized_email`; recipient resolution should still return one row per active member using the primary address.
- Existing query tests in `web/test/memba/membership/query_test.exs` prove single-email behaviour and normalization. They are the natural place to add alternate-address lookup and primary-recipient coverage.

## Accounts single-email assumptions

- `web/lib/memba/accounts.ex`
  - `normalize_email/1` trims/downcases for auth lookup and token storage.
  - `request_sign_in_link/2` creates a token for the normalized requested address if `staff_email?/1` or `list_active_clubs_for_email/1` succeeds.
  - `list_active_clubs_for_email/1` and `active_member_of_club?/2` delegate through Membership's single-email lookup APIs.
  - Token creation and delivery already use the normalized address requested by the user, so alternate-email support should mostly come from Membership known-address lookup while preserving staff `@memba.io` behaviour.
- `web/lib/memba_web/controllers/auth_controller.ex`
  - Calls `Accounts.request_sign_in_link/1`, then delivers to the returned `recipient_email`.
  - Consumed tokens sign in as the token email, which may become an alternate address.
- Existing tests in `web/test/memba/accounts_test.exs` cover staff sign-in, active-member token creation, unknown neutral responses, and active-club lookup by one email.

## Messaging recipient-resolution single-email assumptions

- `web/lib/memba/messaging.ex`
  - `send_club_message/2` resolves recipients through `Membership.list_active_members_of_club/1`.
  - `resolved_recipient/1` expects `%{id, name, email}` and stores that `email` on `Memba.Messaging.Recipient`.
  - Provider handoff uses `recipient.email` as `EmailDeliveryRequest.recipient_address`.
  - ADR 0007 means this should stay a Membership public query dependency, not a direct join against `membership_person_email_addresses` in Messaging.
- `web/lib/memba/messaging/recipient.ex`
  - Struct is still single-recipient-address shaped with enforced `:email`, which is compatible with the plan because outbound delivery remains one primary address per person.
- `web/test/memba/messaging/send_club_message_test.exs`
  - Existing assertions expect one delivery event and provider request per active member and compare `recipient_email`/`recipient_address` to the person's single `email`.
  - Add primary-address-only coverage here once multiple addresses exist.

## Staff/admin LiveView single-email assumptions

- `web/lib/memba_web/live/admin/clubs_live/show.ex`
  - Inline person creation is owned by club show via `@empty_person %{"name" => "", "email" => ""}` and a `"create_person"` event.
  - The form has a single `Person email` input and submits `%{"name", "email"}` to `Membership.create_person/2`.
  - People and members lists display `person.email` / `member.email`.
  - The plan requires moving create/edit into dedicated `/admin/clubs/:club_id/people/new` and `/admin/clubs/:club_id/people/:person_id/edit` LiveViews, replacing this inline form with links and showing primary/alternate information distinctly.
- `web/test/memba_web/live/admin/clubs_live/show_test.exs`
  - Currently focuses on club slug editing, but browser acceptance harness tests still assert the inline person form exists.
- `web/test/memba_web/live/browser_acceptance_harness_test.exs`
  - Asserts `#person-name-input[aria-label='Person name']` and `#person-email-input[aria-label='Person email']`, then creates people through the inline staff form.
  - Will need update when inline creation is removed and dedicated create/edit pages are introduced.

## Seeds, fixtures, and test-helper single-email assumptions

- `web/priv/repo/seeds.exs`
  - Inserts `membership_people` rows directly with a single `email`.
  - Messaging seed deliveries use `recipient_address` values that match those single emails.
  - Later seed updates must insert `membership_person_email_addresses` primary rows or use the new public creation path.
- `web/test/support/membership_fixtures.ex`
  - Currently only has club helpers; many tests hand-roll person creation with an `email` attribute.
- `web/test/features/step_definitions/membership_steps.exs`
  - Elixir Cucumber creates people by dispatching `%CreatePerson{person_id, name, email}` with a derived single email and stores only `person_id` in context.
- `web/test/features/step_definitions/authentication_steps.exs`
  - Domain Cucumber creates people through `Membership.create_person(%{person_id, name, email})` and stores one email per person in context.
- Common direct single-email test helpers appear in:
  - `web/test/memba/membership/person_test.exs`
  - `web/test/memba/membership/create_person_dispatch_test.exs`
  - `web/test/memba/membership/person_projection_test.exs`
  - `web/test/memba/membership/public_api_test.exs`
  - `web/test/memba/membership/query_test.exs`
  - `web/test/memba/messaging/send_club_message_test.exs`
  - `web/test/memba/accounts_test.exs`

## Browser acceptance support single-email assumptions

- `acceptance-tests/features/person_email_addresses.feature`
  - Already exists and is tagged `@wip`, matching the plan's allowed acceptance feature change.
  - Scenarios mention primary and alternate emails, but step definitions are not implemented yet.
- `acceptance-tests/test/cucumber_config.test.js`
  - Expects `person_email_addresses.feature` to be skipped by the default browser Cucumber profile while `@wip`.
- `acceptance-tests/features/support/member_message.js`
  - `createPerson` and `createPersonOnCurrentClubPage` fill `"Person email"` and store `world.people[name] = {email, name, personId}`.
  - Message mailbox assertions check delivery to `person.email`.
- `acceptance-tests/features/support/authentication.js`
  - `ensurePerson` creates a person with one auth email.
  - Sign-in request/link assertions use one stored `person.email`.
  - Signed-in assertions expect UI text `Signed in as ${person.email}`.
- `acceptance-tests/features/support/member_harness.js`
  - `signInMember` uses `person.email`.
  - `personFromWorld` asserts a single `person.email` is present.
  - Mailbox matching looks for the requested single address.

## Implementation implications for following tasks

- Keep `membership_people.email` as the denormalized primary email for compatibility while introducing `membership_person_email_addresses` as the known-address lookup table.
- Add the new projection table/schema and include the table/projector in test reset/config before relying on event-sourced tests.
- Preserve current single-email `CreatePerson` callers and legacy `PersonCreated` replay, then layer the replace-all email-address event model on top.
- Update Membership known-address queries first so Accounts and Messaging can keep depending on public Membership APIs.
- Keep Messaging recipient shape as one resolved address per person, but ensure that address comes from the person's primary email.
- Replace staff inline person creation only when the dedicated create/edit LiveViews and tests are ready.
