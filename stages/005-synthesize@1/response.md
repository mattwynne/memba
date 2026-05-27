# Final Readiness Review

## 1. Decision: NOT READY

## 2. Confidence: High

All three reviewers independently identified material gaps. After synthesizing and filtering their findings, several blocking issues remain that would force an implementing engineer to make product or architectural decisions mid-flight.

## 3. Consensus Findings

- **Open `opened` status decision is blocking.** All three reviewers flagged the "whether `opened` should be a delivery status, a separate receipt event, or both" question as a real design decision that affects aggregate design, event schemas, and projector logic. An engineer cannot implement the aggregate, events, and projections without knowing this.
- **Commanded/EventStore dependency strategy is underspecified.** The plan says "add the persistent event-store dependency" but does not name a concrete package or confirm availability. `commanded_eventstore_adapter` relies on the `eventstore` package which uses its own PostgreSQL schema; the plan doesn't address whether to use a separate database, shared database with prefixed schemas, or in-memory store for tests. This is a real technical design decision, not a "pick a version" detail.
- **Aggregate and event design is listed but not specified.** The plan lists six command/event families but doesn't define their fields, invariants, or aggregate boundaries. For a first-ever CQRS/ES introduction into the codebase, this is a material design gap — an engineer would have to decide aggregate boundaries (e.g., is `Message` its own aggregate or part of `Club`?), which events carry which data, and what invariants each aggregate enforces.
- **Cucumber integration path is uncertain.** The plan references `huddlz-hq/cucumber` but doesn't confirm it exists, is compatible with current Elixir/OTP versions, or how it integrates with Mix test infrastructure. Two reviewers flagged this; the third noted it as a risk.
- **Acceptance criteria are implicit in a not-yet-written feature file.** The plan says "add the shared feature file" as an implementation step, meaning the acceptance criteria don't exist yet. A plan should contain or reference concrete, testable acceptance criteria before implementation begins.

## 4. Corrected Findings

| Reviewer Finding | Correction |
|---|---|
| **Gemini: folder structure is blocking** | Downgraded to non-blocking. Folder layout is an organizational choice that can be made during implementation without affecting correctness. |
| **Codex: exact package versions are blocking** | Partially downgraded. Exact *versions* are not blocking, but the *choice of adapter package* and *database topology* (separate DB vs. shared with schema prefix vs. in-memory for test) is blocking. |
| **Claude: need full event/command schema tables** | Partially agree. Full schema tables would be ideal but a clear written description of aggregate boundaries, key invariants, and event names/core fields is sufficient. We don't need SQL DDL. |
| **Gemini: missing rollback/failure handling plan** | Rejected as blocking. First iteration with fake provider doesn't need a rollback plan. Nice-to-have for later. |
| **Codex: need to specify projection storage (Ecto schemas)** | Agree this should be addressed but downgraded from blocking to near-blocking. The projections are read models over events; their Ecto schema design follows naturally from the event design. Once events are defined, projections are straightforward. |
| **Claude: "sent" vs "queued" status ambiguity** | Rejected. With a fake provider in this iteration, "sent" is unambiguous — the fake acknowledges the send. Real provider status semantics belong to the Postmark iteration. |

## 5. Blocking Gaps

1. **`opened` event modeling decision is unmade.** The plan explicitly lists this as an open technical decision. It affects: the delivery aggregate's state transitions, the event schemas, and both projector implementations (member-facing and operator-facing). The plan author must decide before implementation. *Why it blocks:* An engineer cannot define the aggregate, events, or projections without knowing whether `opened` is a delivery status transition, a separate event on a different aggregate, or both.

