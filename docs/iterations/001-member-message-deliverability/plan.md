# Member message deliverability

Date: 2026-05-26
Status: draft

## Goal

Build the first event-sourced domain skeleton for clubs, people, memberships, and member-to-member club messages, so Memba can model and test message delivery status before adding real email-provider integration.

This iteration should prove the product-shaped core: a member can send a message to the members of their club; the system records per-member delivery state; regular members get simple receipt-style statuses; and operators can inspect detailed deliverability information per member.

## Background / Context

Memba's strategy depends on reliable club communication. Many target club members are older and not especially technical, so message status language must be simple, calm, and approachable.

ADR 0002 says new domain models should use Commanded and event sourcing by default. This iteration introduces the first real membership/message domain skeleton and includes the persistent event-store setup needed to make business events real.

ADR 0003 says shared Cucumber feature files are domain modelling artifacts and should be executable at two layers: directly against the Elixir domain model and, later, through the whole Phoenix application. This iteration starts with domain-level execution using `https://github.com/huddlz-hq/cucumber` and fake/stub ports.

`huddlz-hq/cucumber` has been checked enough for planning: the repository exists, provides an Elixir Cucumber package, documents ExUnit integration, and currently advertises `{:cucumber, "~> 0.8.0"}` as the Mix dependency.

This is not yet the live Postmark deliverability iteration. Postmark remains the likely first live provider because its 100-free-emails/month allowance is enough for validation, but this slice keeps provider integration fake so the domain model and acceptance language can settle first.

## Scope

### In scope

- Add persistent Commanded event-store support using `commanded_eventstore_adapter` and `eventstore`.
- Model minimal clubs, people, and memberships as event-sourced domain concepts.
- Keep membership minimal: a person belongs to a club as a member. Full membership lifecycle/status depth can come later.
- Model club messages as domain behaviour: any member can send a message to the members of their club.
- Use a fake/stub email-provider port for this iteration.
- Record one delivery record per addressed member.
- Record and project delivery events/statuses including sent, delivered, delayed, bounced, spam complaint, and opened.
- Model `opened` as a delivery status transition on a delivery, not as a separate receipt aggregate in this iteration.
- Provide a member-facing receipt summary projection with simple statuses: sent, delivered, delivery problem, opened.
- Provide an operator deliverability projection with detailed per-member status and provider-style reason/details.
- Add and execute shared Cucumber scenarios for member message deliverability.
- Run those scenarios against the Elixir domain model using `huddlz-hq/cucumber`.

### Out of scope

- Real Postmark sending.
- Real provider webhook endpoints.
- Tracking pixel HTTP endpoint.
- Phoenix UI/status pages.
- Authentication and permission hardening.
- Rich editor, templates, attachments, HTML email generation, and unsubscribe/preferences/compliance polish.
- Full household, renewal, payment, waiver, and membership lifecycle modelling.
- Marketing campaign analytics.
- Read receipts.

## Acceptance Criteria

- The shared feature file `acceptance-tests/features/member_message_deliverability.feature` describes the domain behaviour without UI, route, database, or adapter details.
- The same feature file remains suitable for future whole-app execution via cucumber-js/Playwright.
- Domain-level Cucumber execution runs the message deliverability scenarios against the Elixir domain model.
- A club can be created in the domain model.
- People can be created in the domain model.
- People can be made members of a club.
- Any member can send a message to the members of their club.
- Sending a message creates one delivery record per addressed member.
- The fake email-provider port is called once per delivery.
- A sent delivery appears to members as `sent`.
- A delivered delivery appears to members as `delivered`.
- A delayed delivery appears to members as `delivery problem`.
- A bounced delivery appears to members as `delivery problem`.
- A spam complaint appears to members as `delivery problem`.
- An opened delivery appears to members as `opened`.
- Operator deliverability output distinguishes sent, delivered, delayed, bounced, spam complaint, and opened.
- Operator deliverability output preserves provider-style reason/detail text when supplied.
- Unit/integration tests cover commands, aggregate decisions, event application, projections, event-store setup, and fake provider behaviour where Cucumber does not provide enough diagnostic coverage.
- `devenv shell mix precommit` passes.

## Acceptance Scenarios

The shared scenarios live in `acceptance-tests/features/member_message_deliverability.feature` and are part of this plan. They cover:

- A member sending a club message to all club members.
- Member-facing receipt status for a sent message.
- Member-facing receipt status for a delivered message.
- Member-facing receipt status for delayed, bounced, and spam-complaint delivery problems.
- Member-facing receipt status for an opened message.
- Operator-facing deliverability details for delivered, delayed, bounced, spam complaint, and opened statuses, including provider-style reason text when present.

The feature file deliberately uses domain language such as club, person, member, message, delivery record, receipt status, and operator deliverability status. It avoids UI, route, selector, database, and adapter language.

## Open Business Decisions

None known.

## Implementation Plan

