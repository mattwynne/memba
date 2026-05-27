# Member message deliverability

Date: 2026-05-26
Status: draft

## Goal

Build the first event-sourced domain skeleton for clubs, people, memberships, and member-to-member club messages, so Memba can model and test message delivery status before adding real email-provider integration.

This iteration should prove the product-shaped core: a member can send a message to the members of their club; the system records per-recipient delivery state; regular members get simple receipt-style statuses; and operators can inspect detailed deliverability information per member.

## Background / Context

Memba's strategy depends on reliable club communication. Many target club members are older and not especially technical, so message status language must be simple, calm, and approachable.

Key architectural decisions for this iteration are captured in ADRs:

- ADR 0002: use Commanded and event sourcing by default.
- ADR 0003: use shared Cucumber feature files at domain and whole-app layers.
- ADR 0004: model message deliverability as one message aggregate per message.
- ADR 0005: include resolved recipients in message send commands.
- ADR 0006: simplify member-facing delivery status.
- ADR 0007: use separate Membership and Messaging Commanded contexts.
- ADR 0008: use the same PostgreSQL database with a dedicated EventStore schema.
- ADR 0009: use `commanded_ecto_projections` for read models.
- ADR 0010: use shared feature files with Elixir Cucumber.
- ADR 0011: use caller-generated UUID aggregate identities.
- ADR 0012: track whether a message delivery was opened, not how many times.

This is not yet the live Postmark deliverability iteration. Postmark remains the likely first live provider because its 100-free-emails/month allowance is enough for validation, but this slice keeps provider integration fake so the domain model and acceptance language can settle first.

## Scope

### In scope

- Add persistent Commanded EventStore support using `commanded_eventstore_adapter` and `eventstore` as decided in ADR 0008.
- Add `commanded_ecto_projections` as decided in ADR 0009.
- Add Elixir Cucumber using the shared feature-file setup from ADR 0010.
- Model minimal Membership context concepts: clubs, people, and memberships.
- Model Messaging context concepts: member-sent club messages and per-recipient delivery state.
- Resolve recipients as all active members of the message's club at send time, including the sending member and excluding members of other clubs.
- Use a fake/stub delivery provider port for this iteration.
- Record one recipient delivery per resolved recipient.
- Record and project delivery statuses: sent, delivered, delayed, bounced, spam complaint, and opened.
- Provide a member-facing receipt projection/query with simple statuses: sent, delivered, delivery problem, opened.
- Provide an operator deliverability projection/query with detailed per-member status and reason/details.
- Execute the shared Cucumber scenarios against the Elixir domain model using fake/stub ports.

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
- Open counts, last-opened time, device/client diagnostics, or repeated-open tracking.

## Acceptance Criteria

- The shared feature files describe the domain behaviour without UI, route, database, or adapter details:
  - `acceptance-tests/features/member_message_deliverability.feature`
  - `acceptance-tests/features/operator_email_deliverability.feature`
- The same feature files remain suitable for future whole-app execution via cucumber-js/Playwright.
- Domain-level Cucumber execution runs those scenarios against the Elixir domain model.
- A club can be created in the Membership context.
- A person can be created in the Membership context independently of any club.
- A person can be made an active member of a club.
- Any active member can send a message to the active members of their club.
- Sending a message to one club does not address members of another club.
- Sending a message creates one recipient delivery per resolved recipient.
- The fake delivery provider port is called once per recipient delivery.
- Member-facing receipt status mapping follows ADR 0006.
- Operator deliverability output distinguishes sent, delivered, delayed, bounced, spam complaint, and opened.
- Operator deliverability output preserves reason/detail text when supplied.
- Repeated open reports are idempotent and only answer whether the delivery was opened at least once, as decided in ADR 0012.
- Unit/integration tests cover commands, aggregate decisions, event application, projections, EventStore setup, and fake provider behaviour where Cucumber does not provide enough diagnostic coverage.
- `devenv shell mix precommit` passes.

## Acceptance Scenarios

The shared scenarios live in:

- `acceptance-tests/features/member_message_deliverability.feature`
- `acceptance-tests/features/operator_email_deliverability.feature`

They are part of this plan and must exist before implementation starts.

### Member message deliverability scenarios

- A member sends a club message to members of their club, and a member of another club is not addressed.
- A sent message is waiting for delivery confirmation.
- A delivered message is shown as delivered.
- A delayed delivery is shown as a delivery problem.
- A bounced delivery is shown as a delivery problem.
- A spam complaint is shown as a delivery problem.
- An opened message is shown as opened.

### Operator email deliverability scenarios

- A delivered email is visible to operators.
- A delayed delivery is visible to operators, with reason preserved.
- A bounced delivery is visible to operators, with reason preserved.
- A spam complaint is visible to operators, with reason preserved.
- An opened email is visible to operators.

## Open Business Decisions