2. **Commanded infrastructure design is unspecified.** The plan must state: (a) which adapter package to use (`commanded_eventstore_adapter` + `eventstore`, or `commanded_extreme_adapter`, or Commanded's in-memory adapter for this iteration); (b) whether the event store uses a separate Postgres database or a schema prefix in the existing DB; (c) how the test environment handles event store state (in-memory, sandboxed, truncated). *Why it blocks:* These choices affect `mix.exs`, `config/`, supervision tree, and CI setup. They cannot be deferred to "during implementation" for a first-ever ES introduction.

3. **Aggregate boundaries and core invariants are undefined.** The plan must specify at minimum: which aggregates exist (e.g., `Club`, `Person`, `Membership`, `Message`, `Delivery`), which commands target which aggregate, and what invariants each aggregate enforces (e.g., "a person can only be added as a member to an existing club" — is that enforced by the aggregate or a process manager?). *Why it blocks:* Aggregate boundary decisions are the most consequential CQRS/ES design choices and are extremely expensive to change after events are persisted.

4. **Acceptance criteria do not exist yet.** The feature file is listed as an implementation step. The plan must contain concrete Gherkin scenarios (or equivalent testable criteria) so that: (a) the engineer knows what to build, and (b) a reviewer can objectively validate success. *Why it blocks:* Without acceptance criteria, neither the engineer nor reviewer can determine when the iteration is complete.

5. **`huddlz-hq/cucumber` viability is unconfirmed.** The plan depends on this library for its primary validation strategy. If it doesn't exist or isn't compatible, the entire validation plan collapses. *Why it blocks:* The plan must confirm the library exists, is usable, or specify a fallback (e.g., ExUnit-based scenario tests).

## 6. Non-blocking Improvements

1. Specify folder structure conventions for feature files, step definitions, and the two-runner setup.
2. Add a brief data model sketch for projected read models (Ecto schemas for clubs, people, memberships, messages, deliveries).
3. Clarify whether the fake email provider is a behaviour + module or a Mox-style mock, and where it lives.
4. Add a note about idempotency expectations for event handlers/projectors.
5. Consider whether `Membership` needs an aggregate or is just a relationship managed by the `Club` aggregate.

## 7. Smallest Viable Iteration

The current scope is already a reasonable smallest slice (domain model with fake provider, no UI, no real email). However, it could be further narrowed if needed:

**Minimum viable first slice:** Club creation, person creation, membership, and message sending with a single "sent" status. Defer all delivery status tracking (delivered, bounced, delayed, spam, opened) to a follow-up. This would let the team validate the Commanded infrastructure, aggregate design, and Cucumber integration without the complexity of the delivery state machine.

If the team prefers to keep delivery statuses in scope (which is reasonable since that's the core value), then the current scope is fine — but the blocking gaps above must be resolved first.

## 8. Validation Plan

The iteration is successful when:

1. `devenv shell mix precommit` passes with zero errors.
2. All Gherkin scenarios defined in the shared feature file pass when executed via the Elixir-layer Cucumber runner against the domain model with fake provider.
3. The scenarios cover at minimum: creating a club, adding a member, sending a message, and observing each delivery status (sent, delivered, delayed, bounced, spam complaint, opened) reflected correctly in both the member-facing receipt view and operator deliverability view.
4. ExUnit tests pass for: event store setup, aggregate invariant enforcement, projector correctness, and fake provider interactions.
5. No Phoenix UI or real provider integration is required.

## 9. Corrected Iteration Plan Draft

Below are the specific edits required to make the plan READY. A full rewrite is not appropriate since the plan structure is sound — it needs gap-filling, not restructuring.

### Edit 1: Resolve the `opened` status decision

**Replace** the Open Technical Decisions bullet about `opened` **with** a decision in the main plan body. Suggested resolution (plan author should confirm or override):

> `opened` is modeled as a delivery status transition (not a separate event type). The `Delivery` aggregate tracks status as a state machine: `sent → delivered → opened`, with `bounced`, `delayed`, and `spam_complaint` as terminal/branch states. The member-facing projection maps `delivered` and `opened` to their simple labels; the operator-facing projection shows the full status history with timestamps.

### Edit 2: Specify Commanded infrastructure choices

**Replace** Implementation Plan step 1 and the "exact package versions" open decision **with:**

> 1. Add `commanded` (latest stable), `commanded_eventstore_adapter`, and `eventstore` to `mix.exs`. The event store will use a separate PostgreSQL database (`memba_eventstore_dev` / `memba_eventstore_test`) managed by `EventStore.Tasks.Create` / `EventStore.Tasks.Drop`. Test environment will use the `eventstore` test database with `Commanded.EventStore.Adapters.EventStore` configured for serialization with `Commanded.Serialization.JsonSerializer`.
>
> 2. Add `config/event_store.exs` (imported by `config/dev.exs` and `config/test.exs`) with connection details. Add `EventStore` and `Commanded.Application` to the supervision tree. Add Mix aliases for `event_store.setup` and `event_store.reset`.

### Edit 3: Define aggregate boundaries, commands, events, and invariants

**Replace** Implementation Plan step 3 **with:**

> 3. Define the following aggregates, commands, events, and invariants:
>
> **Club aggregate** (identity: `club_id`)
> - Command: `CreateClub{club_id, name}` → Event: `ClubCreated{club_id, name}`
> - Invariant: club_id must not already exist (enforced by aggregate lifecycle)
>
> **Person aggregate** (identity: `person_id`)
> - Command: `CreatePerson{person_id, name, email}` → Event: `PersonCreated{person_id, name, email}`
> - Invariant: person_id must not already exist
>
> **Membership aggregate** (identity: `{club_id, person_id}` composite or dedicated `membership_id`)
> - Command: `AddMember{membership_id, club_id, person_id}` → Event: `MemberAdded{membership_id, club_id, person_id}`
> - Invariant: same membership_id must not already exist
> - Note: cross-aggregate validation (club and person must exist) is handled by the application service / process manager, not the aggregate.
>
> **Message aggregate** (identity: `message_id`)
> - Command: `SendMessage{message_id, club_id, sender_person_id, subject, body}` → Event: `MessageSent{message_id, club_id, sender_person_id, subject, body, sent_at}`
> - Invariant: message_id must not already exist
> - The application service resolves club members and dispatches individual `CreateDelivery` commands.
>
> **Delivery aggregate** (identity: `delivery_id`)
> - Command: `CreateDelivery{delivery_id, message_id, recipient_person_id, recipient_email}` → Event: `DeliveryCreated{delivery_id, message_id, recipient_person_id, recipient_email, status: :sent}`
> - Command: `UpdateDeliveryStatus{delivery_id, status, timestamp}` → Event: `DeliveryStatusChanged{delivery_id, status, timestamp}`
> - Valid status transitions: `sent → delivered`, `delivered → opened`, `sent → bounced`, `sent → delayed`, `delayed → delivered`, `sent → spam_complaint`
> - Invariant: status transitions must follow the allowed state machine. Invalid transitions are rejected.

### Edit 4: Add concrete acceptance criteria (Gherkin scenarios)

**Add a new section** after "Implementation Plan" titled "Acceptance Scenarios" containing the core Gherkin:

> ## Acceptance Scenarios
>
> These scenarios will be placed in the shared feature file and executed at the domain layer.
>
> ```gherkin
> Feature: Member message deliverability
>
>   Scenario: Club operator sends a message to members
>     Given a club "Chess Club" exists
>     And a person "Alice" with email "alice@example.com" is a member of "Chess Club"
>     And a person "Bob" with email "bob@example.com" is a member of "Chess Club"
>     When "Alice" sends a message to "Chess Club" with subject "Meeting tomorrow"
>     Then the message should be sent to 2 recipients
>     And "Alice" should see a receipt showing the message was "Sent" to each member
>
>   Scenario: Message is delivered successfully
>     Given a message has been sent to "Bob" at "bob@example.com"
>     When the email provider reports the message was delivered
>     Then "Alice" should see a receipt showing "Delivered" for "Bob"
>     And the operator deliverability view should show status "delivered" with a timestamp
>
>   Scenario: Message delivery is delayed
>     Given a message has been sent to "Bob" at "bob@example.com"
>     When the email provider reports the message was delayed
>     Then "Alice" should see a receipt showing "Delayed" for "Bob"
>     And the operator deliverability view should show status "delayed" with a timestamp
>
>   Scenario: Message bounces
>     Given a message has been sent to "Bob" at "bob@example.com"
>     When the email provider reports the message bounced
>     Then "Alice" should see a receipt showing "Bounced" for "Bob"
>     And the operator deliverability view should show status "bounced" with a timestamp
>
>   Scenario: Message triggers a spam complaint
>     Given a message has been sent to "Bob" at "bob@example.com"
>     When the email provider reports a spam complaint
>     Then "Alice" should see a receipt showing "Spam Complaint" for "Bob"
>     And the operator deliverability view should show status "spam_complaint" with a timestamp
>
>   Scenario: Message is opened by recipient
>     Given a message has been delivered to "Bob" at "bob@example.com"
>     When the email provider reports the message was opened
>     Then "Alice" should see a receipt showing "Opened" for "Bob"
>     And the operator deliverability view should show status "opened" with a timestamp
>
>   Scenario: Operator views deliverability summary
>     Given a message has been sent to 3 members
>     And 2 messages were delivered and 1 bounced
>     Then the operator deliverability view should show 2 delivered and 1 bounced
> ```

### Edit 5: Confirm or replace `huddlz-hq/cucumber`

**Replace** Implementation Plan step 7 **with:**

> 7. Confirm `huddlz-hq/cucumber` is available and compatible with current Elixir/OTP versions. If it is unavailable or incompatible, implement the acceptance scenarios as structured ExUnit tests that mirror the Gherkin scenario names and steps (one test per scenario, with descriptive names matching the scenario titles). Document the decision in an ADR if the Cucumber approach is deferred.

### Edit 6: Clean up Open Technical Decisions

**Replace** the entire Open Technical Decisions section **with:**

> ## Open Technical Decisions
>
> - Exact folder structure for shared feature files should be chosen during implementation. The constraint is that scenarios must be reusable by a future cucumber-js/Playwright runner.
> - Whether `Membership` uses a composite identity (`{club_id, person_id}`) or a dedicated `membership_id` should be decided during implementation. Either approach works; the aggregate boundary and invariants are the same.

These are genuinely deferrable decisions that don't affect the architecture.

---

{"context_updates":{"plan_ready":false}}