1. Add `commanded_eventstore_adapter` and `eventstore` to `web/mix.exs` alongside the existing `commanded` dependency. Use current compatible stable versions for the existing `commanded ~> 1.4` dependency.
2. Configure Commanded to use `Commanded.EventStore.Adapters.EventStore` with `Commanded.Serialization.JsonSerializer`.
3. Use separate PostgreSQL event-store databases for development and test: `memba_eventstore_dev` and `memba_eventstore_test`. Keep projection/read-model tables in the existing Ecto repo database.
4. Add event-store setup/reset support to Mix aliases so development/test setup creates, initializes, and resets both the Ecto repo and the EventStore database. Test cleanup must leave both projections and event streams isolated between tests.
5. Add or update application supervision so the EventStore and Commanded application run in development and test.
6. Define the following aggregates, commands, events, and invariants:

   - **Club aggregate** (`club_id`):
     - Command: `CreateClub{club_id, name}`.
     - Event: `ClubCreated{club_id, name}`.
     - Invariant: a club stream cannot be created twice.

   - **Person aggregate** (`person_id`):
     - Command: `CreatePerson{person_id, name, email}`.
     - Event: `PersonCreated{person_id, name, email}`.
     - Invariant: a person stream cannot be created twice.

   - **Membership aggregate** (`membership_id`, with `club_id` and `person_id` fields):
     - Command: `AddMember{membership_id, club_id, person_id}`.
     - Event: `MemberAdded{membership_id, club_id, person_id}`.
     - Invariant: a membership stream cannot be created twice.
     - Cross-aggregate existence checks for club and person are handled by the application service before dispatch, not inside the aggregate.

   - **Message aggregate** (`message_id`):
     - Command: `SendMessage{message_id, club_id, sender_person_id, subject, body, sent_at}`.
     - Event: `MessageSent{message_id, club_id, sender_person_id, subject, body, sent_at}`.
     - Invariant: a message stream cannot be created twice.
     - The application service verifies the sender is a member, resolves current club members from projections, dispatches the message command, then creates one delivery per addressed member.

   - **Delivery aggregate** (`delivery_id`):
     - Command: `CreateDelivery{delivery_id, message_id, recipient_person_id, recipient_email, sent_at}`.
     - Event: `DeliveryCreated{delivery_id, message_id, recipient_person_id, recipient_email, status: :sent, sent_at}`.
     - Command: `RecordDeliveryStatus{delivery_id, status, reason, occurred_at}`.
     - Event: `DeliveryStatusRecorded{delivery_id, status, reason, occurred_at}`.
     - Valid statuses: `:sent`, `:delivered`, `:delayed`, `:bounced`, `:spam_complaint`, `:opened`.
     - Valid transitions: `sent -> delivered`, `sent -> delayed`, `delayed -> delivered`, `sent -> bounced`, `delayed -> bounced`, `sent -> spam_complaint`, `delivered -> spam_complaint`, `delivered -> opened`.
     - Invalid transitions are rejected by the aggregate.

7. Define a fake/stub email-provider port used by the message-sending application service in tests. For this iteration, fake provider success means Memba has handed the delivery to the provider; the resulting delivery state is `sent`.
8. Build Ecto projections/read models for current clubs, people, memberships, messages, deliveries, member-facing receipt summaries, and operator deliverability details.
9. Add the Elixir Cucumber dependency and configure it to execute the shared scenarios against the domain model. If the package proves incompatible during implementation, stop and report the incompatibility rather than silently replacing the acceptance approach.
10. Add domain-level Cucumber step definitions for the shared scenarios using fake/stub ports.
11. Keep the existing cucumber-js/Playwright setup available for future whole-app execution of the same scenarios, but do not implement the Phoenix UI layer in this iteration.
12. Add lower-level ExUnit tests where useful for event-store setup, aggregate rules, projector behaviour, and fake provider interactions.
13. Run `devenv shell mix precommit` and fix any issues.

## Open Technical Decisions

- Exact package versions for `commanded_eventstore_adapter`, `eventstore`, and `cucumber` should be chosen during implementation by selecting versions compatible with the existing Elixir, Phoenix, and Commanded versions.
- Exact folder structure for Elixir Cucumber step definitions should be chosen during implementation. The shared feature file path is fixed for this iteration: `acceptance-tests/features/member_message_deliverability.feature`.

## New Capability

After this iteration, Memba will have an event-sourced domain skeleton for clubs, people, memberships, and club messages. It will be able to model a member sending a message to club members and to project both simple member-facing receipt statuses and detailed operator deliverability information, using a fake provider.

This creates the product-shaped foundation for the next iteration: live Postmark sending, provider webhooks, tracking pixels, and a real deliverability demo with test inboxes.

## Validation Plan

- Use the shared Cucumber feature file as the domain model specification for this iteration.
- Run the shared scenarios against the Elixir domain model with `huddlz-hq/cucumber` and fake/stub ports.
- Keep scenarios abstract from infrastructure so they can later run through cucumber-js/Playwright against the whole Phoenix app.
- Add ExUnit tests for lower-level technical details that are not appropriate in Gherkin.
- Run `devenv shell mix precommit` before considering implementation complete.
- No live provider/manual inbox demo is required in this iteration; that belongs to the follow-up Postmark deliverability iteration.

## Risks / Follow-ups

- Event-store setup may reveal package-version or database lifecycle issues; if so, resolve them before adding live email integration.
- The shared-scenario/two-runner approach is new to this project and may need folder/test-runner refinement.
- The minimal membership model may need to evolve soon to include active/lapsed membership state, households, renewals, privacy preferences, and unsubscribe/compliance rules.
- The next slice should integrate Postmark end to end: real sending, webhooks, tracking pixel, and a manual demo script using Gmail, Outlook/Hotmail, and other test inboxes.