None known.

## Implementation Plan

1. Add dependencies and configuration for:
   - `commanded_eventstore_adapter` and `eventstore` per ADR 0008;
   - `commanded_ecto_projections` per ADR 0009;
   - `{:cucumber, github: "huddlz-hq/cucumber"}` per ADR 0010.
2. Configure EventStore in the same environment database as the Phoenix/Ecto app, using a dedicated schema such as `event_store`. Keep projections/read models in the application schema.
3. Add setup/reset/test support so Ecto projections and EventStore state are created and cleaned correctly in development and test.
4. Add separate Commanded apps and routers for Membership and Messaging, per ADR 0007:
   - `Memba.Membership.App` and `Memba.Membership.Router`;
   - `Memba.Messaging.App` and `Memba.Messaging.Router`.
5. Implement caller-generated UUID aggregate identities per ADR 0011.
6. Implement minimal Membership aggregates, commands, and events:
   - Club: create a club.
   - Person: create a person with name and email; person identity is club-independent.
   - Membership: add a person as an active member of a club. For this iteration, memberships are active from creation and cannot lapse, expire, or be revoked.
7. Implement Membership projections/read models and a public Membership query API. Messaging must call this query API to resolve active club members; it must not depend directly on Membership Ecto schemas or projection tables.
8. Implement the Messaging aggregate as one aggregate per message per ADR 0004.
9. Implement `SendMessage` so the application service resolves recipients via Membership's query API and includes those resolved recipients in the command, per ADR 0005.
10. Have the Message aggregate emit `MessageSent` plus one recipient delivery event per resolved recipient in the message stream.
11. Implement the delivery status state machine inside the Message aggregate:
    - statuses: sent, delivered, delayed, bounced, spam complaint, opened;
    - member-facing mapping from ADR 0006;
    - opened semantics from ADR 0012;
    - invalid transitions rejected;
    - duplicate equivalent status reports idempotent.
12. Define a fake/stub delivery provider port used by the message-sending service/tests. For this iteration, fake provider success means Memba has handed the delivery to the provider.
13. Implement Messaging projections/read queries for messages, recipient deliveries, member-facing receipts, and operator deliverability details using `commanded_ecto_projections`.
14. Configure Elixir Cucumber to read shared feature files from `acceptance-tests/features/**/*.feature` and execute domain step definitions from the Phoenix app test suite, per ADR 0010.
15. Add domain-level Cucumber step definitions for the shared member-message and operator-deliverability scenarios using fake/stub ports.
16. Keep the existing cucumber-js/Playwright setup available for future whole-app execution of the same scenarios, but do not implement the Phoenix UI layer in this iteration.
17. Add lower-level ExUnit tests where useful for EventStore setup, aggregate rules, projector behaviour, status-transition idempotency, and fake provider interactions.
18. Run `devenv shell mix precommit` and fix any issues.

## Open Technical Decisions

- Exact compatible package versions should be chosen during implementation for `commanded_eventstore_adapter`, `eventstore`, `commanded_ecto_projections`, and the GitHub Cucumber dependency.
- Exact folder structure for Elixir Cucumber support code should be chosen during implementation, while preserving ADR 0010's shared feature-file paths.

## New Capability

After this iteration, Memba will have event-sourced Membership and Messaging domain skeletons. It will be able to model a member sending a message to all active members of their club, create per-recipient delivery state, and project both simple member-facing receipt statuses and detailed operator deliverability information using a fake provider.

This creates the product-shaped foundation for the next iteration: live Postmark sending, provider webhooks, tracking pixels, and a real deliverability demo with test inboxes.

## Validation Plan

- Use the shared Cucumber feature files as the domain model specification for this iteration.
- Run the shared scenarios against the Elixir domain model with `huddlz-hq/cucumber` and fake/stub ports.
- Keep scenarios abstract from infrastructure so they can later run through cucumber-js/Playwright against the whole Phoenix app.
- Add ExUnit tests for lower-level technical details that are not appropriate in Gherkin.
- Run `devenv shell mix precommit` before considering implementation complete.
- No live provider/manual inbox demo is required in this iteration; that belongs to the follow-up Postmark deliverability iteration.

## Risks / Follow-ups

- EventStore setup may reveal package-version or database lifecycle issues; if so, resolve them before adding live delivery-provider integration.
- The shared-scenario/two-runner approach is new to this project and may need folder/test-runner refinement.
- The minimal membership model may need to evolve soon to include active/lapsed membership state, households, renewals, privacy preferences, and unsubscribe/compliance rules.
- Future notification channels may require changing delivery-channel fields and provider abstractions; ADR 0005 says to keep the shape channel-neutral where practical.
- The next slice should integrate Postmark end to end: real sending, webhooks, tracking pixel, and a manual demo script using Gmail, Outlook/Hotmail, and other test inboxes.
