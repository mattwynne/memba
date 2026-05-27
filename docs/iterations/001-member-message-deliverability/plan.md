# Member message deliverability

Date: 2026-05-26
Status: draft

## Goal

Build the first event-sourced domain skeleton for clubs, people, memberships, and member-to-member club messages, so Memba can model and test message delivery status before adding real email-provider integration.

This iteration should prove the product-shaped core: a member can send a message to the members of their club; the system records per-member delivery state; regular members get simple receipt-style statuses; and operators can inspect detailed deliverability information per member.

## Background / Context

Memba's strategy depends on reliable club communication. Many target club members are older and not especially technical, so message status language must be simple, calm, and approachable.

ADR 0002 says new domain models should use Commanded and event sourcing by default. This iteration introduces the first real membership/message domain skeleton and should therefore include the persistent event-store setup needed to make business events real.

ADR 0003 says shared Cucumber feature files are domain modelling artifacts and should be executable at two layers: directly against the Elixir domain model and, later, through the whole Phoenix application. This iteration starts with domain-level execution using `https://github.com/huddlz-hq/cucumber` and fake/stub ports.

This is not yet the live Postmark deliverability iteration. Postmark remains the likely first live provider because its 100-free-emails/month allowance is enough for validation, but this slice keeps provider integration fake so the domain model and acceptance language can settle first.

## Scope

### In scope

- Add persistent Commanded event-store support, using the standard PostgreSQL Commanded EventStore adapter unless implementation discovers a blocker.
- Model minimal clubs, people, and memberships as event-sourced domain concepts.
- Keep membership minimal: a person belongs to a club as a member. Full membership lifecycle/status depth can come later.
- Model club messages as domain behaviour: a member sends a message to the members of their club.
- Use a fake/stub email-provider port for this iteration.
- Record one delivery record per addressed member.
- Record and project delivery events/statuses including sent, delivered, delayed, bounced, spam complaint, and opened.
- Provide a member-facing receipt summary projection with simple statuses: sent, delivered, delivery problem, opened.
- Provide an operator deliverability projection with detailed per-member status and provider-style reason/details.
- Add shared Cucumber scenarios for member message deliverability.
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
- The same feature file is suitable for future whole-app execution via cucumber-js/Playwright.
- Domain-level Cucumber execution runs the message deliverability scenarios against the Elixir domain model.
- A club can be created in the domain model.
- People can be created in the domain model.
- People can be made members of a club.
- A member can send a message to the members of their club.
- Sending a message creates one delivery record per addressed member.
- The fake email-provider port is called once per delivery.
- A sent delivery appears to members as `sent`.
- A delivered delivery appears to members as `delivered`.
- A bounced delivery appears to members as `delivery problem`.
- An opened delivery appears to members as `opened`.
- Operator deliverability output distinguishes at least sent, delivered, delayed, bounced, spam complaint, and opened.
- Operator deliverability output preserves provider-style reason/detail text when supplied.
- Unit/integration tests cover commands, aggregate decisions, event application, projections, and fake provider behaviour where Cucumber does not provide enough diagnostic coverage.
- `devenv shell mix precommit` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Add the persistent event-store dependency/configuration for Commanded, using the standard PostgreSQL Commanded EventStore adapter unless blocked.
2. Add or update the application supervision/configuration so Commanded and the event store run in development and test.
3. Define the initial commands/events/aggregates for:
   - creating a club;
   - creating a person;
   - adding a person as a club member;
   - sending a message to club members;
   - recording delivery status changes: sent, delivered, delayed, bounced, spam complaint, opened.
4. Define a fake/stub email-provider port used by the message-sending application service in tests.
5. Build Ecto projections/read models for current clubs, people, memberships, messages, deliveries, member-facing receipt summaries, and operator deliverability details.
6. Add the shared feature file for member message deliverability.
7. Add domain-level Cucumber configuration/step definitions using `huddlz-hq/cucumber` to execute the shared scenarios directly against the Elixir domain model.
8. Keep the existing cucumber-js/Playwright setup available for future whole-app execution of the same scenarios, but do not implement the Phoenix UI layer in this iteration.
9. Add lower-level ExUnit tests where useful for event-store setup, aggregate rules, projector behaviour, and fake provider interactions.
10. Run `devenv shell mix precommit` and fix any issues.

## Open Technical Decisions

- Exact package versions and configuration details for `commanded_eventstore` / EventStore should be chosen during implementation.
- Exact folder structure for shared feature files and the two Cucumber execution layers should be chosen during implementation, preserving ADR 0003's requirement that the same scenarios can run at both layers.
- Whether `opened` should be represented as a delivery status, a separate receipt event, or both. The user-facing projection must still show `opened` as the simple receipt status.

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

- Event-store setup may reveal configuration or package-version issues; if so, resolve them before adding live email integration.
- The shared-scenario/two-runner approach is new to this project and may need folder/test-runner refinement.
- The minimal membership model may need to evolve soon to include active/lapsed membership state, households, renewals, privacy preferences, and unsubscribe/compliance rules.
- The next slice should integrate Postmark end to end: real sending, webhooks, tracking pixel, and a manual demo script using Gmail, Outlook/Hotmail, and other test inboxes.
